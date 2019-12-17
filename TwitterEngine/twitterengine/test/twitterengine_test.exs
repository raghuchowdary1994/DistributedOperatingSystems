defmodule TwitterEngineTest do
  use ExUnit.Case, async: false

  setup_all do
    {:ok, server_pid} = TwitterEngine.start_link(5)
    :timer.sleep(50)
  end


  test "Test User Registration 5 Users" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    list = Enum.map(1..5, fn x-> :ets.lookup(:users ,  "user"<>Integer.to_string(x) ) end)
    :timer.sleep(10)
    assert length(list)==5
  end

  test "Test User Registration 10 Users" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(10)

    list = Enum.map(1..10, fn x-> :ets.lookup(:users ,  "user"<>Integer.to_string(x) ) end)
    :timer.sleep(10)
    assert length(list)==10
  end

  test "Test Followers Following 5 Users" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)

    list = Enum.map( 1..5 , fn x ->
      [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(x))
      followers = elem(row, 1)
      following = elem(row, 2)

      if followers != [] and following != [] do
        true
      end
    end )

    assert Enum.member?(list, false) == false
  end

  test "Test Followers Following 10 Users" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(10)
    list = Enum.map( 1..10 , fn x ->
      [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(x))
      followers = elem(row, 1)
      following = elem(row, 2)

      if followers != [] and following != [] do
        true
      end
    end )

    assert Enum.member?(list, false) == false
  end

  test "Test 1 send tweet case" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)

    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(100)
    TwitterClient.send_tweet( 2, 1, 5 )
    :timer.sleep(100)
    TwitterClient.send_tweet( 2, 1, 5 )
    :timer.sleep(100)
    TwitterClient.send_tweet( 2, 1, 5 )
    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(2) )
    followers = elem( row , 1 )
    :timer.sleep(500)
    list = Enum.map( followers , fn x ->
      TwitterClient.set_online(x)
      :timer.sleep(200)
      userid = "user"<>Integer.to_string(x)
      u_pid = :global.whereis_name(:"#{userid}")
      state = :sys.get_state(u_pid)
      tweetfeed = Map.get( state, :tweetfeed )
      tweetfeed
    end )
    list = List.flatten(list)
    assert Enum.empty?(list) == false
  end

  test "Test 2 send tweet case" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 10)

    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    TwitterClient.send_tweet( 4, 1, 5 )
    :timer.sleep(100)
    TwitterClient.send_tweet( 4, 1, 5 )
    :timer.sleep(100)
    TwitterClient.send_tweet( 4, 1, 5 )

    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(4) )
    followers = elem( row , 1 )
    :timer.sleep(500)
    list = Enum.map( followers , fn x ->
      TwitterClient.set_online(x)
      :timer.sleep(200)
      userid = "user"<>Integer.to_string(x)
      u_pid = :global.whereis_name(:"#{userid}")
      state = :sys.get_state(u_pid)
      tweetfeed = Map.get( state, :tweetfeed )
      tweetfeed
    end )
    list = List.flatten(list)
    assert Enum.empty?(list) == false
  end

  test "Test 1 hashtag query" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)

    TwitterEngine.build_followers(5)
    :timer.sleep(100)
    TwitterClient.send_tweet( 1, 1, 5 )

    userid = "user"<>Integer.to_string(1)
    u_pid = :global.whereis_name(:"#{userid}")
    state = :sys.get_state(u_pid)
    :timer.sleep(100)
    hashTagsbyUser = Map.get(state, :hashtags)
    [ row ] = :ets.lookup( :hashtags, Enum.random(hashTagsbyUser) )
    hashtag = elem( row , 0 )
    :timer.sleep(1000)
    TwitterClient.query_hashtags( 1,  Enum.random([hashtag]) )
    :timer.sleep(100)
    assert Enum.empty?([row]) == false
  end

  test "Test 2 hashtag query" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)

    TwitterEngine.build_followers(5)
    :timer.sleep(100)
    TwitterClient.send_tweet( 3, 1, 5 )
    userid = "user"<>Integer.to_string(3)
    u_pid = :global.whereis_name(:"#{userid}")
    state = :sys.get_state(u_pid)
    :timer.sleep(100)
    hashTagsbyUser = Map.get(state, :hashtags)
    [ row ] = :ets.lookup( :hashtags, Enum.random(hashTagsbyUser) )
    hashtag = elem( row , 0 )
    :timer.sleep(1000)
    TwitterClient.query_hashtags( 3,  Enum.random([hashtag]) )
    :timer.sleep(100)
    assert Enum.empty?([row]) == false
  end

  test "Test 1 mention query" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(100)
    TwitterClient.send_tweet( 1, 1, 5 )

    userid = "user"<>Integer.to_string(1)
    u_pid = :global.whereis_name(:"#{userid}")
    state = :sys.get_state(u_pid)
    :timer.sleep(100)
    mentionsbyUser = Map.get(state, :mentions)

    [ row ] = :ets.lookup( :mentions, Enum.random(mentionsbyUser) )
    mention = elem( row , 0 )
    TwitterClient.query_mentions( 1,  Enum.random([mention]) )
    :timer.sleep(100)
    assert Enum.empty?([row]) == false
  end

  test "Test 2 mention query" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(10)
    :timer.sleep(100)
    TwitterClient.send_tweet( 7, 1, 5 )

    userid = "user"<>Integer.to_string(7)
    u_pid = :global.whereis_name(:"#{userid}")
    state = :sys.get_state(u_pid)
    :timer.sleep(100)
    mentionsbyUser = Map.get(state, :mentions)

    [ row ] = :ets.lookup( :mentions, Enum.random(mentionsbyUser) )
    mention = elem( row , 0 )
    TwitterClient.query_mentions( 7,  Enum.random([mention]) )
    :timer.sleep(100)
    assert Enum.empty?([row]) == false
  end


  test "Test 1 Online" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    TwitterClient.set_online(2)
    state = :sys.get_state(server)
    activeUsers = Map.get( state , :activeUsers )
    assert Enum.member?(activeUsers, 2) == true
  end

  test "Test 2 Online" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 10)
    :timer.sleep(100)
    TwitterEngine.build_followers(10)
    TwitterClient.set_online(8)
    state = :sys.get_state(server)
    activeUsers = Map.get( state , :activeUsers )
    assert Enum.member?(activeUsers, 8) == true
  end

  test "Test 1 Offline" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    TwitterClient.set_offline(2)
    state = :sys.get_state(server)
    activeUsers = Map.get( state , :activeUsers )

    assert Enum.member?(activeUsers, 2) == false
  end

  test "Test 2 Offline" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(10)
    TwitterClient.set_offline(6)
    state = :sys.get_state(server)
    activeUsers = Map.get( state , :activeUsers )

    assert Enum.member?(activeUsers, 6) == false
  end


  test "Test 1 delete User" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterClient.delete_user(2)
    :timer.sleep(100)
    user = :ets.lookup(:users ,  "user"<>Integer.to_string(2) )
    assert user == []
  end

  test "Test 2 delete User" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 10 , 5)
    :timer.sleep(100)
    TwitterClient.delete_user(9)
    :timer.sleep(100)
    user = :ets.lookup(:users ,  "user"<>Integer.to_string(9) )
    assert user == []
  end

  test "Test 1 retweet User" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(500)

    TwitterClient.send_tweet( 1, 5, 5 )
    :timer.sleep(500)
    TwitterClient.send_tweet( 3, 5, 5 )
    :timer.sleep(500)
    TwitterClient.send_tweet( 4, 5, 5 )

    :timer.sleep(500)

    TwitterClient.set_online(2)
    :timer.sleep(1000)

    TwitterClient.retweet(2)
    :timer.sleep(5000)

    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(2) )
    followers = elem( row , 1 )
    :timer.sleep(200)

    list = Enum.map( followers , fn x ->
      TwitterClient.set_online(x)
      :timer.sleep(500)
      userid = "user"<>Integer.to_string(x)
      u_pid = :global.whereis_name(:"#{userid}")
      state = :sys.get_state(u_pid)
      tweetfeed = Map.get( state, :tweetfeed )
      tweetfeed
    end )
    :timer.sleep(500)

    list = List.flatten(list)
    assert Enum.empty?(list) == false
  end

  test "Test 2 retweet User" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(500)

    TwitterClient.send_tweet( 3, 1, 5 )
    :timer.sleep(500)
    TwitterClient.send_tweet( 2, 1, 5 )
    :timer.sleep(500)
    TwitterClient.send_tweet( 4, 1, 5 )

    :timer.sleep(500)

    TwitterClient.set_online(5)
    :timer.sleep(1000)

    TwitterClient.retweet(5)
    :timer.sleep(5000)

    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(5) )
    followers = elem( row , 1 )
    :timer.sleep(200)

    list = Enum.map( followers , fn x ->
      TwitterClient.set_online(x)
      :timer.sleep(500)
      userid = "user"<>Integer.to_string(x)
      u_pid = :global.whereis_name(:"#{userid}")
      state = :sys.get_state(u_pid)
      tweetfeed = Map.get( state, :tweetfeed )
      tweetfeed
    end )
    :timer.sleep(500)

    list = List.flatten(list)
    assert Enum.empty?(list) == false
  end


  test "Test 1 User live feed" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(500)

    TwitterClient.set_offline(2)
    :timer.sleep(1000)
    TwitterClient.send_tweet( 1, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 3, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 4, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 5, 1, 5 )

    :timer.sleep(500)
    TwitterClient.set_online(2)
    :timer.sleep(500)
    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(2) )
    offlinemsg = elem(row, 3)
    assert offlinemsg == []
  end


  test "Test 2 User live feed" do
    server = :global.whereis_name(:"TwitterEngine")
    :timer.sleep(20)
    Main.createClientProcess( 5 , 5)
    :timer.sleep(100)
    TwitterEngine.build_followers(5)
    :timer.sleep(500)

    TwitterClient.set_offline(4)
    :timer.sleep(1000)
    TwitterClient.send_tweet( 1, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 3, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 2, 1, 5 )
    :timer.sleep(100)

    TwitterClient.send_tweet( 5, 1, 5 )

    :timer.sleep(500)
    TwitterClient.set_online(4)
    :timer.sleep(500)
    [ row ] = :ets.lookup(:users ,  "user"<>Integer.to_string(4) )
    offlinemsg = elem(row, 3)
    assert offlinemsg == []
  end


end
