defmodule Server.GameSupervisor do
  @moduledoc """
  DynamicSupervisor module responsible for managing the root
  game processes.
  """

  use DynamicSupervisor
  alias Server.{Game, GamesRegistry}

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [])
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
  def init([game_id, configuration]) do
  end
end
