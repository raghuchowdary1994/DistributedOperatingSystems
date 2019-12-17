defmodule TwitterEngine do
  use GenServer

  def start_link(numofUsers) do
    s_pid = GenServer.start_link(__MODULE__, %{numberUsers: numofUsers , registeredUsers: 0, activeUsers: [], tweet_count: 0}, name: {:global, :TwitterEngine})
    :global.sync()
    {:ok,s_pid}
  end

  def init(state) do
      users = :ets.new(:users,[:set,:public,:named_table])
      mentions = :ets.new(:mentions,[:bag,:public,:named_table])
      hashtags = :ets.new(:hashtags,[:bag,:public,:named_table])
      tweets = :ets.new(:tweets,[:bag,:public,:named_table])
      {:ok,state}
  end

    def registerUser(username) do
        s_pid = :global.whereis_name(:"TwitterEngine")
        GenServer.call(s_pid, {:registerUser, username})
    end

    def handle_call({:registerUser, username}, _from,state) do

        numofUsers = Map.get( state, :numberUsers )
        registered_Users = Map.get( state, :registeredUsers )

        activeusers = Map.get(state, :activeUsers)
        activeusers = activeusers ++ [username]

        registered_Users = if( registered_Users < numofUsers ) do
          registered_Users = registered_Users + 1
          registered_Users
        end
        new_state = Map.put( state, :registeredUsers , registered_Users)

        new_state = Map.put( state, :activeUsers, Enum.take_random(1..numofUsers, trunc(numofUsers*0.6) )           )

        :ets.insert(:users, {username, [], [], []})   # username followerstoUser following offlinetweets
        if (registered_Users == numofUsers) do
            :timer.sleep(50)
            IO.puts "All users Registration completed."
            IO.puts "Keeping 60% active users logged initially"
            :timer.sleep(50)
            {:noreply, new_state}
        end

        {:reply, username ,new_state}
    end

    def build_followers(numofUsers) do
      IO.puts "Building followers, taking 30% random followers for each User"

      user_range = 1..numofUsers
      noof_followers = trunc(numofUsers * 0.3)  #each user has 30% followers
        Enum.each(1..numofUsers, fn x ->

            num = noof_followers
            if (num > 0) do
                followers_list = generate_for_one_user(x, num, Enum.to_list(user_range), [])
                str = "user" <> Integer.to_string(x)
                [row] = :ets.lookup(:users, str)
                :ets.insert(:users, { str, followers_list, elem(row , 2), [] })
                TwitterClient.update_follower_count(num, str)
                Enum.each(followers_list, fn(follower) ->
                    update_following_list(follower, x)
                end)
            end
        end)

    end


    def generate_for_one_user(user, num, no_users, foll_list) do
        follower = Enum.random(no_users)
        if (num > 0) do
            if (!Enum.member?(foll_list, follower)) do
                if (follower != user) do
                    foll_list = Enum.concat([follower], foll_list)
                    generate_for_one_user(user, num - 1, no_users, foll_list)
                else
                    generate_for_one_user(user, num, no_users, foll_list)
                end
            else
                generate_for_one_user(user, num, no_users, foll_list)
            end
        else
            foll_list
        end
    end

    def update_following_list(follower, username) do
        [result] = :ets.lookup(:users, "user" <> Integer.to_string(follower) )

        followers_list = elem(result, 1)
        following_list = elem(result, 2)
        following_list = following_list ++ [username]
        :ets.insert(:users, { "user" <> Integer.to_string(follower), followers_list, following_list, []})
    end

   def handle_cast( {:retweet_to_server , message, this_user } ,  state) do

     tweet_count = Map.get(state, :tweet_count)
     tweet_count = tweet_count + 1
     tweetid = " #{this_user} : " <> message
     [user_data] = :ets.lookup(:users, "user"<>Integer.to_string(this_user))
     IO.puts "Retweeting : #{message}"
     followers = elem(user_data, 1)
       Enum.each(followers, fn(x) ->
           [x_user_data] = :ets.lookup(:users, "user"<>Integer.to_string(x))

           activeusers = Map.get(state, :activeUsers)
           if Enum.member?(activeusers, x) do
               receive_pid = :global.whereis_name(:"#{"user"<>Integer.to_string(x)}")
               GenServer.cast( receive_pid, {:receive_tweet, "user"<>Integer.to_string(x), tweetid, message, this_user} )
           else
               offlinemsg = elem(x_user_data, 3)
               offlinemsg = offlinemsg ++ [tweetid]
               followers = elem(x_user_data,1)
               following = elem(x_user_data,2)
               :ets.insert( :users, { "user"<>Integer.to_string(x), followers, following, offlinemsg } )
           end

       end)
       state = Map.put(state, :tweet_count, tweet_count)

     {:noreply,state}
   end

    def handle_cast( {:tweet_to_server , message, this_user } ,  state) do
      hashtags = Regex.scan(~r/#[a-zA-Z0-9_]+/, message)|> Enum.concat
      mentions = Regex.scan(~r/@[a-zA-Z0-9_]+/, message)|> Enum.concat

      tweet_count = Map.get(state, :tweet_count)
      tweet_count = tweet_count + 1
      tweetid = " #{this_user} : " <> message
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
                        :ets.insert(:hashtags, {x, [tweetid]})
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
                       :ets.insert(:mentions, {x, [tweetid]})#tweetid]})
                   end
               end)
      end
      tweetsidvalue = :ets.lookup(:tweets, this_user)
      if( tweetsidvalue != [] ) do
        [tweetsidvalue] = tweetsidvalue
        tweetsidvalue = elem(tweetsidvalue,1)
        tweetsidvalue = tweetsidvalue ++ [ " #{this_user} : "<> message]
        :ets.delete(:tweets,this_user)
        :ets.insert(:tweets, {this_user, tweetsidvalue})
      else
         :ets.insert(:tweets, {this_user, [tweetid]})
      end

      [user_data] = :ets.lookup(:users, "user"<>Integer.to_string(this_user))

      followers = elem(user_data, 1)
        Enum.each(followers, fn(x) ->
            [x_user_data] = :ets.lookup(:users, "user"<>Integer.to_string(x))

            activeusers = Map.get(state, :activeUsers)

            if Enum.member?(activeusers, x) do
                receive_pid = :global.whereis_name(:"#{"user"<>Integer.to_string(x)}")
                GenServer.cast( receive_pid, {:receive_tweet, "user"<>Integer.to_string(x), tweetid, message, this_user} )
            else
                offlinemsg = elem(x_user_data, 3)
                offlinemsg = offlinemsg ++ [tweetid]
                followers = elem(x_user_data,1)
                following = elem(x_user_data,2)
                :ets.insert( :users, { "user"<>Integer.to_string(x), followers, following, offlinemsg } )
            end

        end)

      state = Map.put(state, :tweet_count, tweet_count)
      {:noreply,state}
    end


    def handle_cast( {:query_hashtags, this_user, hashtag}, state ) do
      tweets = :ets.lookup(:hashtags, hashtag)

      tweets = if tweets == [] do
            tweets =[]
      else
            [tweets] = tweets
            tweets = elem(tweets,1)
      end

      receive_pid = :global.whereis_name(:"#{"user"<>Integer.to_string(this_user)}")
      GenServer.cast( receive_pid, {:print_queryhashtags, "user"<>Integer.to_string(this_user), tweets , hashtag} )
      {:noreply,state}
    end


    def handle_cast( {:query_mentions, this_user, mention}, state ) do
      tweets = :ets.lookup(:mentions, mention)

      tweets = if tweets == [] do
            tweets =[]
      else
            [tweets] = tweets
            tweets = elem(tweets,1)
      end
      receive_pid = :global.whereis_name(:"#{"user"<>Integer.to_string(this_user)}")
      GenServer.cast( receive_pid, {:print_queryhashtags, "user"<>Integer.to_string(this_user), tweets , mention} )

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


    def handle_cast( {:set_online, user}, state ) do
        activeusers = Map.get( state , :activeUsers )
        userid = "user"<>Integer.to_string(user)

        IO.puts "#{userid} back online"

        activeusers = if Enum.member?(activeusers, user) do
         activeusers
       else
         activeusers = activeusers ++ [user]
       end

        [user_data] = :ets.lookup(:users, userid)
        offline_msgs = elem(user_data, 3)

        followers = elem(user_data,1)
        following = elem(user_data,2)
        :ets.insert( :users, { userid, followers, following, [] } )
        user_pid = :global.whereis_name(:"#{userid}")
        GenServer.cast( user_pid, {:print_offlinemsgs, userid, offline_msgs} )

        state = Map.put( state, :activeUsers, activeusers )
      {:noreply, state}
    end

    def handle_cast( {:delete_user, user} , state ) do
        userid = "user"<>Integer.to_string(user)
        activeusers = Map.get( state , :activeUsers )
        activeusers = List.delete( activeusers , user )
        :ets.delete(:users,userid)
        state = Map.put( state, :activeUsers, activeusers )
      {:noreply, state}
    end


end
