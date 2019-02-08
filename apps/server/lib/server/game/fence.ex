defmodule Server.Game.Fence do
  @moduledoc """
  Worker process responsible for authenticating incoming requests
  to join the game.

  ┌────────────────────────+++ Server Supervision Tree +++────────────────────────┐
  │                                                                               │
  │  ╔═════════════════════════════════════════════════════════════════════════╗  │
  │  ║                             GamesSupervisor                             ║  │
  │  ╚═════════════════════════════════════════════════════════════════════════╝  │
  │                                       │                                       │
  │                                       │                                       │
  │                                       │                                       │
  │                                       ▼                                       │
  │                             ┏━━━━━━━━━━━━━━━━━━━┓                             │
  │                             ┃                   ┃                             │
  │                             ┃  GameSupervisor   ┃                             │
  │                             ┃                   ┃                             │
  │                             ┗━━━━━━━━━━━━━━━━━━━┛                             │
  │                                       │                                       │
  │                      ┌────────────────┼──────────────────┐                    │
  │                      ▼                ▼                  │                    │
  │                   .─────.          .─────.               ▼                    │
  │                  ╱       ╲        ╱       ╲    ╔═══════════════════╗          │
  │                 (  Auth   )      (  Game   )   ║  RolesSupervisor  ║          │
  │                  `.     ,'        `.     ,'    ╚═══════════════════╝          │
  │                    `───'            `───'                │                    │
  │                                                          │                    │
  │                                                          │                    │
  │                                    ┌────────┬────────┬───┴────┬────────┐      │
  │                                    │        │        │        │        │      │
  │                                    │        │        │        │        │      │
  │                                    ▼        ▼        ▼        ▼        ▼      │
  │                                 .─────.  .─────.  .─────.  .─────.  .─────.   │
  │                                (  Joe  )( John  )( Mike  )( Paul  )( Matt  )  │
  │                                 `─────'  `─────'  `─────'  `─────'  `─────'   │
  │                                                                               │
  └───────────────────────────────────────────────────────────────────────────────┘
  """

  use GenServer
  alias Server.{Configuration, GamesRegistry}

  @typedoc """
  Indicates the authentication status of a game.

  ## Statuses

      * `:password_required` - the creator of the game has set a
        password on this game, and it must be entered before
        connection is allowed.

      * `:allowed` - no authentication is necessary, and the
        connection attempt can proceed.

      * `:already_started` - the game has already started, but
        the owner has not allowed additional spectators to watch.
        The game therefore cannot be joined.

  """
  @type auth_status :: :password_required | :allowed | :already_started

  @typedoc """
  Indicates the possible stages that the game might be in.

  ## Stages

      * `:lobby` - holding area before the game has started,
        where players choose their roles and can mingle.

      * `:in_progress` - the main stage where turn-based
        gameplay takes place.

      * `:results` - the game is over, and results are being
        shown to the players.

  """
  @type stage :: :lobby | :in_progress | :results

  def start_link({server_id, %Configuration{} = config}) do
    GenServer.start_link(__MODULE__, config, name: via_tuple(server_id))
  end

  defp via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  @spec password_requirement(Server.Game.server_id()) :: :password_required | :no_password
  def password_requirement(server_id) do
    GenServer.call(via_tuple(server_id), :password_requirement)
  end

  @doc """
  Returns `true` either if the password matches the one previously
  set for this game or no password was set, otherwise `false`.
  """
  @spec valid_password?(Server.Game.server_id(), String.t()) :: boolean
  def valid_password?(server_id, password) do
    GenServer.call(via_tuple(server_id), {:valid_password?, password})
  end

  @impl true
  def init(%Configuration{password: password, allow_spectators: allow_spectators}) do
    state = %{password: password, allow_spectators: allow_spectators, stage: :lobby}
    {:ok, state}
  end

  @impl true
  def handle_call(:password_requirement, _from, %{password: nil} = state) do
    {:reply, :no_password, state}
  end

  def handle_call(:password_requirement, _from, state) do
    {:reply, :password_required, state}
  end

  @impl true
  def handle_info(:game_started, state) do
    {:noreply, %{state | stage: :in_progress}}
  end

  def handle_info(:game_ended, state) do
    {:noreply, %{state | stage: :results}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
