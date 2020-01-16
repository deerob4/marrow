defmodule Server.GamesSupervisor do
  @moduledoc """
  DynamicSupervisor module responsible for managing the root
  game processes.
  """

  use DynamicSupervisor

  alias Server.{Game, GamesRegistry, GameMonitor}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_game(game_id, server_id, configuration) do
    child_spec = {Server.Game.Supervisor, {game_id, server_id, configuration}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def terminate_game(server_id) do
    case Registry.lookup(GamesRegistry, {Game.Supervisor, server_id}) do
      [{pid, nil}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Returns a list of all the games, in the form
  `{server_id, stage, state}`.
  """
  @spec list_games() :: [{Game.server_id(),  Game.stage(), map}]
  def list_games() do
    Enum.map(GameMonitor.list_keys(), &game_info/1)
  end

  defp game_info(server_id) do
    case Game.join_payload(server_id) do
      %{stage: :lobby, game_metadata: metadata, started_at: time} ->
        {server_id, :lobby, Map.merge(%{started_at: time}, Map.merge(metadata, Game.Lobby.join_payload(server_id)))}

      %{stage: :in_progress, game_metadata: metadata, started_at: time} ->
        {server_id, :in_progress, Map.merge(%{started_at: time}, Map.merge(metadata, Game.state_payload(server_id)))}
    end
  end

  @doc """
  Returns `true` or `false` depending on whether a game with
  the given `id` is running.
  """
  @spec game_exists?(Game.server_id()) :: boolean
  def game_exists?(server_id) do
    case Registry.lookup(GamesRegistry, {Game, server_id}) do
      [{_pid, nil}] -> true
      [] -> false
    end
  end

  def game_pid(server_id) do
    case Registry.lookup(GamesRegistry, {Game, server_id}) do
      [{pid, nil}] -> pid
      [] -> nil
    end
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
