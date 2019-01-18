defmodule Server.GameState do
  @moduledoc """
  Purely functional model representing the state of an ongoing
  game.
  """

  alias __MODULE__
  alias Server.GameState.MissedTurns
  alias Language.{Environment, Model}
  alias Language.Model.{Card, Board, Trigger}

  defstruct role_positions: %{},
            current_turn: 0,
            active_role: nil,
            role_order: %{},
            cards: {},
            board: nil,
            callbacks: nil,
            events: nil,
            triggers: nil,
            variables: nil,
            metadata: %{},
            miss_turns: %{},
            dice_rolls: %{}

  @type role :: String.t()

  @type position_map :: %{required(role) => Board.tile()}

  @type t :: %__MODULE__{
          role_positions: %{required(role) => Language.Board.tile()},
          current_turn: integer,
          active_role: role,
          board: nil,
          variables: Environment.t(),
          events: Environment.t(),
          callbacks: Environment.t(),
          triggers: [Trigger.t()],
          metadata: map,
          cards: %{required(String.t()) => [Card.t()]},
          miss_turns: %{required(role) => [MissedTurns.t()]},
          dice_rolls: %{required(role) => {pos_integer, pos_integer}}
        }

  @doc """
  Creates a new state model from the given `%Language.Model{}`
  struct.

  The game state will be initialised according to how the model
  lays out the start of the game.
  """
  @spec initialise(Model.t()) :: t
  def initialise(%Model{} = model) do
    {first_move, role_order} = generate_role_order(model.start_order, model.roles)

    %GameState{
      current_turn: 1,
      role_order: role_order,
      active_role: first_move,
      variables: create_variable_env(model.global_vars, model.player_vars),
      callbacks: Environment.new(),
      events: Environment.new(),
      triggers: model.triggers,
      metadata: model.metadata,
      cards: Enum.group_by(model.cards, & &1.stack),
      dice_rolls: Map.new(model.roles, &{&1, []}),
      miss_turns: Map.new(model.roles, &{&1, []}),
      role_positions: role_position_map(model.start_tile, model.roles)
    }
  end

  defp generate_role_order(:random, roles),
    do: roles |> Enum.shuffle() |> role_cycle()

  defp generate_role_order(:as_written, roles),
    do: role_cycle(roles)

  defp generate_role_order(specific_order, _roles) when is_list(specific_order),
    do: role_cycle(specific_order)

  # Create a linking between the roles so that we can always
  # see who the next player is.
  # ["a", "b", "c"] -> %{"a" => "b", "b" => "c", "c" => "a"}
  @spec role_cycle([role]) :: {first :: role, %{required(role) => role}}
  defp role_cycle([first | _] = roles) do
    {first, role_cycle(roles, first, %{})}
  end

  defp role_cycle([], _first, roles), do: roles

  defp role_cycle([last], first, roles) do
    role_cycle([], first, Map.put(roles, last, first))
  end

  defp role_cycle([current | [next | _] = rest], first, roles) do
    role_cycle(rest, first, Map.put(roles, current, next))
  end

  @spec role_position_map(Board.tile(), [role]) :: position_map
  defp role_position_map(%Board.Tile{} = all_start, roles) do
    Map.new(roles, &{&1, all_start})
  end

  # If a position has been assigned to each role, then a map will
  # have already been parsed so we can just use that.
  @spec role_position_map(position_map, [role]) :: position_map
  defp role_position_map(role_map, _roles) when is_map(role_map), do: role_map

  # We need to merge the global and player variables into one env.
  @spec create_variable_env(Model.variables(), Model.variables()) :: t
  defp create_variable_env(global_vars, player_vars) do
    env = Environment.new()
    vars = Map.merge(global_vars, player_vars)

    Enum.reduce(vars, env, fn {name, value}, env ->
      {:ok, env} = Environment.set(env, name, value)
      env
    end)
  end

  @doc """
  Rolls the dice specified in the game state and returns the
  outcome.

  All dice rolls are also stored so that they may be retrieved
  at a later date.
  """
  @spec roll_dice(t) :: {pos_integer, t}
  def roll_dice(%GameState{active_role: active_role, current_turn: current_turn} = state) do
    roll = 1

    state =
      update_in(state, [:dice_rolls, active_role], fn rolls ->
        [{current_turn, roll} | rolls]
      end)

    {1, state}
  end

  @doc """
  Moves the game to the next turn and returns the new game.

  This increments the `current_turn` value, and sets the active
  player to the next player.
  """
  @spec next_turn(t) :: t
  def next_turn(%GameState{} = state) do
    state
    |> increment_turn()
    |> set_next_player()
    |> handle_triggers()
  end

  defp increment_turn(%{current_turn: current_turn} = state) do
    %{state | current_turn: current_turn + 1}
  end

  defp set_next_player(%{active_role: current} = state) do
    with player when is_bitstring(player) <-
           next_player(current, state.role_order, state.current_turn, state.miss_turns) do
      %{state | active_role: player}
    end
  end

  defp next_player(current_role, role_order, current_turn, misses)
       when :erlang.is_map_key(current_role, role_order) do
    next_role = role_order[current_role]

    if can_make_turn?(misses[next_role], current_turn) do
      next_role
    else
      role_order = Map.delete(role_order, current_role)
      next_player(next_role, role_order, current_turn, misses)
    end
  end

  defp next_player(_, %{}, _, _), do: :skip_turn

  defp can_make_turn?(miss_turns, current_turn) do
    Enum.all?(miss_turns, &MissedTurns.can_move?(&1, current_turn))
  end

  defp handle_triggers(state) do
    state
  end

  @doc """
  Makes the given `role` miss `duration` number of turns.

  During the duration of this period, the role will be unable
  to move or participate directly in the game.
  """
  @spec miss_turns(t, role, integer) :: t
  def miss_turns(%GameState{} = state, role, duration) do
    missed_turns = %MissedTurns{duration: duration, set_on: state.current_turn}
    miss_turns = update_in(state.miss_turns, [role], &[missed_turns | &1])
    %{state | miss_turns: miss_turns}
  end

  @doc """
  Chooses a random card from the given `stack`.

  This function will return `:bad_stack` if the stack doesn't
  exist.
  """
  @spec choose_card(t, String.t()) :: Card.t() | :bad_stack
  def choose_card(%GameState{} = state, stack) do
    if Map.has_key?(state.cards, stack) do
      Enum.random(state.cards[stack])
    else
      :bad_stack
    end
  end

  @doc """
  Returns `true` if `role` is a valid player in the game,
  otherwise `false`.
  """
  @spec validate_role(t, role) :: :ok | :invalid_role
  def validate_role(%GameState{role_positions: roles} = _state, role) do
    case Map.has_key?(roles, role) do
      true -> :ok
      false -> :invalid_role
    end
  end

  def validate_coord(%GameState{board: _board}, _coord) do
    :ok
  end

  @doc """
  Returns the list of the game's available roles.
  """
  @spec roles(t) :: [role]
  def roles(%GameState{role_positions: role_positions}) do
    Map.keys(role_positions)
  end
end
