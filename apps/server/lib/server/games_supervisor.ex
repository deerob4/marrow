defmodule Server.GamesSupervisor do
  @moduledoc """
  DynamicSupervisor module responsible for managing the root
  game processes.
  """

  use DynamicSupervisor

  alias Server.{Game, GamesRegistry}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_game(game_id, server_id, configuration) do
    child_spec = {Server.Game.Supervisor, {game_id, server_id, configuration}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
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

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
