defmodule Server.Game.Lobby do
  @moduledoc """
  Lobby module.
  """

  use GenServer

  alias Server.{Game, GamesRegistry}
  alias ServerWeb.Endpoint

  @typep role :: String.t()

  @type role_info :: %{name: role, available?: boolean}

  @type select_role :: :ok | {:error, :already_taken}

  @type join_payload :: %{
          roles: [role_info],
          countdown: integer | nil,
          min_players_reached?: boolean
        }

  @typep role_status :: :available | :taken

  # Client

  def start_link({server_id, _roles, _wait_time, _player_counts} = params) do
    GenServer.start_link(__MODULE__, params, name: via_tuple(server_id))
  end

  @doc false
  def via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  @doc """
  Returns a payload containing information about the state of
  the lobby. See `t:join_payload` for more information.

  The payload will include the following values:

    * `min_players_reached?` - whether or not the minimum number
      of players required for the game to start have joined the
      lobby and confirmed a role.

    * `countdown` - the number of seconds left until the game is
      due to begin, or `nil` if not enough players have joined.

  """
  @spec join_payload(Game.server_id()) :: join_payload
  def join_payload(server_id) do
    GenServer.call(via_tuple(server_id), :join_payload)
  end

  @doc """
  Marks the given `role` as taken, reserving it for the player.

  This function will return `:ok` if the request is successful,
  or `{:error, :already_taken}` if `role` has already been
  reserved by another player.
  """
  @spec select_role(Game.server_id(), role) :: select_role
  def select_role(server_id, role) do
    GenServer.call(via_tuple(server_id), {:select_role, role})
  end

  @doc """
  Releases the previously taken `role`, allowing it to be
  selected again by other players.
  """
  @spec release_role(Game.server_id(), role) :: :ok
  def release_role(server_id, role) do
    GenServer.cast(via_tuple(server_id), {:release_role, role})
  end

  def reset(server_id), do: GenServer.cast(via_tuple(server_id), :reset)

  # Server

  @impl true
  def init({server_id, roles, wait_time, {min_players, max_players}}) do
    state = %{
      server_id: server_id,
      min_players: min_players,
      max_players: max_players,
      min_players_reached?: false,
      roles:
        Map.new(roles, fn %{name: name, repr: {repr_type, repr_value}} ->
          {name, %{status: :available, repr: %{type: repr_type, value: repr_value}}}
        end),
      countdown: wait_time,
      timer_ref: nil,
      # So we can reset it if the countdown gets cancelled.
      wait_time: wait_time
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:select_role, role}, _from, %{roles: roles} = state) do
    case roles[role] do
      %{status: :available} ->
        roles = put_in(roles, [role, :status], :taken)

        if not state.min_players_reached? and min_players_reached?(roles, state.min_players) do
          send(self(), :min_players_reached)
        end

        {:reply, :ok, %{state | roles: roles}}

      %{status: :taken} ->
        {:reply, {:error, :already_taken}, state}
    end
  end

  def handle_call(:join_payload, _from, %{roles: roles, countdown: countdown} = state) do
    payload = %{
      roles: list_roles(roles),
      countdown: countdown,
      min_players_reached?: state.min_players_reached?
    }

    {:reply, payload, state}
  end

  @impl true
  def handle_cast({:release_role, role}, %{roles: roles} = state) do
    roles = put_in(roles, [role, :status], :available)
    taken_count = taken_role_count(roles)

    if taken_count < state.min_players && state.min_players_reached? do
      send(self(), :cancel_countdown)
    end

    {:noreply, %{state | roles: roles, min_players_reached?: taken_count >= state.min_players}}
  end

  @impl true
  def handle_info(:min_players_reached, %{server_id: server_id} = state) do
    :ok = Endpoint.broadcast("game:#{server_id}", "lobby:min_players_reached", %{})
    send(self(), :countdown)
    {:noreply, %{state | min_players_reached?: true}}
  end

  def handle_info(:countdown, %{countdown: 0, server_id: server_id} = state) do
    :ok = Game.begin_game(server_id)
    {:noreply, state}
  end

  def handle_info(:countdown, %{countdown: countdown, server_id: server_id} = state) do
    countdown = countdown - 1
    timer_ref = Process.send_after(self(), :countdown, 1000)
    :ok = Endpoint.broadcast("game:#{server_id}", "lobby:countdown", %{countdown: countdown})
    {:noreply, %{state | countdown: countdown, timer_ref: timer_ref}}
  end

  def handle_info(:cancel_countdown, %{timer_ref: timer_ref, server_id: server_id} = state) do
    :ok = Endpoint.broadcast("game:#{server_id}", "lobby:countdown_cancelled", %{})
    Process.cancel_timer(timer_ref)
    {:noreply, %{state | timer_ref: nil, countdown: state.wait_time}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  @spec min_players_reached?(%{role => role_status}, integer) :: boolean
  defp min_players_reached?(roles, min_players) do
    taken_role_count(roles) >= min_players
  end

  @spec list_roles(%{role => role_status}) :: [role_info]
  defp list_roles(roles) do
    Enum.map(roles, fn {name, %{repr: repr, status: status}} ->
      %{name: name, available?: status === :available, repr: repr}
    end)
  end

  @spec taken_role_count(%{role => role_status}) :: integer
  defp taken_role_count(roles) do
    Enum.count(roles, &match?({_, %{status: :taken}}, &1))
  end
end
