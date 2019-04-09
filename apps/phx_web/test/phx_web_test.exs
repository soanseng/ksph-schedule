defmodule PhxWebTest do
  use ExUnit.Case
  doctest PhxWeb

  test "greets the world" do
    assert PhxWeb.hello() == :world
  end
end
