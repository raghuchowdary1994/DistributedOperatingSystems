defmodule TwitterengineWeb.TwitterengineChannel do
  use TwitterengineWeb, :channel

  def join("twitterengine:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (twitterengine:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  def handle_in("login", payload , socket) do

      name = Map.get(payload,"name")
      # IO.inspect name
      if length( Twitterengine.find(name)) == 0  do
          payload = %{"response"=>0}
          push socket,"login",payload
      else

        :ets.insert(:channelid, { String.to_atom(name) , self() })
        Twitterengine.set_online(name)
        temp = :ets.lookup( :channelid, String.to_atom(name) )
        IO.inspect temp
        
        IO.inspect temp
        payload = %{"response"=>1}
        push socket,"login",payload
      end
      {:noreply, socket}
  end

  def handle_in( "register", payload, socket ) do

    name = Map.get(payload, "name")
    if length( Twitterengine.find(name) ) == 0  do
        Twitterengine.registerUser(name)
        payload = %{"response"=>1}
        push socket,"register",payload
    else
        payload = %{"response" => 0}
        push socket,"register",payload
    end
    {:noreply,socket}
  end

  def handle_in("follow", payload, socket) do
      follower_name = Map.get(payload, "f_name")
      logged_name = Map.get(payload, "l_name")
      IO.inspect follower_name
      IO.inspect logged_name
      if length(Twitterengine.find(logged_name))==0 do
          payload = %{"response"=>0}
          push socket,"follow",payload
      else
          Twitterengine.follow(logged_name, follower_name)
          payload = %{"response" => 1}
          push socket,"follow",payload

      end
      {:noreply, socket}
  end



  def handle_in("send_tweet", payload, socket) do
      username = Map.get(payload, "u_name")
      msg = Map.get(payload, "tweet")

      Twitterengine.send_tweet(msg, username)
      {:noreply, socket}
  end


   def handle_info({:feed, userId, tweet}, socket) do
        IO.inspect "hello"
        res = userId <> " tweeted: '#{tweet}' " 
        push socket, "onlineFeed", %{body: res}
        {:noreply, socket}
    end

    def handle_info({:outputtweets, userId, tweet}, socket) do
        IO.inspect "hello"
        IO.inspect tweet
        push socket, "onlineFeed", %{body: tweet}
        {:noreply, socket}
    end

  def handle_in( "query_mention" , payload , socket ) do
        mention_user = Map.get(payload , "m_user")
        username = Map.get(payload, "u_name")
        Twitterengine.query_mentions(mention_user, username)
    {:noreply,socket}
  end

  def handle_in( "query_hashtag" , payload , socket ) do
        hashtag = Map.get(payload , "h_user")
        username = Map.get(payload, "u_name")
        Twitterengine.query_hashtags(hashtag, username)
    {:noreply,socket}
  end

  def handle_in("retweet", payload, socket) do
      username = Map.get( payload, "u_name" )
      tweetid = Map.get( payload, "tweet" )
      Twitterengine.send_retweet(tweetid, username)
      {:noreply, socket}
  end

  def handle_in("mentions", %{"username" => user, "queried" => queried}, socket) do
      IO.puts "inmentions"
      tweets = Project4Web.Server.query_mentions(queried, user)
      IO.inspect tweets
      push socket, "mentions", %{tweets: tweets}
      {:noreply, socket}
  end

  def handle_in("hashtag", %{"username" => user, "hashtag" => hashtag}, socket) do
      tweets = Project4Web.Server.query_hashtag(hashtag, user)
      push socket, "hashtag", %{tweets: tweets}
      {:noreply, socket}
  end



  def handle_in("get_tweets", %{"username" => user}, socket) do
      tweets = Project4Web.Server.get_tweets(user)
      # IO.inspect tweets
      # IO.puts "gettweets"
      push socket, "return_tweets", %{tweets: tweets}
      {:noreply, socket}
  end

  




end
