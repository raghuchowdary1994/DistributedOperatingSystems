defmodule TwitterClient do
  use GenServer

  def start_link(userId) do

    {:ok, pid} = GenServer.start_link(__MODULE__, %{name: userId, tweetfeed: [], tweets: [], hashtags: [], mentions: [] ,follower_count: 0, tweet_count: 0 }, name: {:global, :"#{userId}"} )
    :global.sync()
    TwitterEngine.registerUser( userId )

    {:ok, pid}
  end

  def init(state) do

    {:ok, state}
  end


  def update_follower_count(count, this_user) do
       this_pid = :global.whereis_name(:"#{this_user}")
       GenServer.cast(this_pid, {:update, count})
   end


    def simulateTweets( user, numofUsers, numofRequests ) do
      if( numofRequests > 0 ) do
      userid = "user"<>Integer.to_string(user)

      user_pid = :global.whereis_name(:"#{userid}")

      GenServer.cast(user_pid, {:simulate, user, numofUsers, numofRequests})
      end
    end

    def send_tweet( this_user , numofRequests, numofUsers) do
        userid = "user"<>Integer.to_string(this_user)
        :global.sync()
        user_pid = :global.whereis_name(:"#{userid}")

        GenServer.cast(user_pid, {:send_tweet, this_user, numofRequests, numofUsers})
   end

   def retweet( user ) do
     userid = "user"<>Integer.to_string(user)
     :global.sync()

     user_pid = :global.whereis_name(:"#{userid}")
     GenServer.cast( user_pid, { :retweet, user } )
   end


   def query_hashtags( user, query) do
            userid = "user"<>Integer.to_string(user)
            :global.sync()
            user_pid = :global.whereis_name(:"#{userid}")
            GenServer.cast(user_pid, {:queryHashTags, user, query})
   end

   def query_mentions( user, query) do
            userid = "user"<>Integer.to_string(user)
            :global.sync()
            user_pid = :global.whereis_name(:"#{userid}")
            GenServer.cast(user_pid, {:querymentions, user, query})
   end

   def handle_cast({:querymentions, this_user, mention}, state) do

     :global.sync()
     server_pid = :global.whereis_name(:"TwitterEngine")
     GenServer.cast(server_pid, {:query_mentions, this_user, mention})

        {:noreply, state}
    end


   def handle_cast({:queryHashTags, this_user, hashtag}, state) do
     :global.sync()
     server_pid = :global.whereis_name(:"TwitterEngine")
     GenServer.cast(server_pid, {:query_hashtags, this_user, hashtag})

        {:noreply, state}
    end

   def handle_cast( {:retweet, user}, state ) do
     tweets = Map.get(state, :tweetfeed)
     # IO.inspect tweets
     :timer.sleep(30)

     if( tweets != [] ) do

        userid = "user"<>Integer.to_string(user)
        :global.sync()
        server_pid = :global.whereis_name(:"TwitterEngine")

        current_count = Map.get(state, :tweet_count)
        tweetsbyUser = Map.get(state, :tweets)
        msg = Enum.random(tweets)
        tweetsbyUser = tweetsbyUser ++ [msg]
        state = Map.put( state, :tweets , tweetsbyUser )
        state = Map.put( state, :tweet_count , current_count + 1 )
        GenServer.cast( server_pid, {:retweet_to_server , msg , user } )

    end
     {:noreply, state}
   end

    def handle_cast({:update, count}, state) do
         state = Map.put(state, :follower_count, count)
         {:noreply, state}
     end

    def handle_cast( {:simulate, user, numofUsers, numofRequests} , state ) do

          send_tweet( user , numofRequests, numofUsers )

          hashTagsbyUser = Map.get(state, :hashtags)

         if( hashTagsbyUser != [] ) do
        query_hashtags( user,  Enum.random(hashTagsbyUser) )
        end
        query_mentions(user, "@user"<>to_string(Enum.random(Enum.to_list(1..numofUsers))))

        set_online(user)

          :timer.sleep(Enum.random(Enum.to_list(1000..5000)))
        set_offline(user)

        retweet( user )

        simulateTweets( user, numofUsers, numofRequests-1 )
      {:noreply, state}
    end


    def set_offline(user) do
      userid = "user"<>Integer.to_string(user)
      :global.sync()
      server_pid = :global.whereis_name(:"TwitterEngine")
        GenServer.cast(server_pid, {:set_offline, user})
    end

    def delete_user(user) do
      userid = "user"<>Integer.to_string(user)
      :global.sync()
      server_pid = :global.whereis_name(:"TwitterEngine")
      GenServer.cast(server_pid, {:delete_user, user})
    end

    def set_online(user) do

      userid = "user"<>Integer.to_string(user)
      :global.sync()
      server_pid = :global.whereis_name(:"TwitterEngine")
        GenServer.cast(server_pid, {:set_online, user})
    end

    def handle_cast( {:print_queryhashtags, user, tweets, hashtag} ,state ) do
                IO.puts " #{user} has query for #{hashtag} "

      if tweets == [] do
                IO.puts "#{hashtag} queried by #{user}: No result!"
        else
            Enum.each(tweets, fn(tweet) ->
                IO.puts "#{hashtag} queried by #{user}: " <> tweet
            end)
        end
      {:noreply, state}
    end

   def handle_cast( {:send_tweet, this_user, numofRequests, numofUsers}, state ) do

                :global.sync()
                server_pid = :global.whereis_name(:"TwitterEngine")
                current_count = Map.get(state, :tweet_count)
                tweetsbyUser = Map.get(state, :tweets)
                hashTagsbyUser = Map.get(state, :hashtags)
                mentionsbyUser = Map.get(state, :mentions)

                temp_user = Enum.random(Enum.to_list(1..numofUsers) -- [this_user])
                mention = "@#{"user"<>Integer.to_string(temp_user)}"

                temp_user = Enum.random(Enum.to_list(1..numofUsers) -- [this_user])
                hashTag = "##{"hashTag"<>Integer.to_string(temp_user)}"

                msg = "$#{"user"<>Integer.to_string(this_user)} tweeting with hashTags and mentions #{mention}  #{hashTag}"
                IO.puts "#{msg}"

                hashTagsbyUser = hashTagsbyUser ++ [hashTag]
                tweetsbyUser = tweetsbyUser ++ [msg]
                mentionsbyUser = mentionsbyUser ++ [mention]
                state = Map.put( state, :tweets , tweetsbyUser )
                state = Map.put( state, :hashtags , hashTagsbyUser )
                state = Map.put( state, :mentions , mentionsbyUser )
                state = Map.put( state, :tweet_count , current_count + 1 )

                GenServer.cast( server_pid, {:tweet_to_server , msg, this_user } )

        {:noreply, state}
   end


   def handle_cast({:receive_tweet, user, tweetid, message, sender}, state) do
        # IO.inspect tweetid
        tweetfeed = Map.get( state, :tweetfeed )
        tweetfeed = tweetfeed ++ [tweetid]
        IO.puts "$ #{user} received the tweet #{tweetid}  from #{"user"<>Integer.to_string(sender)}"
        state = Map.put(state, :tweetfeed, tweetfeed)
        {:noreply, state}
    end


    def handle_cast( {:print_offlinemsgs, userid, offline_msgs} , state ) do
      if( offline_msgs == [] ) do
        IO.puts "Tweet feed for #{userid} : No new Tweets"
      else

        IO.puts " Tweet feed for #{userid}: #{offline_msgs}"

      end
      {:noreply,state}
    end

end
