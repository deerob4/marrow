defmodule Server.Game do
  @moduledoc """
  The main game process module.
  """

  require Logger

  use GenServer

  alias Language.Model
  alias Server.{Configuration, GameState, GamesRegistry}
  alias Server.Game.{Event, UserList}
  alias ServerWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @type server_id :: String.t()

  @typedoc """
  The available stages of a game.

  The available stages are:

    * `:lobby` - the game has not yet started, and is still open
       to new players joining.

    * `:in_progress` - the game has started, and play is
      ongoing.

  """
  @type stage :: :lobby | :in_progress

  @type metadata :: %{
          id: integer,
          title: String.t(),
          description: String.t(),
          max_turns: integer | nil
        }

  @type join_payload :: %{
          stage: stage,
          password_required?: boolean,
          game_metadata: metadata,
          started_at: DateTime.t(),
          joinable?: boolean,
          events: [Event.t()]
        }

  @type state_payload :: %{
          events: [String.t()],
          game_state: Server.GameState.t(),
          tiles: [Language.Model.Board.tile()]
        }

  @typep state :: map

  @type turn_stage :: :waiting_for_roll | :rolling | :moving_pieces | :choosing_card

  @typep card_action :: String.t()

  # Number of ms between tile hops.
  @movement_speed 250

  # Client

  def start_link({%Model{} = model, server_id, %Configuration{} = config}) do
    GenServer.start_link(
      __MODULE__,
      {model, server_id, config},
      name: via_tuple(server_id)
    )
  end

  defp via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  @doc """
  Returns information about the game that a client can use when
  first connecting.

  It is expected that the client will use the information to
  determine what to show to the end user. The following fields
  are included within the payload:

    * `stage` - the current stage that the game is at.

    * `metadata` - a collection of metadata about the game, such as
      its title.

    * `password_required` - whether or not a password is required
      to join this game.

    * `joinable` - whether or not the game is available for
      people to join. This is usually `false` if the game is in
      progress and the owner has disallowed spectators.

  """
  @spec join_payload(server_id) :: join_payload
  def join_payload(server_id) do
    GenServer.call(via_tuple(server_id), :join_payload)
  end

  @doc """
  Returns true if `guess` matches the password set for this game,
  otherwise `false`.

  This function will always return `false` if no password was
  set.
  """
  @spec correct_password?(server_id, any) :: boolean
  def correct_password?(server_id, guess) do
    GenServer.call(via_tuple(server_id), {:correct_password?, guess})
  end

  @doc """
  Instructs the game server to start the game proper.
  """
  @spec begin_game(server_id) :: :ok
  def begin_game(server_id) do
    GenServer.cast(via_tuple(server_id), :begin_game)
  end

  @doc """
  Returns the current state of the game.

  Most of this information will be sent to all connected clients
  at the start of the game and then patched with updates as the
  game progresses, but clients who join midway through will need
  to get the entire payload.
  """
  @spec state_payload(server_id) :: state_payload
  def state_payload(server_id) do
    GenServer.call(via_tuple(server_id), :state_payload)
  end

  @doc """
  Rolls the dice for the current player and returns the result.
  The game state will be updated with the latest details.
  """
  @spec roll_dice(server_id) :: GameState.next_tile()
  def roll_dice(server_id) do
    GenServer.call(via_tuple(server_id), :roll_dice)
  end

  @doc """
  When a card is shown to the player and several options are
  available, they can choose a particular one.
  """
  @spec pick_card_action(server_id, card_action) :: :ok
  def pick_card_action(server_id, card_action) do
    GenServer.cast(via_tuple(server_id), {:pick_card_action, card_action})
  end

  # Server

  @impl true
  def init({model, server_id, config}) do
    metadata_fields = [:id, :title, :description, :min_players, :max_players, :max_turns]

    state = %{
      id: server_id,
      model: model,
      started_at: DateTime.utc_now(),
      metadata: Map.take(model, metadata_fields),
      stage: :lobby,
      game_state: nil,
      turn_stage: :waiting_for_roll,
      config: config,
      turn_time_limit: model.turn_time_limit,
      turn_time_remaining: nil,
      timer_ref: nil,
      events: []
    }

    Logger.debug("Game #{server_id}: Initialising state")

    {:ok, state}
  end

  @impl true
  def handle_call(:join_payload, _, %{config: config, metadata: metadata, stage: stage} = state) do
    payload = %{
      game_metadata: metadata,
      stage: stage,
      started_at: state.started_at,
      password_required?: config.password != nil,
      joinable?: config.allow_spectators || stage === :lobby,
      events: state.events
    }

    {:reply, payload, state}
  end

  def handle_call({:correct_password?, guess}, _from, %{config: %{password: password}} = state) do
    {:reply, password === guess, state}
  end

  def handle_call(:state_payload, _, state) do
    {:reply, construct_state_payload(state), state}
  end

  def handle_call(:roll_dice, _, %{game_state: game, turn_stage: :waiting_for_roll} = state) do
    prev_tile = game.role_positions[game.active_role]

    {game, %{role: role, rolled: rolled, path: [_ | path]} = next_tile} =
      GameState.roll_dice(game)

    Endpoint.broadcast("game:#{state.id}", "game:new_event", %{
      event: %Event{
        player: game.active_role,
        turn: game.current_turn,
        event: %Event.RollEvent{rolled: rolled}
      }
    })

    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    send(self(), {:move_board_piece, {role, path, prev_tile}})
    {:reply, next_tile, %{state | timer_ref: nil, game_state: game}}
  end

  @impl true
  def handle_cast(:begin_game, %{id: id, model: model} = state) do
    # A list of roles that have been selected by the players in the lobby.
    roles = UserList.roles(id)
    game_state = GameState.initialise(model, roles)

    Endpoint.subscribe("game:#{id}")

    state =
      state
      # We no longer need the model because all the info is in the game state.
      |> Map.delete(:model)
      |> Map.put(:game_state, game_state)
      |> Map.put(:stage, :in_progress)

    payload = construct_state_payload(state)
    Logger.debug("Game #{id}: Switching to in progress stage")
    Endpoint.broadcast("game:#{id}", "lobby:begin_game", payload)
    send(self(), :begin_countdown)

    {:noreply, state}
  end

  def handle_cast(
        {:pick_card_action, action_id},
        %{id: id, game_state: game, turn_stage: :choosing_card} = state
      ) do
    Endpoint.broadcast("game:#{id}", "game:hide_card", %{})

    game
    |> GameState.pick_card_action(action_id)
    |> handle_state_change(state)
  end

  @spec construct_state_payload(state) :: state_payload
  defp construct_state_payload(%{game_state: game_state, events: events}) do
    %{
      game_state: game_state,
      events: events,
      tiles:
        game_state.board.path_lines
        |> Enum.map(&Language.Model.Board.please_generate_path/1)
        |> List.flatten()
        |> Enum.uniq()
    }
  end

  @impl true
  def handle_info(
        %Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        state
      ) do
    current_turn = state.game_state.current_turn
    join_events = Enum.map(joins, &create_presence_event(&1, current_turn, %Event.JoinEvent{}))
    leave_events = Enum.map(leaves, &create_presence_event(&1, current_turn, %Event.LeaveEvent{}))

    {:noreply, %{state | events: state.events ++ join_events ++ leave_events}}
  end

  # Turn countdown timer

  # If we try and start a countdown but one was never set then we
  # can just ignore the message.
  def handle_info(:begin_countdown, %{turn_time_limit: nil} = state) do
    {:noreply, state}
  end

  def handle_info(:begin_countdown, %{turn_time_limit: limit} = state) do
    send(self(), :countdown)
    {:noreply, %{state | turn_time_remaining: limit}}
  end

  def handle_info(:countdown, %{id: id, game_state: game, turn_time_remaining: 0} = state) do
    Endpoint.broadcast("game:#{id}", "game:new_event", %{
      event: %Event{
        player: game.active_role,
        turn: game.current_turn,
        event: %Event.MissTurnEvent{}
      }
    })

    Endpoint.broadcast("game:#{id}", "game:turn_timeout", %{})
    Logger.debug("Game #{id}: Turn #{game.current_turn} timed out")
    {:noreply, state, {:continue, :next_turn}}
  end

  def handle_info(:countdown, %{id: id, turn_time_remaining: remaining} = state) do
    timer_ref = Process.send_after(self(), :countdown, 1000)
    remaining = remaining - 1
    Endpoint.broadcast("game:#{id}", "game:turn_countdown", %{remaining: remaining})
    {:noreply, %{state | turn_time_remaining: remaining, timer_ref: timer_ref}}
  end

  # Moving board pieces

  def handle_info({:move_board_piece, {role, [tile | rest], prev}}, %{id: id} = state) do
    Logger.debug("Game #{id}: Moving #{role} to #{inspect(tile)}")
    Endpoint.broadcast("game:#{id}", "game:move_board_piece", %{role: role, tile: tile})
    Process.send_after(self(), {:move_board_piece, {role, rest, prev}}, @movement_speed)
    {:noreply, %{state | turn_stage: :moving}}
  end

  def handle_info({:move_board_piece, {role, [], prev}}, %{id: id, game_state: game} = state) do
    Logger.debug("Game #{id}: Finished moving #{role}")

    event = %{
      event: %Event{
        player: role,
        turn: game.current_turn,
        event: %Event.MovementEvent{
          prev_tile: prev,
          new_tile: game.role_positions[role]
        }
      }
    }

    Endpoint.broadcast("game:#{id}", "game:new_event", event)
    Endpoint.broadcast("game:#{id}", "game:finish_moving_piece", %{})

    {:noreply, %{state | turn_stage: :waiting_for_roll}, {:continue, :next_turn}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_continue(:next_turn, %{game_state: game} = state) do
    game
    |> GameState.next_turn()
    |> handle_state_change(state)
  end

  def handle_continue({:player_won, role}, %{id: id} = state) do
    Logger.debug("Game #{id}: #{role} won the game")
    Endpoint.broadcast("game:#{id}", "game:player_won", %{winning_role: role})
    {:stop, :shutdown, state}
  end

  def handle_continue({:show_card, card}, %{id: id} = state) do
    Endpoint.broadcast("game:#{id}", "game:show_card", %{card: card})
    {:noreply, %{state | turn_stage: :choosing_card}}
  end

  defp create_presence_event({_, %{metas: [%{role: role}]}}, current_turn, type) do
    %Event{turn: current_turn, player: role, event: type}
  end

  # The next turn could be called by the thing or the thing.

  defp handle_state_change({:continue, game}, %{id: id} = state) do
    send(self(), :begin_countdown)
    Logger.debug("Game #{id}: Moved to turn #{game.current_turn}")
    # Broadcast the events that took place
    Enum.each(
      game.event_queue,
      &Endpoint.broadcast("game:#{id}", "game:new_event", %{event: &1})
    )

    # Broadcast the new game state to the clients.
    Endpoint.broadcast("game:#{id}", "game:new_state", %{game: game})
    {:noreply, %{state | game_state: game}}
  end

  defp handle_state_change({:card, card, game}, state) do
    {:noreply, %{state | game_state: game}, {:continue, {:show_card, card}}}
  end

  defp handle_state_change({:win, role, game}, %{id: id} = state) do
    Endpoint.broadcast("game:#{id}", "game:new_state", %{game: game})
    {:noreply, %{state | game_state: game}, {:continue, {:player_won, role}}}
  end

  defp handle_state_change({:timeup, %{current_turn: turn}}, %{id: id} = state) do
    Endpoint.broadcast("game:#{id}", "game:timeup", %{})
    Logger.debug("Game #{id}: Max turns reached: #{turn} out of #{turn}")
    {:stop, :shutdown, state}
  end

  defp handle_state_change({:move, role, path, current_tile, game}, state) do
    send(self(), {:move_board_piece, {role, path, current_tile}})
    {:noreply, %{state | game_state: game}}
  end

  defp handle_state_change({:error, reason}, %{id: id, game_state: game} = state) do
    Endpoint.broadcast("game:#{id}", "game:new_state", %{
      game: %{game | current_turn: game.current_turn + 1}
    })

    Endpoint.broadcast("game:#{id}", "game:source_error", %{error: reason})
    Logger.error("Game #{id}: #{reason}")
    {:stop, :shutdown, state}
  end

  # @impl true
  # def terminate(reason, %{id: id}) do
  #   IO.inspect reason
  #   Server.GamesSupervisor.terminate_game(id)
  # end
end
