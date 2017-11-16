defmodule HAPTest do
  use ExUnit.Case
  doctest HAP

  test "greets the world" do
    assert HAP.hello() == :world
  end
end
