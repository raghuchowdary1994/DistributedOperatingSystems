defmodule Worker do
  use GenServer

  # Worker Module whose purpose is to get the Vampire Numbers from given range from Supervisor
  def start_link(start_range , end_range ) do
    {:ok, pid} = GenServer.start_link(__MODULE__,[start_range, end_range ])
    GenServer.cast(pid, {:push, start_range, end_range })
   {:ok,pid}
  end

  def init(state) do
    {:ok , state}
  end

  def handle_cast({:push, start_range , end_range } , _state) do
    result =  Enum.map( start_range..end_range , fn x -> checkVampireNumber(x) end ) |> Enum.filter(fn x -> x != nil end)
    {:noreply , result}
  end

  def checkVampireNumber(x) do

    if rem( length(Integer.digits(x)) , 2) == 1  do
      []
    else
      list = Integer.digits(x)
      sortedList = Enum.sort(list)
      len = length(list)
      i=2
      j = trunc(:math.sqrt(x))

      result = Enum.filter( i..j , fn(k) -> rem( x, k ) == 0 and length(Integer.digits(k)) == div(len,2)
      and length(Integer.digits( div(x,k) )) == div(len,2) and not( rem(k,10) == 0 and rem(div(x,k) ,10) == 0 )
      and (sortedList == Enum.sort( Integer.digits(k) ++ Integer.digits(div(x,k)))) end)

      if not(Enum.empty?(result)) do
        [x] ++  Enum.map( result , fn (k) ->  "#{k} #{div(x,k)}" end ) |> Enum.join(" ")
      end

    end
  end

end
