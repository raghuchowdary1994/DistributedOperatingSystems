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
  def main(argv) do
    [numNodes, topology, algorithm] = argv
    Boss.start_link(String.to_integer(numNodes), topology, algorithm)
  end

end
