defmodule TapestryNode do
  use GenServer

  def start_link(node_id, numReq) do
    GenServer.start_link(__MODULE__, [node_id, numReq], name: String.to_atom(node_id) )
  end

  def init([node_id, numReq]) do
    routingtable = Enum.map( 1..8 , fn x -> Enum.map(1..16, fn y -> y =0 end) end)
    {:ok,%{ pid: self(), nodeid: node_id, numReq: numReq, routing_table: routingtable}}
  end


  def handle_call({:joinNode, nwlist, new_node}, _from , state) do

      len = 0
      prefix_match_list = []
      match_list = Enum.filter( nwlist , fn x ->

      nodeA = GenServer.call( x , {:gethash} )
      nodeB = new_node

      prefix_match_len = get_prefixlen(nodeA,nodeB,0)

      if prefix_match_len == len do
        x
      end
      if prefix_match_len > len do
        len = prefix_match_len
        x
      end

    end)

    dist = Enum.map( match_list, fn x ->
      x_hash = GenServer.call( x , {:gethash} )
      GenServer.cast( x , {:updatetable, x_hash , new_node } )
      dist = get_prefixlen(x_hash,new_node,0)
    end)

    if Enum.empty?(dist)==false do
    max_prefix = Enum.max(dist)
    idx = Enum.find_index( dist , fn x -> x == max_prefix end)
    max_prefix_pid = Enum.at(match_list, idx)
    {:reply,[max_prefix_pid,max_prefix], state}
    else
      {:reply,[0,0], state}
    end
  end


  def handle_cast( {:routing , allNodes, numReq, hash_list} , state ) do
    tempNodes = List.delete( allNodes, self)

    node_A = Map.get( state, :nodeid)

    tempHash = List.delete( hash_list, node_A)

    Enum.each( 1..numReq , fn x ->
      randdest = Enum.random(tempNodes)

      idx = Enum.find_index(tempNodes, fn y -> randdest == y end )
      dest_hash = Enum.at(tempHash, idx)

      GenServer.cast( self() , {:invokeReq, dest_hash , 0} )
    end )

    {:noreply,state}
  end


  def handle_cast( {:invokeReq, randdest , hops} , state ) do

    routingtable = Map.get(state , :routing_table)
    nodeid = Map.get(state, :nodeid)

    dist = get_prefixlen( nodeid, randdest , 0 )

    val = String.at(randdest, dist)

    j = cond do
        val == "A" -> 10
        val == "B" -> 11
        val == "C" -> 12
        val == "D" -> 13
        val == "E" -> 14
        val == "F" -> 15
        true -> String.to_integer(val)
    end

    list = Enum.at(routingtable, dist)
    r_node = Enum.at(list , j)

    if r_node != 0 do
      r_pid = Process.whereis( String.to_atom(r_node) )
      :timer.sleep(10)
      GenServer.cast( r_pid , {:nexthop , randdest, hops+1} )
    else
      pid=:global.whereis_name(:Main)
      Process.send_after( pid ,{:catchhops , hops} ,0)
    end

    {:noreply,state}
  end


  def handle_cast( {:nexthop , randdest, hops} ,state) do

    routingtable = Map.get(state , :routing_table)
    nodeid = Map.get(state, :nodeid)
    dist = get_prefixlen( nodeid, randdest , 0 )

      if dist == 8 do
        pid=:global.whereis_name(:Main)
        Process.send_after( pid ,{:catchhops , hops} ,0)
        {:noreply,state}
      else
        val = String.at(randdest, dist)

        j = cond do
            val == "A" -> 10
            val == "B" -> 11
            val == "C" -> 12
            val == "D" -> 13
            val == "E" -> 14
            val == "F" -> 15
            true -> String.to_integer(val)
      end

      list = Enum.at(routingtable, dist)
      r_node = Enum.at(list , j)

      if r_node != 0 do
        r_pid = Process.whereis( String.to_atom(r_node) )
        GenServer.cast( r_pid , {:nexthop , randdest, hops+1} )
      else
        pid=:global.whereis_name(:Main)
        Process.send_after( pid ,{:catchhops , hops} ,0)
      end
    end
    {:noreply,state}
  end


  def handle_call( {:fillLevel0 , allNodes}, _from , state ) do

    node_a = Map.get(state, :nodeid)

    Enum.each( allNodes, fn x ->
      x_hash = GenServer.call( x , {:gethash} )
      dist = get_prefixlen( node_a, x_hash , 0 )
      if dist == 0 do
        GenServer.cast( self() , {:updatefill0 , node_a , x_hash} )
      end
    end )

    {:reply, node_a ,state}
  end



  def handle_cast( {:updatefill0 , nodeA , nodeB }, state ) do
    i = get_prefixlen( nodeA, nodeB , 0 )
    val = String.at(nodeB,i)

      j = cond do
          val == "A" -> 10
          val == "B" -> 11
          val == "C" -> 12
          val == "D" -> 13
          val == "E" -> 14
          val == "F" -> 15
          true -> String.to_integer(val)
      end

    routingtable = Map.get(state, :routing_table)

    list = Enum.at(routingtable, i)
    list = List.replace_at( list , j , nodeB )
    routingtable = List.replace_at(routingtable, i, list)
    state = Map.put(state, :routing_table, routingtable)

    {:noreply,state}
  end

  def handle_cast( {:updatelevels , nodeB, max_prefix } , state ) do

    routingtable = Map.get(state, :routing_table)
    node_a = Map.get(state, :nodeid)

    c_state = :sys.get_state(nodeB)
    c_routingtable = Map.get(c_state, :routing_table)
    nodeBs = Map.get(c_state, :nodeid)

    Enum.each( 1..max_prefix, fn x ->
      c_routingtable = Map.get(c_state, :routing_table)
      GenServer.cast( self() , {:updatel , c_routingtable , x} )
    end)
    {:noreply,state}
  end

  def handle_cast({:updatel, c_routingtable, x} , state) do
    routingtable = Map.get(state, :routing_table)
    list = Enum.at(c_routingtable, x)
    routingtable = List.replace_at( routingtable , x , list)
    state = Map.put(state, :routing_table, routingtable)
    {:noreply,state}
  end


  def handle_call({:buildtable, nodes }, _from,  state ) do
    node_id = Map.get(state, :nodeid )
    nlist = List.delete( nodes, self )
    Enum.each( nlist, fn x ->
      x_hash = GenServer.call( x , {:gethash} )
      GenServer.cast( self() , {:updatetable , node_id, x_hash })
      end)

    {:reply, node_id , state}
  end

  def handle_call({:gethash} , _from, state ) do

    node_id = Map.get(state, :nodeid )
    {:reply, node_id, state}
  end

  def handle_cast({:updatetable, nodeA , nodeB},  state) do

    i = get_prefixlen(nodeA,nodeB,0)
    val = String.at(nodeB, i)
    j = cond do
        val == "A" -> 10
        val == "B" -> 11
        val == "C" -> 12
        val == "D" -> 13
        val == "E" -> 14
        val == "F" -> 15
        true -> String.to_integer(val)
    end

    routingtable = Map.get(state, :routing_table)
    list = Enum.at(routingtable, i)
    list = List.replace_at( list , j , nodeB )
    routingtable = List.replace_at(routingtable, i, list)
    state = Map.put(state, :routing_table, routingtable)
    {:noreply, state}
  end

  def get_prefixlen(nodeA,nodeB,len) do
    if ( nodeA != "" && (String.slice(nodeA, 0, 1) == String.slice(nodeB, 0, 1)) ) do
        nodeA = String.slice(nodeA, 1..String.length(nodeA))
        nodeB = String.slice(nodeB, 1..String.length(nodeB))
        get_prefixlen(nodeA, nodeB, len + 1)
    else
        len
    end
  end




end
