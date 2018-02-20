defmodule UnicliTest do
  use ExUnit.Case
  doctest Unicli

  test "greets the world" do
    assert Unicli.hello() == :world
  end
end
