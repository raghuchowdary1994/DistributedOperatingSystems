defmodule Boss do
  use GenServer

  def start_link(numNodes, topology, algorithm) do
      IO.puts("Main process pid is #{inspect self()}")
      {:ok, pid} = GenServer.start_link(__MODULE__,{numNodes,topology , algorithm},name: {:global, :Boss})
      start( numNodes, topology, algorithm , pid)
      {:ok, pid}
  end

  def init({numNodes,topology , algorithm}) do
    {:ok, {0, []}}
  end

  def start( numNodes, topology , algorithm, pid) do
    msg = "Hey wassup?"
    allNodes = createNodes(numNodes)

    createTopology( allNodes , topology )

    allNodes = Enum.filter( allNodes, fn x ->
      { x, count, neighbor_list, s, w } = :sys.get_state(x)
      neighbor_list != []
    end)


    GenServer.cast( pid, {:initial_nodes, allNodes})

    callAlgo( allNodes, algorithm, msg )
    :timer.sleep(:infinity)
  end

  def callAlgo( allNodes, algorithm, msg ) do
    start_time = System.monotonic_time(:millisecond)
    randomNode = Enum.random(allNodes)
    if algorithm == "gossip" do
      GenServer.cast(randomNode, {:invoke_gossip, msg, start_time })
    else
      GenServer.cast(randomNode, {:invoke_pushsum, msg, 0, 0, start_time })
    end
  end

  def createNodes(numNodes) do
    Enum.map( 1..numNodes , fn x ->
    {:ok, pid} = Worker.start_link( x )
     GenServer.call( pid, {:initialState , pid})
     pid
     end)
  end

    def buildFullNW(allNodes) do
      Enum.each( allNodes, fn x ->
        neigh_list = List.delete( allNodes, x )
        GenServer.call( x, {:neighbor_list , neigh_list} , :infinity)
      end)
    end

    def buildLine(allNodes) do
      n = length(allNodes) - 1
      Enum.each( 0..n , fn x ->
        cond  do

          x == 0 ->
          neigh_list = [Enum.at(allNodes, 1)]
          GenServer.call( Enum.at(allNodes , x) , {:neighbor_list , neigh_list} )

          x == length(allNodes) - 1 ->
          neigh_list = [Enum.at(allNodes, n-1)]
          GenServer.call( Enum.at(allNodes , x) , {:neighbor_list , neigh_list} )

          x > 0 and x < length(allNodes) - 1 ->
          neigh_list = [Enum.at(allNodes, x-1), Enum.at(allNodes, x+1)]
          GenServer.call( Enum.at(allNodes , x) , {:neighbor_list , neigh_list} )

        end
        end)
    end

    def buildRandom2DGrid( allNodes ) do
      n = Enum.count(allNodes)
      x = Enum.map( 1..n , fn x -> :rand.uniform() |> Float.round(2) end)
      y = Enum.map( 1..n , fn x -> :rand.uniform() |> Float.round(2) end)
      ordered_pairs = Enum.zip(x , y)
      Enum.each( allNodes, fn x ->
        i = Enum.find_index(allNodes, fn b -> b == x end)
        center = Enum.fetch!(ordered_pairs , i)
        count =  Enum.count(allNodes)
        a = Enum.filter( (0..count-1), fn y ->

          insideCircle(center , Enum.at(ordered_pairs, y)) end )
        b = Enum.map_every(a, 1, fn x -> Enum.at(allNodes, x) end)
        GenServer.call(x, {:neighbor_list, b})
      end)
    end

  def insideCircle(point, center) do
    {x, y} = point
    {p, q} = center
    distance = :math.pow(:math.pow((x-p), 2) + :math.pow((y-q), 2), 1/2)
    if distance <= 0.1 and distance > 0 do
      true
    else
      false
    end
  end

    def build3DTorus(allNodes) do
      ncount = length(allNodes)
      rowNodeCount = round(Float.ceil(:math.pow(ncount,(1/3))))
      planeNodeCount = round(:math.pow(rowNodeCount,2))

      numofNodes = rowNodeCount * rowNodeCount * rowNodeCount

       list = Enum.map(1..numofNodes, fn x->

       positiveX = if(x+1 <= numofNodes && rem(x,rowNodeCount) != 0 ) do x+1 else x-rowNodeCount+1 end
       negativeX = if(x-1 >= 1 && rem(x-1,rowNodeCount) != 0) do x-1 else x+rowNodeCount-1 end
       positiveY = if(rem(x,planeNodeCount) != 0 && planeNodeCount - rowNodeCount >= rem(x,(planeNodeCount))) do x+ rowNodeCount else x-planeNodeCount+rowNodeCount end
       negativeY = if((planeNodeCount - rowNodeCount*(rowNodeCount-1)) < rem(x-1,(planeNodeCount)) + 1) do x- rowNodeCount else x+planeNodeCount-rowNodeCount end
       positiveZ = if(x+ planeNodeCount <= numofNodes) do x+ planeNodeCount else x - planeNodeCount*(rowNodeCount-1) end
       negativeZ = if(x- planeNodeCount >= 1) do x- planeNodeCount else x + planeNodeCount*(rowNodeCount-1) end

       neighbour = [
         Enum.at(allNodes, positiveX-1) ,
         Enum.at(allNodes, negativeX-1) ,
         Enum.at(allNodes, positiveY-1) ,
         Enum.at(allNodes, negativeY-1) ,
         Enum.at(allNodes, positiveZ-1) ,
         Enum.at(allNodes, negativeZ-1) ]

       neighbour = Enum.filter( neighbour, fn x -> x != nil end )
       end)

      Enum.each( 1..ncount, fn x ->
        GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, Enum.at(list, x-1) })
      end)

    end

    def buildHoneyComb(allNodes) do
      ncount = Enum.count(allNodes)
      w = Kernel.trunc(:math.floor( :math.pow( ncount, 1/2) ) )
       Enum.each( 1..ncount, fn x ->

            row_num = Kernel.trunc(:math.floor((x-0.1)/w))
            cond do
              rem(row_num,2) == 0 ->
                cond do
                  rem(x,2) == 0 ->
                    n1 = x-1
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)

                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })
                   rem(x,2) == 1 ->
                     n1 = x+1
                     n2 = x+w
                     n3 = x-w
                     neigh_list = [ n1, n2, n3 ]

                     neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                     neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)

                     GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                end
              rem(row_num,2) == 1 ->
                cond do
                  rem(x,2) == 0 ->
                    n1 = if ( rem( x , w) != 0 ) do x+1 end
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)

                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                  rem(x,2) == 1 ->
                    n1 = if ( rem( (x-1), w) != 0 ) do x-1 end
                    # n1 = x-1
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)
                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                end
            end
       end )
    end

    def buildHoneyCombRN(allNodes) do

      ncount = Enum.count(allNodes)
      w = Kernel.trunc(:math.floor( :math.pow( ncount, 1/2) ) )

       Enum.each( 1..ncount, fn x ->

            row_num = Kernel.trunc(:math.floor((x-0.1)/w))

            cond do
              rem(row_num,2) == 0 ->
                cond do
                  rem(x,2) == 0 ->
                    n1 = x-1
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)
                    rand_list = List.delete(allNodes, Enum.at(allNodes, x-1))
                    neigh_list = [Enum.random(rand_list)] ++ neigh_list
                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                   rem(x,2) == 1 ->
                     n1 = x+1
                     n2 = x+w
                     n3 = x-w
                     neigh_list = [ n1, n2, n3 ]

                     neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                     neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)
                     rand_list = List.delete(allNodes, Enum.at(allNodes, x-1))
                     neigh_list = [Enum.random(rand_list)] ++ neigh_list
                     GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                end
              rem(row_num,2) == 1 ->
                cond do
                  rem(x,2) == 0 ->
                    n1 = if ( rem( x , w) != 0 ) do x+1 end
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)
                    rand_list = List.delete(allNodes, Enum.at(allNodes, x-1))
                    neigh_list = [Enum.random(rand_list)] ++ neigh_list
                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                  rem(x,2) == 1 ->
                    n1 = if ( rem( (x-1), w) != 0 ) do x-1 end
                    n2 = x+w
                    n3 = x-w
                    neigh_list = [ n1, n2, n3 ]

                    neigh_list = Enum.filter( neigh_list, fn x -> x > 0 && x <= ncount end )
                    neigh_list = Enum.map( neigh_list, fn x -> Enum.at(allNodes, x-1) end)
                    rand_list = List.delete(allNodes, Enum.at(allNodes, x-1))
                    neigh_list = [Enum.random(rand_list)] ++ neigh_list
                    GenServer.call( Enum.at(allNodes, x-1) , {:neighbor_list, neigh_list })

                end
            end
       end )

    end

    def createTopology( allNodes, topology ) do
      case topology do
        "fullnw" ->  buildFullNW(allNodes)
        "line"         ->  buildLine(allNodes)
        "random2d" -> buildRandom2DGrid(allNodes)
        "3dtorus" -> build3DTorus(allNodes)
        "honeycomb" -> buildHoneyComb(allNodes)
        "honeycombrn" -> buildHoneyCombRN(allNodes)
      end
    end

    def handle_cast( {:initial_nodes, allNodes} , {count ,node_list}) do

      {:noreply,{0, allNodes}}
  end

    def handle_cast({:convergence_gossip, remove_pid, msg, start_time}, {count , node_list}) do

      IO.puts("Convergence Reached for #{inspect remove_pid} ")
      if length(node_list) <= 2 do
         IO.puts("Remaining 2 Actors Converged")

         IO.puts("Time to Converge: #{System.monotonic_time(:millisecond)-start_time} milli seconds")
         Process.exit(self(), :kill)

      end
      {:noreply,{ count, List.delete(node_list,remove_pid)}}
    end

    def handle_cast({:convergence_pushsum, remove_pid, msg, start_time}, {count ,node_list}) do

         IO.puts("Convergence has reached")

         IO.puts("Time to Converge: #{System.monotonic_time(:millisecond)-start_time} milli seconds")
         Process.exit(self(), :kill)

      {:noreply,{List.delete(node_list,remove_pid)}}
    end

end
