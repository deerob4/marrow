defmodule Server.Game.TurnTimer do
  @moduledoc """
  Keeps track of the number of seconds that have elapsed in a
  game turn.
  """

  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :tick, 1000)
    {:ok, 0}
  end

  @impl true
  def handle_info(:tick, time) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, time + 1}
  end

  def handle_info(_, time) do
    {:noreply, time}
  end
end
