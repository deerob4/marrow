defmodule ServerWeb.GameChannel do
  use ServerWeb, :channel

  alias Server.{Game, GameSupervisor}
  alias Game.Lobby

  # Anyone can join the channel. But if the game has a password, their
  # socket connection will be marked as `:unauthorised` and they'll
  # have to provide a password to progress any further in the process.

  @impl true
  def join("game:" <> game_id, _, socket) do
    if GameSupervisor.game_exists?(game_id) do
      stage = Game.current_stage(game_id)

      socket =
        socket
        |> assign(:game_id, game_id)
        |> assign(:stage, stage)

      join_stage(stage, socket)
    else
      {:error, %{error: "invalid game id"}, socket}
    end
  end

  defp join_stage(:lobby, socket) do
    authorised? = Lobby.requires_password?(socket.assigns.game_id)
    socket = assign(socket, :authorised?, authorised?)
    {:ok, %{authorised?: authorised?}, socket}
  end

  defp join_stage(:in_progress, socket) do
    {:error, %{error: "not implemented yet"}, socket}
  end

  @impl true
  def handle_in("lobby:authorise", %{"password" => password}, socket) do
    if Lobby.valid_password?(socket.assigns.game_id, password) do
      roles = Lobby.list_roles(socket.assigns.game_id)
      {:reply, {:ok, roles}, socket}
    else
      {:reply, :invalid, socket}
    end
  end

  def handle_in("lobby:select_role", %{"role" => role}, socket) do
    case Lobby.select_role(socket.assigns.game_id, role) do
      :ok ->
        broadcast_from(socket, "lobby:role_taken", %{role: role})
        {:reply, :ok, socket}

      {:error, :already_taken} ->
        {:reply, :already_taken, socket}
    end
  end

  # If they leave the lobby having selected a role, release it so
  # that others can choose to play as it.
  @impl true
  def terminate({:shutdown, :left}, %{assigns: %{stage: :lobby, role: role}} = socket) do
    :ok = Lobby.release_role(socket.assigns.game_id, role)
    broadcast_from(socket, "lobby:role_released", %{role: role})
  end

  def terminate(_, _socket) do
    :ok
  end
end
