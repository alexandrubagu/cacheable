defmodule CacheableTest do
  use ExUnit.Case
  doctest Cacheable

  test "greets the world" do
    assert Cacheable.hello() == :world
  end
end
