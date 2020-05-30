defmodule Language.Interpreter.ImplTest do
  use ExUnit.Case, async: true

  alias Language.Interpreter.Impl

  test "plus/1" do
    args = [10, 89, 100, 12]
    assert Impl.plus(args) === 211
  end

  test "minus/1" do
    args = [100, 900, 45]
    assert Impl.minus(args) === -755
  end

  test "multiply/1" do
    args = [100, 453, 934, 1, 0]
    assert Impl.multiply(args) === 0
  end

  test "divide/1" do
  end

  test "mod/1" do
  end

  test "lt?/1" do
    assert Impl.lt?([4, 90, 893, 2903])
    refute Impl.lt?([4, 90, 893, 2903, 11])
  end

  test "lte?/1" do
  end

  test "gt?/1" do
  end

  test "gte?/1" do
  end

  test "eq?/1" do
  end

  test "neq?/1" do
  end

  test "and?/1" do
  end

  test "or?/1" do
  end

  test "not?/1" do
    assert Impl.not?(true) === false
  end

  test "concat/1" do
    args = ["Hello", " ", "world"]
    assert Impl.concat(args) === "Hello world"
  end

  test "choose_random/1" do
    args = [1, "hello", {1, 1}, "john", false]
    assert Impl.choose_random(args) in args
  end

  test "rand_int/2" do
    assert Impl.rand_int(34, 90) in 34..90
  end

  test "min/1" do
    args = [90, 54, 29, 21, 87, 12]
    assert Impl.min(args) === 12
  end

  test "max/1" do
    args = [90, 54, 29, 21, 87, 12]
    assert Impl.max(args) === 90
  end

  test "player_tile/2" do
  end
end
