defmodule Twitterengine do
  @moduledoc """
  Twitterengine keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{numberUsers: 0 , registeredUsers: 0, activeUsers: [], tweet_count: 0}, name: {:global, :TwitterEngine})
  end

  def init(state) do
      users = :ets.new(:users,[:set,:public,:named_table])
      mentions = :ets.new(:mentions,[:bag,:public,:named_table])
      hashtags = :ets.new(:hashtags,[:bag,:public,:named_table])
      tweets = :ets.new(:tweets,[:bag,:public,:named_table])
      channel_ids = :ets.new(:channelid,[:set, :public, :named_table])
      {:ok,state}
  end


  def find( username ) do
      res = :ets.lookup(:users, username)
  end

    def registerUser(username ) do
        s_pid = :global.whereis_name(:"TwitterEngine")
        GenServer.call(s_pid, {:registerUser, username})
    end

    def handle_call({:registerUser, username}, _from,state) do

        :ets.insert(:users, {username, [], [], []})   # username followerstoUser following offlinetweets

        {:reply, username ,state}
    end

  
   def handle_cast( {:retweet_to_server , tweetid, this_user } ,  state) do
    IO.inspect tweetid
    [message] = :ets.lookup(:tweets, String.to_integer(tweetid))
    message = elem(message,1)
    IO.inspect message
     tweet_count = Map.get(state, :tweet_count)
     tweet_count = tweet_count + 1
     tweetid = System.unique_integer [:monotonic,:positive]
     
     [user_data] = :ets.lookup(:users, this_user)
     message = "Retweeting : "<>message
     followers = elem(user_data, 1)
       Enum.each(followers, fn(x) ->
           [x_user_data] = :ets.lookup(:users, x)

           activeusers = Map.get(state, :activeUsers)
           if Enum.member?(activeusers, x) do
               channel = :ets.lookup(:channelid, String.to_atom(x) )

                [channel|_] = channel
                channel = Tuple.to_list(channel)
                channel = Enum.at(channel,1)
                send( channel, {:feed, this_user, message<>" with tweetId:"<>Integer.to_string(tweetid)})
            else
               offlinemsg = elem(x_user_data, 3)
               offlinemsg = offlinemsg ++ [tweetid]
               followers = elem(x_user_data,1)
               following = elem(x_user_data,2)
               :ets.insert( :users, { x, followers, following, offlinemsg } )
           end

       end)
       state = Map.put(state, :tweet_count, tweet_count)

     {:noreply,state}
   end

    def handle_cast( {:tweet_to_server , message, this_user } ,  state) do
      hashtags = Regex.scan(~r/#[a-zA-Z0-9_]+/, message)|> Enum.concat
      mentions = Regex.scan(~r/@[a-zA-Z0-9_]+/, message)|> Enum.concat

      IO.inspect this_user
      IO.inspect "ffff"
      IO.inspect message
      tweet_count = Map.get(state, :tweet_count)
      tweet_count = tweet_count + 1
      if( hashtags != [] ) do
        Enum.each(hashtags, fn(x) ->
                    hashtagvalue = :ets.lookup(:hashtags, x)

                    if (hashtagvalue != []) do
                        [hashtagvalue] = hashtagvalue
                        hashtagvalue = elem(hashtagvalue, 1)
                        hashtagvalue = hashtagvalue ++ [" #{this_user} : " <> message]#[tweetid]
                        :ets.delete(:hashtags,x)
                        :ets.insert(:hashtags, {x, hashtagvalue})
                    else
                        :ets.insert(:hashtags, {x, [message]})
                    end
                  end)
      end

      if( mentions != [] ) do
        Enum.each(mentions, fn(x) ->
                   mentionsvalue = :ets.lookup(:mentions, x)
                   if (mentionsvalue != []) do
                       [mentionsvalue] = mentionsvalue
                       mentionsvalue = elem(mentionsvalue, 1)
                       mentionsvalue = mentionsvalue ++ [" #{this_user} : " <> message]#[tweetid]
                       :ets.delete(:mentions,x)
                       :ets.insert(:mentions, {x, mentionsvalue})
                   else
                       :ets.insert(:mentions, {x, [message]})#tweetid]})
                   end
               end)
      end
      tweetid = System.unique_integer [:monotonic,:positive]


     :ets.insert(:tweets, {tweetid, message})
      IO.inspect :ets.lookup(:tweets,tweetid)
      [user_data] = :ets.lookup(:users, this_user )

      followers = elem(user_data, 1)
        Enum.each(followers, fn(x) ->
            [x_user_data] = :ets.lookup(:users, this_user)

            activeusers = Map.get(state, :activeUsers)

            if Enum.member?(activeusers, x) do
                channel = :ets.lookup(:channelid, String.to_atom(x) )
       
                [channel|_] = channel
                channel = Tuple.to_list(channel)
                channel = Enum.at(channel,1)
                send( channel, {:feed, this_user, message<>" with tweetId:"<>Integer.to_string(tweetid)})
            else
                offlinemsg = elem(x_user_data, 3)
                offlinemsg = offlinemsg ++ [tweetid]
                followers = elem(x_user_data,1)
                following = elem(x_user_data,2)
                socket = elem( x_user_data, 4 )
                :ets.insert( :users, { x, followers, following, offlinemsg } )
            end

        end)

      state = Map.put(state, :tweet_count, tweet_count)
      {:noreply,state}
    end

    def handle_cast( {:set_offline, user}, state ) do
        activeusers = Map.get( state , :activeUsers )
        userid = "user"<>Integer.to_string(user)

        activeusers = List.delete( activeusers, user )
        IO.puts "#{userid} went offline"
        state = Map.put( state, :activeUsers, activeusers )
      {:noreply, state}
    end

    def set_online(user) do
            server_pid = :global.whereis_name(:"TwitterEngine")
            GenServer.call(server_pid, {:set_online, user})
        end

    def handle_call( {:set_online, user}, _from , state ) do
      :timer.sleep(30)
        activeusers = Map.get( state , :activeUsers )
        IO.puts "#{user} back online"
       
        [user_data] = :ets.lookup(:users, user)
         retval = if (user == elem(user_data, 0)) do
          true
        else
          false
        end

        activeusers = if Enum.member?(activeusers, user) do
         activeusers
       else
         activeusers = activeusers ++ [user]
       end
        state = Map.put( state, :activeUsers, activeusers )
      {:reply, retval ,state}
    end

    def handle_cast( {:delete_user, user} , state ) do
        userid = "user"<>Integer.to_string(user)
        activeusers = Map.get( state , :activeUsers )
        activeusers = List.delete( activeusers , user )
        :ets.delete(:users,userid)
        state = Map.put( state, :activeUsers, activeusers )
      {:noreply, state}
    end


    def follow(user, following_user) do
      GenServer.cast({:global, :"TwitterEngine"}, {:follow, user, following_user})
  end

  def handle_cast({:follow, user, following_user}, state) do
      IO.puts "fff"
      [user_data] = :ets.lookup(:users, user)
      #insert as following for current user
      following = elem(user_data, 3)
      if (Enum.member?(following, following_user) == false) do
          following = Enum.concat(following, [following_user])
          :ets.insert(:users, {elem(user_data, 0), elem(user_data, 1), following, elem(user_data, 3)})
          #insert for the following user as a follower
          [result] = :ets.lookup(:users, following_user)
          followers_list = elem(result, 2)
          # followers_list = followers_list ++ [user]
          followers_list = Enum.concat(followers_list, [user])
          IO.inspect followers_list
          :ets.insert(:users, {elem(result, 0), followers_list, elem(result, 2), elem(result, 3)})
      end
      IO.inspect :ets.lookup(:users, user)
      {:noreply, state}
  end

  def send_tweet( tweet , this_user ) do
      GenServer.cast({:global, :"TwitterEngine"}, {:tweet_to_server,tweet ,this_user })
 end

  def send_retweet( tweetid , this_user ) do
      GenServer.cast({:global, :"TwitterEngine"}, {:retweet_to_server,tweetid ,this_user })
 end

   def query_mentions( mention , username ) do
      GenServer.cast({:global, :"TwitterEngine"}, {:mentions, mention, username })
 end

  def query_hashtags( hashtag , username ) do
      GenServer.cast({:global, :"TwitterEngine"}, {:hashtags, hashtag, username })
 end

  def handle_cast( {:hashtags, hashtag , username}, state ) do
      [tweets] = :ets.lookup(:hashtags, hashtag)
      tweets = elem(tweets,1)
      channel = :ets.lookup(:channelid, String.to_atom(username) )
      [channel|_] = channel
      channel = Tuple.to_list(channel)
      channel = Enum.at(channel,1)
      if( tweets == []) do
            send( channel, {:outputtweets, username, "No tweets with input hashtag"})
        else
            Enum.each( tweets , fn x ->
              send( channel, {:outputtweets, username, x })
            end )
      end
    {:noreply,state}
  end


  def handle_cast( {:mentions, mention , username}, state ) do
      [tweets] = :ets.lookup(:mentions, mention)
      tweets = elem(tweets,1)
      channel = :ets.lookup(:channelid, String.to_atom(username) )
      [channel|_] = channel
      channel = Tuple.to_list(channel)
      channel = Enum.at(channel,1)
      if( tweets == []) do
            send( channel, {:outputtweets, username, "No tweets with input mention"})
        else
            Enum.each( tweets , fn x ->
              send( channel, {:outputtweets, username, x })
            end )
      end
    {:noreply,state}
  end

end
