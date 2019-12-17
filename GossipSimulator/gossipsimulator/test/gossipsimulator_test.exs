defmodule GOSSIPSIMULATORTest do
  use ExUnit.Case
  doctest GOSSIPSIMULATOR

  test "greets the world" do
    assert GOSSIPSIMULATOR.hello() == :world
  end
end
