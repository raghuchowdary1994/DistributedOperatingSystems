defmodule Worker do
  use GenServer

def start_link(x) do
    {:ok, pid} = GenServer.start_link(__MODULE__,x)
    {:ok, pid}
  end

  def init(x) do
    {:ok, { 0, 0, [], x, 1 } }
      #  nodeId, count, neighbor_list, s, w
  end

    def handle_call( {:initialState, x }, _from, { _id, count, neighbor_list, s, w } ) do
      {:reply, x, { x, count, neighbor_list, s, w }}
    end

    def handle_call( {:neighbor_list, neigh_list}, _from, { id, count, _neighbor_list, s, w } ) do
      {:reply, neigh_list, { id, count, neigh_list, s, w }}
    end


    def handle_cast({:invoke_gossip, msg, start_time }, { id, count, neigh_list, s, w} ) do
      :global.sync()
      pid=:global.whereis_name(:Boss)


      if count >= 10 do
       GenServer.cast( pid,{:convergence_gossip, self(), msg ,start_time } )

       {:noreply, { id, count, neigh_list, s, w}}
     else

       GenServer.cast(self(), {:transmit_gossip, msg, start_time})
       {:noreply,{ id, count+1, neigh_list, s, w }}
     end

    end



    def handle_cast({:transmit_gossip, msg, start_time}, { id, count, neigh_list, s, w} ) do
      :global.sync()
      pid=:global.whereis_name(:Boss)

      ranNode = Enum.random(neigh_list)

      GenServer.cast(ranNode, {:invoke_gossip, msg, start_time})
      # :timer.sleep(3000)
      GenServer.cast(self(), {:transmit_gossip, msg, start_time})
      {:noreply, { id, count, neigh_list, s, w} }

    end



    def handle_cast({:invoke_pushsum, msg, input_s, input_w, start_time }, { id, count, neigh_list, s, w} ) do
      :global.sync()
      pid=:global.whereis_name(:Boss)

          if count >= 3 do
              GenServer.cast(pid,{:convergence_pushsum,self(), msg, start_time })
              {:noreply,{ id , 3, neigh_list, s, w }}
          else

              new_s = ( s + input_s )
              new_w = ( w + input_w )
              send_s = new_s/2
              send_w = new_w/2

              ratio =  abs( (new_s/new_w) -  (s/w) )
              GenServer.cast(self(), {:transmit_pushsum, msg, send_s, send_w , start_time})
              if ratio < :math.pow(10,-10) do
                {:noreply,{ id, count+1 , neigh_list, send_s , send_w }}
              else
                {:noreply,{ id, 0, neigh_list, send_s, send_w }}
              end
            end
    end

    def handle_cast({:transmit_pushsum, msg, input_s , input_w, start_time }, { id, count, neigh_list, s, w} ) do

      :global.sync()
      pid=:global.whereis_name(:Boss)

      ranNode = Enum.random(neigh_list)

      GenServer.cast(ranNode, {:invoke_pushsum, msg, input_s , input_w, start_time})
      {:noreply, { id, count, neigh_list, input_s, input_w} }
    end
  # end
end
