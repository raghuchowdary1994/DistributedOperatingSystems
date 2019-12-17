defmodule Main do
  use GenServer

  def startProgram( numofUsers , numofRequests ) do

    GenServer.start_link(__MODULE__,[] ,[name: :Main])

    TwitterEngine.start_link(numofUsers)

    createClientProcess( numofUsers , numofUsers)
    invokeandSimulate( numofUsers, numofUsers, numofRequests )

    IO.inspect "All Set Simulator Starting"
    :timer.sleep(100000)
  end

  def init(state ) do
    {:ok,state}
  end

  def createClientProcess( numofUsers , totalUsers ) do

    if numofUsers > 0 do
          str = "user" <> Integer.to_string(numofUsers)
          TwitterClient.start_link(str)
          createClientProcess(numofUsers - 1, totalUsers)
    end
  end

  def invokeandSimulate( numofUsers, numofUsers, numofRequests ) do
    TwitterEngine.build_followers(numofUsers)
    invokeSimulator(numofUsers, numofUsers, numofRequests)
  end

  def invokeSimulator( totalusers, numofUsers, numofRequests ) do
      if totalusers > 0 do
      TwitterClient.simulateTweets( totalusers, numofUsers ,numofRequests )
      invokeSimulator( totalusers-1, numofUsers, numofRequests )
    end

  end

end
