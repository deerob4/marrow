defmodule Server.EventDispatcher do
  @moduledoc """
  We have different events that can alter the game. Some of
  them are pre-specified in the language, and others are defined
  by the user.
  """

  import Language.Interpreter, only: [reduce_expr: 1]

  alias Language.Environment
  alias Server.GameState

  @type event :: any

  @typedoc """
  A variable that is tracked by the game.

  These can be accessed at any point in the game description,
  but may not be not manually mutated by the `set!` command.
  """
  @type global_var :: :"?current_player" | :"?current_tile" | :"?current_turn"

  @doc """
  Dispatches `event` on the game `state`, returning the updated
  state if successful.
  """
  @spec dispatch(GameState.t(), event) :: GameState.t()
  def dispatch(state, event)

  def dispatch(%{role_positions: positions} = state, {:move_to, [role, coord]}) do
    with :ok <- GameState.validate_role(state, role),
         :ok <- GameState.validate_coord(state, coord) do
      positions = Map.put(positions, role, coord)
      {:ok, %{state | role_positions: positions}}
    else
      :invalid_role ->
        build_error("move-to", "role `#{role}` does not exist")

      :invalid_coord ->
        build_error("move-to", "tile `#{coord}` is invalid")
    end
  end

  # Setting a player variable: {:set!, [{"score", ["a"]}, {:+, [10, 20]}]}
  def dispatch(%{variables: vars} = state, {:set!, [{variable, [player]}, new_value]}) do
    with {:ok, new_value} <- reduce_expr(new_value),
         {:player, var_map} <- get_variable_with_type(variable, vars),
         var_map = put_in(var_map, [player], new_value),
         {:ok, variables} <- Environment.replace(vars, variable, var_map) do
      {:ok, %{state | variables: variables}}
    else
      error -> set_error(error, variable)
    end
  end

  # Setting a global variable: {:set, ["score", {:+, [10, 20]}]}
  def dispatch(%{variables: vars} = state, {:set!, [variable, new_value]}) do
    with {:ok, new_value} <- reduce_expr(new_value),
         {:global, _var} <- get_variable_with_type(variable, vars),
         {:ok, variables} <- Environment.replace(vars, variable, new_value) do
      {:ok, %{state | variables: variables}}
    else
      error -> set_error(error, variable)
    end
  end

  def dispatch(state, {:increment!, [variable]}) do
    dispatch(state, {:set!, [variable, {:+, [variable, 1]}]})
  end

  def dispatch(state, {:decrement!, [variable]}) do
    dispatch(state, {:set!, [variable, {:-, [variable, 1]}]})
  end

  def dispatch(state, {:set_meta!, [tile, meta, new_value]}) do
    put_in(state, [:metadata, meta, tile], new_value)
  end

  def dispatch(state, {:skip_turn, [role, duration]}) do
    GameState.miss_turns(state, role, duration)
  end

  def dispatch(state, {:broadcast, [message]}) do
    dispatch(state, {:broadcast_to, [message, GameState.roles(state)]})
  end

  def dispatch(state, {:broadcast_to, [message, roles]}) do
  end

  # Return the variable from the environment tagged with its type.
  defp get_variable_with_type(variable_name, vars) do
    case Environment.get(vars, variable_name) do
      {:ok, %{} = var} -> {:player, var}
      {:ok, var} -> {:global, var}
      :not_found -> :not_found
    end
  end

  defp build_error(function, error) do
    {:error, "error in `#{function}`: #{error}"}
  end

  defp set_error(error, variable) do
    case error do
      {:player, _} ->
        build_error(
          "set!",
          "variable `#{variable}` is a player variable but is being used as a global"
        )

      {:global, _} ->
        build_error(
          "set!",
          "variable `#{variable}` is a global variable but is being used as a player"
        )

      :not_found ->
        build_error("set!", "variable `#{variable}` doesn't exist")

      _ ->
        error
    end
  end

  @doc """

  """
  @spec derive(global_var, GameState.t()) :: Language.variable()
  def derive(global_var, state)

  def derive(:"?current_player", %{active_role: current_player}),
    do: current_player

  def derive(:"?current_tile", %{active_role: current_player, role_positions: positions}),
    do: positions[current_player]

  def derive(:"?current_turn", %{current_turn: current_turn}), do: current_turn
end
