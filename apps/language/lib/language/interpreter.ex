defmodule Language.Interpreter do
  @moduledoc """
  Interprets AST fragments and returns the correct results.

  This module contains the main "runtime" features of the
  language, with all the functions for turning the fragments into
  real values found here.
  """

  require Language.Model

  import Language.Formatter, only: [format_identifier: 1]
  import Language.Model, only: [is_tile: 1]

  alias Language.Interpreter.Impl
  alias Language.Model, as: Game
  alias Language.Model.{Board, GlobalVariable, PlayerVariable}
  alias Server.GameState

  import Language.Interpreter.Macros

  # import Server.GameState, only: [is_event: 2, is_variable: 2]

  @type expr :: {atom, [any]}

  @type reduced_expr :: {:ok, any} | {:error, String.t()}

  @doc [
    marrow: %{
      name: "choose-random",
      body: "Returns a random item from the given list.",
      category: :logic,
      kind: :function,
      examples: [
        %{
          input: ~S{(choose-random (john "smith" "argentina" 10))},
          output: "john"
        }
      ]
    }
  ]
  def woo() do
    10
  end

  defguard is_event(game_state, value)
           when :erlang.is_map_key(value, :erlang.map_get(:events, game_state))

  defguard is_variable(game_state, value)
           when :erlang.is_map_key(value, :erlang.map_get(:variables, game_state)) and
                  :erlang.map_get(
                    :__struct__,
                    :erlang.map_get(value, :erlang.map_get(:variables, game_state))
                  ) === Language.Model.PlayerVariable

  @doc """
  Reduces a compound expression down to a single value.

  `MarrowLang` is an expression language, and so expressions are
  at the core.

  ## Examples

      iex> Language.Interpreter.reduce_expr({:+, [10, 20]})
      {:ok, 30}

      iex> Language.Interpreter.reduce_expr({:+, [10, {:*, [10, 20, "hello"]}]})
      {:error, "the arithemetic function `*` only accepts integers"}

  """
  @spec reduce_expr(expr) :: reduced_expr
  def reduce_expr(expr, state \\ %{})

  # Arithmetic operators.

  expr :+, [allowed: :role, min_length: 2], fn args, _ ->
    Impl.plus(args)
  end

  expr :-, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.minus(args)
  end

  expr :*, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.multiply(args)
  end

  expr :/, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.divide(args)
  end

  expr :%, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.mod(args)
  end

  # Comparison operators.

  expr :<, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.lt?(args)
  end

  expr :<=, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.lte?(args)
  end

  expr :>, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.gt?(args)
  end

  expr :>=, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.gte?(args)
  end

  # Boolean functions.

  expr :=, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.eq?(args)
  end

  expr :!=, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.neq?(args)
  end

  expr :and, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.and?(args)
  end

  expr :or, [allowed: :boolean, min_length: 2], fn args, _ ->
    Impl.or?(args)
  end

  expr :not, [allowed: :boolean, min_length: 1, max_length: 1], fn [arg], _ ->
    Impl.not?(arg)
  end

  # Generic functions.

  expr :concat, [allowed: [:string, :boolean, :integer], min_length: 2], fn args, _ ->
    Impl.concat(args)
  end

  expr :choose_random, [min_length: 2], fn args, _ ->
    Impl.choose_random(args)
  end

  expr :rand_int, [allowed: :integer, min_length: 2, max_length: 2], fn args, _ ->
    case args do
      [from, to] when from < to ->
        Impl.rand_int(from, to)

      [from, to] when from > to ->
        {:error, "the first argument to `rand-int` must be smaller than the second"}
    end
  end

  expr :min, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.min(args)
  end

  expr :max, [allowed: :integer, min_length: 2], fn args, _ ->
    Impl.max(args)
  end

  expr :player_tile, [allowed: :role, min_length: 1, max_length: 1], fn [role], state ->
    Impl.player_tile(role, state.role_positions)
  end

  def reduce_expr({:if, {condition, when_true, when_false}}, state) do
    case reduce_expr(condition, state) do
      {:ok, true} ->
        reduce_expr(when_true, state)

      {:ok, false} ->
        reduce_expr(when_false, state)

      {:ok, _} ->
        {:error, "conditional expressions given to `if` must evaluate to a Boolean value"}

      error ->
        error
    end
  end

  def reduce_expr({:var, _} = variable, state) do
    resolve_var(variable, state)
  end

  # Convert any tile tuples into %Board.Tile{} structs into tuples so
  # they can be compared properly.
  def reduce_expr({x, y} = tile, _state) when is_tile(tile),
    do: {:ok, %Board.Tile{x: x, y: y}}

  # Finally, once the final value has been created, check it's a
  # valid term and hopefully return it.
  def reduce_expr(x, _state) when Game.is_valid_term(x), do: {:ok, x}

  def reduce_expr({builtin, _args}, _state) when is_atom(builtin) do
    {:error,
     "the `#{format_identifier(builtin)}` function has been given an incorrect number of arguments"}
  end

  # This could match either an actual event or a player variable.
  def reduce_expr({:event, event, args}, state) do
    case GameState.valid_event_or_variable(state, event) do
      :none ->
        {:error, "invalid event or player variable `#{format_identifier(event)}` called"}

      :event ->
        {:error, "custom events like `#{event}` have not yet been implemented"}

      :player_variable ->
        case args do
          [var: [player_name]] ->
            resolve_var([var: [player_name, event]], state)

          _ ->
            {:error, "unknown error in event. interpreter.ex line 263"}
        end
    end
  end

  def reduce_expr(command, _) do
    {:error, "unknown command `#{format_identifier(command)}`"}
  end

  # Implementations

  def reduce_args(args, state \\ %{}) do
    with {:ok, args} <- resolve_variables(args, state),
         values = args |> Enum.map(&reduce_expr(&1, state)) |> List.flatten(),
         :none <- find_expr_errors(values),
         IO.inspect(values),
         values = Enum.map(values, &lift/1) do
      {:ok, values}
    end
  end

  def resolve_variables(args, vars) do
    result =
      Enum.reduce_while(args, [], fn var, acc ->
        case resolve_var(var, vars) do
          {:ok, var} -> {:cont, [var | acc]}
          error -> {:halt, error}
        end
      end)

    case result do
      args when is_list(args) -> {:ok, Enum.reverse(args)}
      error -> error
    end
  end

  # defp resolve_var({:var, _} = t, _), do: IO.inspect t

  # Matching current player.
  defp resolve_var({:var, [:"?current_player"]}, %{active_role: player}) do
    {:ok, player}
  end

  defp resolve_var({:var, [:"?current_tile"]}, %{active_role: player, role_positions: positions}) do
    {:ok, extract_tile(positions[player])}
  end

  defp resolve_var({:var, [:"?current_turn"]}, %{current_turn: current_turn}) do
    {:ok, current_turn}
  end

  # Matching global variable
  defp resolve_var({:var, [var_name]}, %{variables: vars})
       when :erlang.is_map_key(var_name, vars) do
    %GlobalVariable{value: value} = vars[var_name]
    {:ok, value}
  end

  # Accessing a variable owned by the current player.
  defp resolve_var({:var, [:"?current_player", var_name]}, %{active_role: player} = state) do
    resolve_var({:var, [player, var_name]}, state)
  end

  # Matching player variable
  defp resolve_var({:var, [player, var_name]}, %{variables: vars})
       when :erlang.is_map_key(var_name, vars) do
    case vars[var_name] do
      %PlayerVariable{values: %{^player => value}} ->
        {:ok, value}

      %GlobalVariable{} ->
        {:error, "global variable `#{format_identifier(var_name)}` was used as a player variable"}

      _ ->
        {:error,
         "unknown player #{format_identifier(player)} used to access the `#{
           format_identifier(var_name)
         }` variable"}
    end
  end

  # Other way of parsing player variables, apparently.
  defp resolve_var({:var, [{:variable, {player, var_name}}]}, state) do
    resolve_var({:var, [player, var_name]}, state)
  end

  # And another one. Probably calling current player on variable.
  defp resolve_var({:var, [{:event, var_name, [player]}]}, state) do
    with {:ok, player} <- reduce_expr(player, state) do
      resolve_var({:var, [player, var_name]}, state)
    end
  end

  # Unknown global variable
  defp resolve_var({:var, [var_name]}, _vars) do
    {:error, "unknown global variable `#{format_identifier(var_name)}`"}
  end

  # Unknown player variable
  defp resolve_var({:var, [_player, var_name]}, _vars) do
    {:error, "unknown player variable `#{format_identifier(var_name)}`"}
  end

  # Special case for if-expressions
  defp resolve_var({:if, {condition, when_true, when_false}}, vars) do
    with {:ok, condition} <- resolve_var(condition, vars),
         {:ok, when_true} <- resolve_var(when_true, vars),
         {:ok, when_false} <- resolve_var(when_false, vars) do
      {:ok, {:if, {condition, when_true, when_false}}}
    end
  end

  # Any other result
  defp resolve_var(other_value, _vars) do
    {:ok, other_value}
  end

  # Internally we convert all tiles to a struct, but they are
  # parsed as {x, y} tuples. We need to convert between them so
  # we can do equality checks.
  defp extract_tile(%Board.Tile{x: x, y: y}), do: {x, y}
  defp extract_tile(other), do: other

  defp lift({:ok, x}), do: x

  @doc """
  Goes through a collection of reduced values and returns the
  first one that matches an error tuple, otherwise `:none`.

  ## Examples

      iex> Language.Interpreter.find_expr_errors([{:ok, 10}, {:error, "error"}])
      {:error, "error"}

      iex> Language.Interpreter.find_expr_errors([{:ok, true}, {:ok, 10}])
      :none

  """
  @spec find_expr_errors([reduced_expr]) :: {:error, String.t()} | :none
  def find_expr_errors(values) do
    Enum.find(values, :none, &match?({:error, _}, &1))
  end
end
