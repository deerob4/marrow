defmodule ServerWeb.GameChannel do
  use ServerWeb, :channel

  alias Server.{Game, GamesSupervisor, Presence}
  alias Game.{Lobby, UserList}

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
    game_id = socket.assigns.game_id

    if UserList.user_in_game?(game_id, user_id) do
      socket =
        socket
        |> assign(:user_id, user_id)
        |> assign(:role, UserList.user_role(game_id, user_id))

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

  # The first time they join the game we need to give them a
  # unique id so that they can rejoin with the same role etc.
  defp allow_first_time_access(payload, socket) do
    user_id = UUID.uuid4()
    :ok = UserList.register_user(socket.assigns.game_id, user_id)
    socket = assign(socket, :user_id, user_id)
    send(self(), :after_join)
    join_stage(payload, socket)
  end

  defp join_stage(%{stage: :lobby, game_metadata: game_metadata}, socket) do
    socket = assign(socket, :stage, :lobby)
    payload = Lobby.join_payload(socket.assigns.game_id)

    payload = %{
      stage: "lobby",
      game_metadata: game_metadata,
      roles: payload.roles,
      min_players_reached: payload.min_players_reached?,
      countdown: payload.countdown,
      user_id: socket.assigns.user_id
    }

    {:ok, payload, socket}
  end

  defp join_stage(%{stage: :in_progress, game_metadata: game_metadata}, socket) do
    payload = %{
      stage: "in_progress",
      game_metadata: game_metadata,
      game_state: Game.state_payload(socket.assigns.game_id),
      player_role: socket.assigns.role
    }

    socket = assign(socket, :stage, :in_progress)
    send(self(), :join_presence)
    {:ok, payload, socket}
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
    %{game_id: game_id, user_id: user_id} = socket.assigns

    case Lobby.select_role(socket.assigns.game_id, role) do
      :ok ->
        :ok = UserList.associate_role_with_user(game_id, user_id, role)
        socket = assign(socket, :role, role)
        broadcast_from(socket, "lobby:role_taken", %{role: role})
        send(self(), :join_presence)
        {:reply, :ok, socket}

      {:error, :already_taken} ->
        {:reply, :already_taken, socket}
    end
  end

  def handle_in("game:join", _, socket) do
    {:noreply, socket}
  end

  def handle_in("game:roll_dice", _, socket) do
    _next_tile = Game.roll_dice(socket.assigns.game_id)
    # broadcast(socket, "game:roll_dice_results", %{next_tile: next_tile})
    {:noreply, socket}
  end

  def handle_in("game:pick_card_action", %{"action_id" => action_id}, socket) do
    Game.pick_card_action(socket.assigns.game_id, action_id)
    # IO.inspect a
    {:noreply, socket}
  end

  @impl true
  def handle_info(:join_presence, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        role: socket.assigns.role
      })

    {:noreply, socket}
  end

  def handle_info(:game_started, socket) do
    {:noreply, assign(socket, :stage, :in_progress)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # If they leave the lobby having selected a role, release it so
  # that others can choose to play as it.
  @impl true
  def terminate({:shutdown, :closed}, %{assigns: %{stage: :lobby, role: role}} = socket) do
    :ok = Lobby.release_role(socket.assigns.game_id, role)
    broadcast_from(socket, "lobby:role_released", %{role: role})
  end

  def terminate(_reason, _socket) do
    :ok
  end
end
