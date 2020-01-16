defmodule Server.EventDispatcher do
  @moduledoc """
  We have different events that can alter the game. Some of
  them are pre-specified in the language, and others are defined
  by the user.
  """

  import Language.Interpreter, only: [reduce_expr: 2, reduce_args: 2]

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
  @spec dispatch(event, GameState.t()) :: GameState.state_update
  def dispatch(event, state)

  # Moving to a new tile: [move_to: [{:var, [:"?current_player"]}, {2, 3}]]
  def dispatch({:move_to, [_, _] = args}, state) do
    with {:ok, [role, tile]} <- reduce_args(args, state) do
      GameState.move_to_tile(state, role, tile)
    end
  end

  # Moving to a new tile and specifying the path: move_to: ["keir", {3, 9}, {3, 8}, {3, 7}, {3, 6}]
  def dispatch({:move_to, [role | path]}, state) do
    with {:ok, path} <- reduce_args(path, state),
         {:ok, role} <- reduce_expr(role, state) do
      GameState.move_via_path(state, role, path)
    end
  end

  # Setting player variable: [{:set!, [{:variable, {"a", "circuits"}}, 10]}]
  def dispatch({:set!, [{:variable, {role, var_name}}, new_value]}, state) do
    with {:ok, role} <- reduce_expr(role, state),
         {:ok, var_name} <- reduce_expr(var_name, state),
         {:ok, new_value} <- reduce_expr(new_value, state) do
      GameState.set_variable(state, {:player, var_name, role, new_value})
    end
  end

  def dispatch({:set!, [{:event, var_name, [role]}, new_value]}, state) do
    with {:ok, var_name} <- reduce_expr(var_name, state),
         {:ok, role} <- reduce_expr(role, state),
         {:ok, new_value} <- reduce_expr(new_value, state) do
      GameState.set_variable(state, {:player, var_name, role, new_value})
    end
  end

  # Setting global variable
  def dispatch({:set!, [var_name, new_value]}, state) do
    with {:ok, new_value} <- reduce_expr(new_value, state),
         {:ok, var_name} <- reduce_expr(var_name, state) do
      GameState.set_variable(state, {:global, var_name, new_value})
    end
  end

  def dispatch({:set_meta!, [_, _, _] = args}, state) do
    with {:ok, [tile, meta, new_value]} <- reduce_args(args, state) do
      GameState.set_meta(state, meta, tile, new_value)
    end
  end

  def dispatch({:skip_turn, [_, _] = args}, state) do
    with {:ok, [role, duration]} <- reduce_args(args, state) do
      GameState.miss_turns(state, role, duration)
    end
  end

  def dispatch(state, {:broadcast, [message]}) do
    dispatch({:broadcast_to, [message, GameState.roles(state)]}, state)
  end

  def dispatch({:broadcast_to, [_, _] = args}, state) do
    with {:ok, [message, roles]} <- reduce_args(args, state) do
      GameState.register_broadcast(state, message, roles)
    end
  end

  def dispatch({:win, [role]}, state) do
    with {:ok, role} <- reduce_expr(role, state) do
      GameState.win(state, role)
    end
  end

  def dispatch({:lose, [role]}, state) do
    with {:ok, role} <- reduce_expr(role, state) do
      role
    end
  end

  def dispatch({:choose_card, []}, state) do
    GameState.choose_card(state)
  end

  def dispatch(unknown_event, _state) do
    {:error,
     "Unknown dispatch `#{inspect(unknown_event)}`. This probably means your parentheses are nested incorrectly."}
  end
end
