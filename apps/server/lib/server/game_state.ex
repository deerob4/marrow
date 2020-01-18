defmodule Server.GameState do
  @moduledoc """
  Purely functional model representing the state of an ongoing
  game.
  """

  import Language.Formatter, only: [format_identifier: 1]

  alias __MODULE__
  alias Server.EventDispatcher
  alias Server.GameState.{Broadcast, MissedTurns}
  alias Server.Game.Event
  alias Language.{Environment, Interpreter, Model}

  alias Language.Model.{
    Board,
    Card,
    Dice,
    GlobalVariable,
    PlayerVariable,
    Role,
    Trigger
  }

  alias Board.Tile

  defimpl Jason.Encoder do
    @encoded_fields [:board, :current_turn, :role_positions, :active_role]

    def encode(game_state, opts) do
      game_state
      |> Map.take(@encoded_fields)
      |> Map.put(:metadata, encode_metadata(game_state.metadata))
      |> Map.put(:variables, extract_values(game_state.variables))
      |> Map.put(:roles, extract_values(game_state.roles))
      |> Jason.Encode.map(opts)
    end

    defp extract_values(map) do
      Enum.map(map, fn {_k, v} -> v end)
    end

    defp encode_metadata(metadata) do
      Map.new(metadata, fn {key, metadatas} ->
        metadatas =
          Enum.map(metadatas, fn {tile, value} ->
            %{tile: tile, value: value}
          end)

        {key, metadatas}
      end)
    end
  end

  defstruct role_positions: %{},
            current_turn: 0,
            max_turns: nil,
            active_role: nil,
            start_order: nil,
            role_order: %{},
            cards: [],
            dice: nil,
            displaying_card_id: nil,
            board: nil,
            roles: %{},
            callbacks: nil,
            events: nil,
            triggers: nil,
            variables: nil,
            metadata: %{},
            broadcast_queue: [],
            lose_queue: [],
            event_queue: [],
            miss_turns: %{},
            dice_rolls: %{}

  @type role :: String.t()

  @type variable_map :: %{String.t() => GlobalVariable.t() | PlayerVariable.t()}

  @type position_map :: %{required(role) => Board.tile()}

  @type variable_edit ::
          {:global, String.t(), Language.variable()}
          | {:player, String.t(), Language.role(), Language.variable()}

  @typedoc """
  Information about the player's movements after the dice have been rolled.
  """
  @type next_tile :: %{
          role: role,
          rolled: integer,
          next_tile: Tile.t(),
          path: [Tile.t()]
        }

  @type state_update ::
          {:continue, t}
          | {:win, role, t}
          | {:card, Card.t(), t}
          | {:move, role, [Board.tile()], Board.Tile.t(), t}
          | {:timeup, t}
          | {:error, String.t()}

  @type t :: %__MODULE__{
          role_positions: %{required(role) => Language.Board.tile()},
          current_turn: integer,
          max_turns: pos_integer | nil,
          active_role: role,
          # Save the order they specified so that if a player loses the game we
          # can regenerate a new order without losing their defined one.
          start_order: [role],
          board: nil,
          # ID of the card shown when the player is prompted to choose a card action.
          displaying_card_id: String.t() | nil,
          dice: Dice.t(),
          roles: %{Language.role() => Role.t()},
          variables: Environment.t(),
          events: Environment.t(),
          callbacks: Environment.t(),
          triggers: [Trigger.t()],
          # Any players that have lost due to a lose condition are listed here so they
          # can be removed at the start of the next turn. Same principle with the other
          # queues below:
          lose_queue: [role],
          event_queue: [Event.t()],
          broadcast_queue: [Broadcast.t()],
          metadata: map,
          cards: [Card.t()],
          miss_turns: %{required(role) => [MissedTurns.t()]},
          dice_rolls: %{required(role) => {pos_integer, pos_integer}}
        }

  @doc """
  Creates a new state model from the given `%Language.Model{}`
  struct.

  The game state will be initialised according to how the model
  lays out the start of the game.
  """
  # @spec initialise(Model.t()) :: t
  def initialise(%Model{} = model, used_roles) do
    model = Model.remove_unused_roles(model, used_roles)
    role_names = Enum.map(model.roles, fn {name, _} -> name end)

    start_order =
      case model.start_order do
        :random -> Enum.shuffle(role_names)
        :as_written -> role_names
        specific_order when is_list(specific_order) -> model.start_order
      end

    # {first_move, role_order} = generate_role_order(model.start_order, role_names)
    {first_move, role_order} = role_cycle(start_order)

    %GameState{
      current_turn: 1,
      role_order: role_order,
      start_order: start_order,
      active_role: first_move,
      variables: Map.merge(model.global_vars, model.player_vars),
      max_turns: model.max_turns,
      callbacks: model.callbacks,
      dice: model.dice,
      events: model.events,
      triggers: model.triggers,
      metadata: model.metadata,
      cards: model.cards,
      dice_rolls: map_from_roles(model.roles),
      miss_turns: map_from_roles(model.roles),
      role_positions: role_position_map(model.roles),
      roles: model.roles,
      board: model.board
    }
  end

  @spec map_from_roles(%{role => Role.t()}) :: %{role => []}
  defp map_from_roles(roles, value \\ []) do
    Map.new(roles, fn {name, _} -> {name, value} end)
  end

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

  @spec role_position_map(%{String.t() => Role.t()}) :: position_map
  defp role_position_map(roles) do
    Map.new(roles, fn {name, %{start_on: tile}} -> {name, tile} end)
  end

  @doc """
  Rolls the dice specified in the game state and returns the
  outcome.

  All dice rolls are also stored so that they may be retrieved
  at a later date.
  """
  @spec roll_dice(t) :: {t, next_tile}
  def roll_dice(%GameState{} = state) do
    rolled_value = Dice.roll(state.dice)
    record = %Dice.Roll{turn: state.current_turn, rolled: rolled_value}
    next_tile = find_next_tile(state, rolled_value)

    {state
     |> add_roll_events(rolled_value, next_tile)
     |> record_roll(record)
     |> set_new_position(next_tile), next_tile}
  end

  @spec add_roll_events(t, integer, next_tile) :: t
  defp add_roll_events(state, rolled, %{next_tile: next_tile}) do
    roll_event = %Event{
      turn: state.current_turn,
      player: state.active_role,
      event: %Event.RollEvent{rolled: rolled}
    }

    movement_event = %Event{
      turn: state.current_turn,
      player: state.active_role,
      event: %Event.MovementEvent{
        spaces_moved: rolled,
        prev_tile: state.role_positions[state.active_role],
        new_tile: next_tile
      }
    }

    state |> add_event(movement_event) |> add_event(roll_event)
  end

  @spec record_roll(t, Dice.Roll.t()) :: t
  defp record_roll(%{dice_rolls: dice_rolls, active_role: active_role} = state, roll) do
    rolls = update_in(dice_rolls, [active_role], &[roll | &1])
    %{state | dice_rolls: rolls}
  end

  @spec set_new_position(t, next_tile) :: t
  defp set_new_position(state, %{next_tile: next_tile}) do
    role_positions = Map.put(state.role_positions, state.active_role, next_tile)
    %{state | role_positions: role_positions}
  end

  @spec find_next_tile(t, integer) :: next_tile
  defp find_next_tile(%{active_role: role, role_positions: positions, board: board}, rolled)
       when rolled > 0 do
    # Get the coordinates of the role's current position.
    %{x: x, y: y} = positions[role]

    # Repeatedly get the next tile from the board for as many dice rolls
    # are, storing each intermediary result to create a list of the entire
    # path to get to the next tile.
    {{x, y}, path} =
      Enum.reduce_while(1..rolled, {{x, y}, []}, fn _, {{x, y} = tile, path} ->
        case Board.next_tile(board, tile) do
          nil -> {:halt, {tile, path}}
          next_tile -> {:cont, {next_tile, [%Tile{x: x, y: y} | path]}}
        end
      end)

    # The code above doesn't include the final tile in the path, so make
    # sure we include it.
    next_tile = %Tile{x: x, y: y}
    path = Enum.reverse([next_tile | path])

    %{role: role, rolled: rolled, next_tile: next_tile, path: path}
  end

  defp find_next_tile(%{active_role: role, role_positions: positions}, 0) do
    tile = positions[role]
    %{role: role, next_tile: tile, path: [tile]}
  end

  @doc """
  Moves the game to the next turn and returns the new game.

  This increments the `current_turn` value, and sets the active
  player to the next player.
  """
  @spec next_turn(t) :: state_update
  def next_turn(%GameState{} = state) do
    state = %{state | event_queue: [], broadcast_queue: []}

    with %GameState{} = state <- handle_triggers(state),
         %GameState{} = state <- set_next_player(state),
         %GameState{} = state <- increment_turn(state) do
      {:continue, state}
    end
  end

  defp increment_turn(%{current_turn: max_turns, max_turns: max_turns} = state) do
    with %GameState{} = state <- handle_timeup(state) do
      {:timeup, state}
    end
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

  defp handle_triggers(%{triggers: triggers} = state) do
    Enum.reduce_while(triggers, state, fn %Trigger{condition: condition, events: events}, acc ->
      case Language.Interpreter.reduce_expr(condition, acc) do
        {:ok, true} ->
          case apply_events(events, acc) do
            %GameState{} = state -> {:cont, state}
            error -> {:halt, error}
          end

        {:ok, false} ->
          # IO.inspect("No action taken for trigger #{inspect(condition)}")
          {:cont, acc}

        error ->
          {:halt, error}
      end
    end)
  end

  defp apply_events(events, state) do
    Enum.reduce_while(events, state, fn event, acc ->
      case EventDispatcher.dispatch(event, acc) do
        %GameState{} = state -> {:cont, state}
        # We need to collect all of these into one.
        error -> {:halt, error}
      end
    end)

    # [_ | states] =
    #   Enum.reduce_while(events, [{:continue, state}], fn event, [outcome | _] = acc ->
    #     case EventDispatcher.dispatch(event, extract_state(outcome)) do
    #       # We need to collect all of these into one.
    #       {:error, _} = error -> {:halt, [error | acc]}
    #       # t:state_update
    #       outcome -> {:cont, [outcome | acc]}
    #     end
    #   end)
    #   |> Enum.reverse()

    # states
  end

  defp extract_state({:continue, t}), do: t
  defp extract_state({:win, _, t}), do: t
  defp extract_state({:card, _, t}), do: t
  defp extract_state({:move, _, _, _, t}), do: t
  defp extract_state({:timeup, t}), do: t

  defp handle_timeup(%{callbacks: %{handle_timeup: _callback}} = state) do
    state
  end

  defp handle_timeup(state) do
    state
  end

  @doc """
  Makes the given `role` miss `duration` number of turns.

  During the duration of this period, the role will be unable
  to move or participate directly in the game.
  """
  @spec miss_turns(t, role, integer) :: state_update
  def miss_turns(%GameState{} = state, role, duration) do
    missed_turns = %MissedTurns{duration: duration, set_on: state.current_turn}
    miss_turns = update_in(state.miss_turns, [role], &[missed_turns | &1])
    {:continue, %{state | miss_turns: miss_turns}}
  end

  @doc """
  Chooses a random card from the available ones and sets it as the
  `displaying_card_id` field on `state`.

  If no cards have been defined, returns `:no_cards`.
  """
  @spec choose_card(t) :: state_update
  def choose_card(%GameState{cards: []}) do
    {:error, "can't choose a card; none have been defined"}
  end

  def choose_card(%GameState{cards: cards} = state) do
    card = %{id: id} = Enum.random(cards)

    with {:ok, card} <- Card.evaluate(card, state) do
      {:card, card, %{state | displaying_card_id: id}}
    end
  end

  @doc """
  Given a card chooses the given action on the card, and returns the
  game updated with the triggers done there.
  """
  @spec pick_card_action(t, String.t()) :: state_update
  def pick_card_action(%GameState{displaying_card_id: card_id, cards: cards} = state, action_id) do
    card = Enum.find(cards, &(&1.id === card_id))
    %Card.Action{events: events} = Enum.find(card.actions, &(&1.id === action_id))
    apply_events(events, state)
  end

  @doc """
  Moves the given `role` to the new `tile`.

  The role and tile will be validated, and an error returned
  if they are not.
  """
  @spec move_to_tile(t, role, Board.tile()) :: state_update
  def move_to_tile(%GameState{role_positions: role_positions} = state, role, %Tile{x: x, y: y})
      when :erlang.is_map_key(role, role_positions) do
    if Board.valid_tile?(state.board, {x, y}) do
      %Tile{x: cx, y: cy} = role_positions[role]
      current_tile = {cx, cy}
      to = %Tile{x: x, y: y}
      path = Board.path_to_tile(state.board, current_tile, {x, y})
      role_positions = Map.put(role_positions, role, to)
      {:move, role, path, %Tile{x: cx, y: cy}, %{state | role_positions: role_positions}}
      # {:continue, %{state | role_positions: role_positions}}
    else
      {:error,
       "can't move player `#{format_identifier(role)}` to tile #{Board.format_tile({x, y})} because it is out of range"}
    end
  end

  def move_to_tile(_state, role, _tile) do
    {:error, "can't move player `#{format_identifier(role)}` because they are not in the game"}
  end

  def move_via_path(%GameState{role_positions: role_positions} = state, role, path)
      when :erlang.is_map_key(role, role_positions) do
    current_tile = role_positions[role]
    travelling_to = List.last(path)
    role_positions = Map.put(role_positions, role, travelling_to)
    {:move, role, path, current_tile, %{state | role_positions: role_positions}}
  end

  def move_via_path(_state, role, _tile) do
    {:error, "can't move player `#{format_identifier(role)}` because they are not in the game"}
  end

  @doc """
  Returns the list of the game's available roles.
  """
  @spec roles(t) :: [role]
  def roles(%GameState{role_positions: role_positions}) do
    Map.keys(role_positions)
  end

  @doc """
  Sets the metadata for the given `category` for `tile`.
  """
  @spec set_meta(t, String.t(), Board.tile(), String.t()) :: state_update
  def set_meta(%GameState{metadata: metadata} = state, category, {x, y} = tile, new_value)
      when :erlang.is_map_key(category, metadata) do
    if Board.valid_tile?(state.board, tile) do
      metadata = put_in(metadata, [category, %Tile{x: x, y: y}], new_value)
      {:continue, %{state | metadata: metadata}}
    else
      {:error,
       "can't update metadata for tile #{Board.format_tile(tile)} because it is out of range"}
    end
  end

  def set_meta(_, category, _, _) do
    {:error,
     "can't update metadata category `#{format_identifier(category)}` because it was not statically declared"}
  end

  @doc """
  Sets the contents of the given `variable`.

  This function accepts two types of modifications, one for each
  variable type, as specified in `t:variable_edit`.
  """
  @spec set_variable(t, variable_edit) :: state_update
  def set_variable(state, variable)

  def set_variable(%GameState{} = state, {:global, var_name, new_value}) do
    with {:ok, new_value} <- Interpreter.reduce_expr(new_value) do
      case state.variables[var_name] do
        %GlobalVariable{} = current_var ->
          state =
            add_event(state, %Event{
              turn: state.current_turn,
              event: %Event.GlobalVariableEvent{variable: var_name, new_value: new_value}
            })

          new_var = GlobalVariable.update_value(current_var, new_value)
          variables = %{state.variables | var_name => new_var}
          {:continue, %{state | variables: variables}}

        nil ->
          {:error,
           "can't set variable `#{format_identifier(var_name)}` because it does not exist"}
      end
    end
  end

  def set_variable(%GameState{} = state, {:player, var_name, role, new_value}) do
    with {:ok, new_value} <- Interpreter.reduce_expr(new_value) do
      case state.variables[var_name] do
        # Variable found and the player exists.
        %PlayerVariable{values: %{^role => _}} = current_var ->
          state =
            add_event(state, %Event{
              turn: state.current_turn,
              player: role,
              event: %Event.PlayerVariableEvent{
                variable: var_name,
                new_value: new_value
              }
            })

          new_var = PlayerVariable.update_value(current_var, role, new_value)
          variables = %{state.variables | var_name => new_var}
          {:continue, %{state | variables: variables}}

        # Variable found but the player isn't in the game.
        %PlayerVariable{} ->
          {:error,
           "unknown role `#{format_identifier(role)}` used to access the `#{
             format_identifier(var_name)
           }` variable"}

        # Variable doesn't exist.
        nil ->
          {:error,
           "can't set variable `#{format_identifier(var_name)}` because it does not exist"}
      end
    end
  end

  @doc """
  Moves the given `role` to `new_tile`.

  This function can fail for two reasons:

  1. If `role` is not in the game.
  2. If `new_tile` is invalid according to the rules specified
     in `Language.Model.Board`.
  """
  @spec move_player(t, Language.role(), Board.Tile.t()) :: state_update
  def move_player(%GameState{} = state, role, new_tile) do
    with %{role_positions: %{^role => prev_tile} = positions} <- state do
      state =
        add_event(state, %Event{
          turn: state.current_turn,
          player: role,
          event: %Event.MovementEvent{prev_tile: prev_tile, new_tile: new_tile}
        })

      {:continue, %{state | positions: Map.put(positions, role, new_tile)}}
    else
      :invalid_tile ->
        {:error, "invalid board tile given to the `move-player` command"}

      %{role_positions: _} ->
        {:error, "invalid role #{format_identifier(role)} given to the `move-player` command"}
    end
  end

  defp add_event(%GameState{event_queue: event_queue} = state, %Event{} = event) do
    %{state | event_queue: [event | event_queue]}
  end

  @doc """
  Adds a broadcast to the game for it to be sent to `roles` on
  the next turn.
  """
  @spec register_broadcast(t, String.t(), [Language.role()]) :: state_update
  def register_broadcast(%GameState{broadcast_queue: broadcasts} = state, message, roles) do
    if all_roles_in_game?(state, roles) do
      broadcast = Broadcast.new(message, roles)
      {:ok, :continue, %{state | broadcast_queue: [broadcast | broadcasts]}}
    else
      {:error, "can't broadcast message because some of the players listed do not exist"}
    end
  end

  @doc """
  Checks whether `value` is the name of a player variable or event in
  the `game`.

  Returns `:player_variable`, `:event`, or `:none` depending on
  the value.
  """
  @spec valid_event_or_variable(t, any) :: :player_variable | :event | :none
  def valid_event_or_variable(game, value)

  def valid_event_or_variable(%GameState{variables: vars}, value)
      when :erlang.is_map_key(value, vars) do
    case vars[value] do
      %PlayerVariable{} -> :player_variable
      _ -> :none
    end
  end

  def valid_event_or_variable(%GameState{events: events}, value)
      when :erlang.is_map_key(value, events),
      do: :event

  def valid_event_or_variable(%GameState{}, _value), do: :none

  @doc """
  Sets the given `role` to win the game on the next turn.

  If `role` is not in the game, an error will be returned.
  """
  @spec win(t, role) :: state_update
  def win(%GameState{} = state, role) do
    if role_in_game?(state, role) do
      {:win, role, state}
    else
      {:error,
       "can't make player `#{format_identifier(role)}` win because they are not in the game"}
    end
  end

  @doc """
  Makes the given `role` lose the game on the next turn. This will
  result in them being removed from the game.
  """
  @spec lose(t, role) :: state_update
  def lose(%GameState{lose_queue: lose_queue} = state, role) do
    if role_in_game?(state, role) do
      # Recalculate the role order without the losing player
      remaining_roles = List.delete(state.start_order, role)
      {_, new_order} = role_cycle(remaining_roles)
      {:continue, %{state | role_order: new_order, lose_queue: [role | lose_queue]}}
    else
      {:error,
       "can't make player `#{format_identifier(role)}` lose because they are not in the game"}
    end
  end

  # Utility functions

  defp role_in_game?(%{role_positions: positions}, role),
    do: Map.has_key?(positions, role)

  defp all_roles_in_game?(state, roles),
    do: Enum.all?(roles, &role_in_game?(state, &1))
end
