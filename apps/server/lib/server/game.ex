defmodule Server.Game do
  @moduledoc """
  The main game process module.
  """

  use GenServer

  alias Editor.Games
  alias Server.Configuration
  alias Server.GamesRegistry

  @type server_id :: String.t()

  @type stage :: :lobby | :in_progress

  # Client

  def start_link({server_id, game_id, %Configuration{} = config}) do
    GenServer.start_link(__MODULE__, {game_id, config}, name: via_tuple(server_id))
  end

  defp via_tuple(game_id) do
    GamesRegistry.via_tuple({__MODULE__, game_id})
  end

  @doc """
  Returns the current stage of the game.

  The available stages are:

    * `:lobby` - the game has not yet started, and is still open
       to new players joining.

    * `:in_progress` - the game has started, and play is
      ongoing.

  """
  @spec current_stage(server_id) :: stage
  def current_stage(server_id) do
    GenServer.call(via_tuple(server_id), :current_stage)
  end

  # Server

  @impl true
  def init({game_id, config}) do
    {:ok, config, {:continue, {:startup, game_id}}}
  end

  @impl true
  def handle_call(:current_stage, _from, %{stage: stage} = state),
    do: {:reply, stage, state}

  @impl true
  def handle_continue({:startup, game_id}, config) do
    game = Games.get_by_id!(game_id)
    # The game can only be available to play if it compiled successfully
    # in the editor so this match should always succeed.
    {:ok, model} = Language.to_game(game.source)
    game_state = Server.GameState.initialise(model)
    {:noreply, %{game: game_state, config: config, stage: :lobby}}
  end
end
