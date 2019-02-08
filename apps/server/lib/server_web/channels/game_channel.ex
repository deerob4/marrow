defmodule ServerWeb.GameChannel do
  use ServerWeb, :channel

  alias Server.{Game, GamesSupervisor}
  alias Server.Presence
  alias Game.{Lobby}

  # Anyone can join the channel. But if the game has a password, their
  # socket connection will be marked as `:unauthorised` and they'll
  # have to provide a password to progress any further in the process.

  @impl true
  def join("game:" <> game_id, params, socket) do
    if GamesSupervisor.game_exists?(game_id) do
      socket = assign(socket, :game_id, game_id)
      payload = Game.join_payload(game_id)
      check_eligibility(payload, params, socket)
    else
      {:error, %{error: "invalid_game_id"}}
    end
  end

  defp check_eligibility(payload, params, socket)

  # If they're sending a user id then they're probably rejoining this
  # game after losing the connection or something. Check if this is the
  # case and if so let them join straight to the current stage.
  defp check_eligibility(payload, %{"user_id" => user_id} = params, socket) do
    if in_game?(user_id, socket) do
      socket = assign(socket, :user_id, user_id)
      join_stage(payload, socket)
    else
      # Otherwise just ignore the invalid user id and continue
      # with the normal eligibility checks.
      params = Map.drop(params, ["user_id"])
      check_eligibility(payload, params, socket)
    end
  end

  defp check_eligibility(%{joinable?: false}, _params, _socket) do
    {:error, %{error: "already_started"}}
  end

  defp check_eligibility(%{password_required?: true} = payload, %{"password" => password}, socket) do
    if Game.correct_password?(socket.assigns.game_id, password) do
      allow_first_time_access(payload, socket)
    else
      {:error, %{error: "incorrect_password"}}
    end
  end

  defp check_eligibility(%{password_required?: true}, _params, _socket) do
    {:error, %{error: "password_required"}}
  end

  defp check_eligibility(payload, _params, socket) do
    allow_first_time_access(payload, socket)
  end

  @spec in_game?(String.t(), Phoenix.Socket.t()) :: boolean
  defp in_game?(user_id, socket) do
    case Presence.get_by_key(topic(socket), user_id) do
      [] -> false
      [_] -> true
    end
  end

  defp topic(socket) do
    "game:#{socket.assigns.game_id}"
  end

  # The first time they join the game we need to give them a
  # unique id so that they can rejoin with the same role etc.
  defp allow_first_time_access(payload, socket) do
    user_id = UUID.uuid4()
    socket = assign(socket, :user_id, user_id)
    send(self(), :after_join)
    join_stage(payload, socket)
  end

  defp join_stage(%{stage: :lobby, metadata: metadata}, socket) do
    # roles = Lobby.list_roles(socket.assigns.game_id)
    roles = [
      %{name: "Keir", isTaken: false},
      %{name: "Dee", isTaken: false},
      %{name: "Jed", isTaken: false},
    ]

    payload = %{
      stage: "lobby",
      metadata: metadata,
      roles: roles,
      user_id: socket.assigns.user_id
    }

    {:ok, payload, socket}
  end

  defp join_stage(%{stage: :in_progress}, _socket) do
    {:error, %{error: "not yet implemented"}}
  end

  @impl true
  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns.user_id, %{})
    IO.inspect "tracked!"
    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_in("check_password", %{password: password}, socket) do
    if Game.correct_password?(socket.assigns.game_id, password) do
      {:reply, :correct, socket}
    else
      {:reply, :incorrect, socket}
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
