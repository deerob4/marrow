defmodule Server.GameMonitor do
  @moduledoc """
  Monitors all created games.
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_game(pid, server_id) do
    GenServer.cast(__MODULE__, {:monitor_game, pid, server_id})
  end

  def list_keys() do
    GenServer.call(__MODULE__, :list_games)
  end

  @impl true
  def init(%{}) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:list_games, _from , games) do
    {:reply, Map.values(games), games}
  end

  @impl true
  def handle_cast({:monitor_game, pid, server_id}, games) do
    Process.monitor(pid)
    {:noreply, Map.put(games, pid, server_id)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, :shutdown}, games) do
    {:noreply, Map.delete(games, pid)}
  end
end
