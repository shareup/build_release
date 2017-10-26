defmodule BuildReleaseTest do
  use ExUnit.Case
  doctest BuildRelease

  test "greets the world" do
    assert BuildRelease.hello() == :world
  end
end
