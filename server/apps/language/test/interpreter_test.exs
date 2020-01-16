defmodule Language.InterpreterTest do
  use ExUnit.Case, async: true
  import Language.Interpreter, only: [reduce_expr: 1]

  test "+ correctly sums a list of numbers" do
    expr = {:+, [10, 20, {:+, [10, 10]}]}
    assert reduce_expr(expr) === {:ok, 50}
  end

  test "+ returns an error when values other than integers are given" do
    expr = {:+, [10, 20, 30, "hello"]}
    assert {:error, _} = reduce_expr(expr)
  end

  # test "- correctly subtracts a list of numbers" do
  #   expr = {:-, [100, 10, 10]}
  #   assert reduce_expr(expr) === {:ok, 80}
  # end

  test "- returns an error when values other than integers are given" do
    expr = {:-, [10, 20, 30, "hello"]}
    assert {:error, _} = reduce_expr(expr)
  end

  test "* correctly multiplies a list of numbers" do
    expr = {:*, [100, 2, {:*, [5, 8]}]}
    assert reduce_expr(expr) === {:ok, 8000}
  end

  test "* returns an error when values other than integers are given" do
    expr = {:*, [10, 20, 30, "hello"]}
    assert {:error, _} = reduce_expr(expr)
  end

  test "not negates a boolean expression" do
    expr = {:not, [true]}
    assert reduce_expr(expr) === {:ok, false}

    expr = {:not, [{:not, [true]}]}
    assert reduce_expr(expr) === {:ok, true}
  end

  test "= correctly checks for equality" do
    expr = {:=, [10, 10, 10, 10, 10]}
    assert reduce_expr(expr) === {:ok, true}

    expr = {:=, [10, 10, 10, 10, 10]}
    assert reduce_expr(expr) === {:ok, true}
  end
end
