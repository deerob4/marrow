defmodule Server.Game do
  @moduledoc """
  The main game process module.
  """

  use GenServer

  alias Server.{Configuration, GamesRegistry}

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
          description: String.t()
        }

  @type join_payload :: %{
          stage: stage,
          password_required?: boolean,
          metadata: metadata,
          joinable?: boolean
        }

  # Client

  def start_link({metadata, game, server_id, %Configuration{} = config}) do
    GenServer.start_link(__MODULE__, {metadata, game, config}, name: via_tuple(server_id))
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
  def correct_password?(server_id, guess) do
    GenServer.call(via_tuple(server_id), {:correct_password?, guess})
  end

  # Server

  @impl true
  def init({metadata, game, config}) do
    metadata_fields = [:id, :title, :description, :min_players, :max_players]

    state = %{
      metadata: Map.take(metadata, metadata_fields),
      stage: :lobby,
      config: config,
      game: game
    }

    {:ok, state}
  end

  # defp create_metadata()

  @impl true
  def handle_call(:join_payload, _, %{config: config, metadata: metadata, stage: stage} = state) do
    payload = %{
      metadata: metadata,
      stage: stage,
      password_required?: config.password != nil,
      joinable?: config.allow_spectators || stage === :lobby
    }

    {:reply, payload, state}
  end

  def handle_call({:correct_password?, guess}, _from, %{config: %{password: password}} = state) do
    {:reply, password === guess, state}
  end
end
