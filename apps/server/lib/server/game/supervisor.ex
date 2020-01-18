defmodule Server.Game.Supervisor do
  @moduledoc """
  Supervisor module for the different game components.
  """

  require Logger

  use Supervisor

  alias Server.{
    Configuration,
    GamesRegistry
  }

  alias Editor.{Games}

  def start_link({_game_id, server_id, %Configuration{}} = args) do
    Supervisor.start_link(__MODULE__, args, name: via_tuple(server_id))
  end

  defp via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  @impl true
  def init({game_id, server_id, config}) do
    game = Games.get_by_id!(game_id)
    {:ok, model} = Language.to_game(game.source)
    model = Editor.Assets.replace_image_metadata(model, game_id)
    roles = Enum.map(model.roles, fn {_, role} -> role end)

    children = [
      {Server.Game, {model, server_id, config}},
      {Server.Game.Lobby,
       {server_id, roles, config.wait_time, {model.min_players, model.max_players}}},
      {Server.Game.UserList, server_id}
    ]

    Server.GameMonitor.add_game(self(), server_id)

    Logger.info("Starting game server #{server_id} for game #{game_id}")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
