defmodule RracketTest do
  use ExUnit.Case
  doctest Rracket

  test "greets the world" do
    assert Rracket.hello() == :world
  end
end
