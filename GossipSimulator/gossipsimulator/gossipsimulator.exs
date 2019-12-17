defmodule GOSSIPSIMULATOR do
  @moduledoc """
  Documentation for GOSSIPSIMULATOR.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GOSSIPSIMULATOR.hello()
      :world

  """


  [numNodes, topology, algorithm]= Enum.map( System.argv() , fn x -> x end )
    GenServer.start_link(Boss, {String.to_integer(numNodes) , topology , algorithm} , name: {:global, :Boss})



end
