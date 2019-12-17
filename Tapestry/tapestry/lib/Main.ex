defmodule Main do
  use GenServer

  def start_link( numNodes, numReq ) do
    IO.puts("Main process started")
    {:ok,pid} = GenServer.start_link( __MODULE__, [numNodes, numReq] , name: {:global, :Main} )
    {:ok,pid}
  end

  def init(input \\ []) do
    [ numNodes , numReq ] = Enum.map( input , fn x -> (x) end )
    invokeTapestry( numNodes, numReq )
    {:ok, 0}
  end

  def invokeTapestry(numNodes, numReq) do
    IO.puts("Number Of Nodes: #{numNodes}")
    IO.puts("Number Of Request Per Node: #{numReq}")
    IO.puts("Nodes Creation Started")
    allNodes = createNodes(numNodes, numReq)
  end

  def createNodes( numNodes, numReq ) do

    allNodes = Enum.map( 1..numNodes, fn x ->
      node_id = :crypto.hash(:sha, "#{x}") |> Base.encode16()
      node_id = String.slice(node_id, 0..7)
      {:ok,pid} = TapestryNode.start_link(node_id,numReq)
      pid
       end )

    IO.puts("Nodes creation completed")
    allNodes = Enum.shuffle(allNodes)

    blen = trunc(numNodes * 0.8)  # break nodes into 80:20 ratio for 20% nodes to perform join operation
    splitL = Enum.split(allNodes, blen)
    splitL = Tuple.to_list(splitL)
    IO.puts("Routing table building for 80% Nodes")

    buildRoutingtable( Enum.at(splitL,0) ) #building routing table

    hash_list = Enum.map( allNodes , fn x ->
      hash_n = GenServer.call( x , {:gethash} )
    end)


    IO.puts("Routing table completed for 80% Nodes")


    IO.puts("Dynamic Join started for 20% Nodes")

    filllevels( Enum.at(splitL,1), Enum.at(splitL,0) )


    joinRemainingNodes( Enum.at(splitL,0), Enum.at(splitL,1) ) #join operation on 20% nodes

    IO.puts("Dynamic Join Completed for 20% Nodes")

    IO.puts("Invoke Routing for Nodes")

    routingNodes(allNodes, numReq, hash_list)

  end

  def routingNodes( allNodes, numReq, hash_list) do

    Enum.each( allNodes, fn x ->
      Process.sleep(10)
      GenServer.cast( x , {:routing , allNodes, numReq, hash_list} )
    end )
    IO.puts "Initial Maxhops: 0"

  end

  def filllevels( remainlist, allNodes ) do
    Enum.each( remainlist, fn x ->
      GenServer.call( x , { :fillLevel0,  allNodes } )
    end )
  end



  def joinRemainingNodes( nwlist, remainlist ) do

    Enum.each( remainlist , fn x ->
      x_hash = GenServer.call( x , {:gethash})
      [max_prefix_id,max_prefix] = GenServer.call( x , {:joinNode, nwlist, x_hash})

      if max_prefix_id != 0 do
        GenServer.cast( x , {:updatelevels, max_prefix_id, max_prefix } )
      end
    end)

  end

  def buildRoutingtable( nodes ) do

    Enum.each( nodes, fn x ->
      GenServer.call( x , { :buildtable,  nodes } )
    end )

  end

  def handle_info({:catchhops , hops}, state) do

    maxhop = if hops > state do
        IO.puts "Maxhops updated to : #{hops}"
      hops
    else
      state
    end

    {:noreply, maxhop}
  end


end
