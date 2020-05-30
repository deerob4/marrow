defmodule Language.Interpreter.Impl do
  @moduledoc false

  use Language.Protocol.Functions

  @impl Language.Protocol.Functions
  def plus(args) do
    reduce_maths_operator(&+/2, 0, args)
  end

  @impl Language.Protocol.Functions
  def minus(args) do
    reduce_maths_operator(&-/2, 0, args)
  end

  @impl Language.Protocol.Functions
  def multiply(args) do
    reduce_maths_operator(&*/2, 1, args)
  end

  @impl Language.Protocol.Functions
  def divide(args) do
    reduce_maths_operator(&div/2, 1, args)
  end

  @impl Language.Protocol.Functions
  def mod(args) do
    reduce_maths_operator(&rem/2, 1, args)
  end

  defp reduce_maths_operator(operator_fun, default, args) do
    args = Enum.reverse(args)
    Enum.reduce(args, default, operator_fun)
  end

  @impl Language.Protocol.Functions
  def lt?(args) do
    reduce_comp_operator(&</2, args)
  end

  @impl Language.Protocol.Functions
  def lte?(args) do
    reduce_comp_operator(&<=/2, args)
  end

  @impl Language.Protocol.Functions
  def gt?(args) do
    reduce_comp_operator(&>/2, args)
  end

  @impl Language.Protocol.Functions
  def gte?(args) do
    reduce_comp_operator(&>=/2, args)
  end

  defp reduce_comp_operator(operator_fun, args) do
    result =
      args
      |> Enum.reverse()
      |> Enum.chunk_every(2, 1)
      |> Enum.map(fn
        [a, b] -> operator_fun.(b, a)
        _a -> true
      end)
      |> Enum.all?(& &1)

    result
  end

  @impl Language.Protocol.Functions
  def eq?(args) do
    length(Enum.uniq(args)) === 1
  end

  @impl Language.Protocol.Functions
  def neq?(args) do
    not eq?(args)
  end

  @impl Language.Protocol.Functions
  def and?(args) do
    Enum.reduce(args, &and/2)
  end

  @impl Language.Protocol.Functions
  def or?(args) do
    Enum.reduce(args, &or/2)
  end

  @impl Language.Protocol.Functions
  def not?(arg) do
    not arg
  end

  @impl Language.Protocol.Functions
  def concat(args) do
    result =
      args
      |> Enum.map(&to_string/1)
      |> Enum.join()

    result
  end

  @impl Language.Protocol.Functions
  def choose_random(args) do
    Enum.random(args)
  end

  @impl Language.Protocol.Functions
  def rand_int(from, to) do
    Enum.random(from..to)
  end

  @impl Language.Protocol.Functions
  def min(args) do
    Enum.min(args)
  end

  @impl Language.Protocol.Functions
  def max(args) do
    Enum.max(args)
  end

  @impl Language.Protocol.Functions
  def player_tile(role, positions) do
    Map.fetch!(positions, role)
  end
end
