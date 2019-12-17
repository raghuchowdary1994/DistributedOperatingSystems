defmodule TAPESTRYTest do
  use ExUnit.Case
  doctest TAPESTRY

  test "greets the world" do
    assert TAPESTRY.hello() == :world
  end
end
