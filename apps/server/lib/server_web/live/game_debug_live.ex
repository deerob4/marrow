defmodule ServerWeb.GameDebugLive do
  use Phoenix.LiveView
  alias Server.GamesSupervisor

  def render(assigns) do
    ServerWeb.GameDebugView.render("index.html", assigns)
  end

  def mount(_, socket) do
    send(self(), :poll)
    {:ok, assign_games(socket)}
  end

  def handle_event("refresh", _, socket) do
    {:noreply, assign_games(socket)}
  end

  def handle_event("terminate_game", server_id, socket) do
    GamesSupervisor.terminate_game(server_id)
    {:noreply, assign_games(socket)}
  end

  def handle_event("terminate_all", _params, socket) do
    Enum.each(socket.assigns.games, fn {server_id, _, _} ->
      GamesSupervisor.terminate_game(server_id)
    end)

    {:noreply, assign_games(socket)}
  end

  defp assign_games(socket) do
    assign(socket, :games, GamesSupervisor.list_games())
  end

  def handle_info(:poll, socket) do
    Process.send_after(self(), :poll, 1000)
    {:noreply, assign_games(socket)}
  end
end
