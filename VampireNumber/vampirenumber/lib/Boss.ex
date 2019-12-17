defmodule Boss do
  use Supervisor
  #Supervisor whose work is to Monitor its workers and for Purpose of collecting result
  #We are creating 2000 Actors to carry computation to check the Vampire numbers in given Range

  def start_link(n1 , n2) do
    {:ok, bpid} = Supervisor.start_link(__MODULE__,[n1,n2])
    get_worker_states(bpid)
    {:ok, bpid}
  end

  def init( input \\ [] ) do
    [ n1 , n2 ] = Enum.map( input , fn x -> (x) end )
    actors = 50
    len = div( (n2 - n1) , actors)
    invokecheckVampire( actors, len , n1 , n2 )
   end

   #Invoking multiple actors for performing computation
  def invokecheckVampire( actors , len , n1 , _n2 ) do
    probs = Enum.map( 1..actors , fn(x) ->
      worker(Worker, [ n1 + 1 + ((x-1) * len) , n1 + (x * len) ] ,[id: x])
    end)
    supervise(probs , strategy: :one_for_one)
  end

  def get_worker_states(bpid) do
  Enum.each(Supervisor.which_children(bpid), fn({_id, pid, _type, _modules}) ->
    Enum.each( :sys.get_state(pid)  , fn x -> IO.puts x end)
  end)
end


end
