defmodule Server.Game.UserList do
  @moduledoc """
  Stores a list of user ids that are allowed to join the game, so
  that players who leave midway through can come back again.

  Only one process will ever be accessing this, so the list is
  stored using a simple `GenServer`.
  """

  use GenServer
  alias Server.{Game, GamesRegistry}

  def start_link(server_id) do
    GenServer.start_link(__MODULE__, %{}, name: via_tuple(server_id))
  end

  defp via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  @doc """
  Adds the given `user_id` to the list of allowed ids.
  """
  @spec register_user(Game.server_id(), String.t()) :: :ok
  def register_user(server_id, user_id) do
    GenServer.cast(via_tuple(server_id), {:register_user, user_id})
  end

  @doc """
  Associates the given `role` with `user_id`.

  This allows the user to keep their role even after
  disconnecting from the game.
  """
  @spec associate_role_with_user(Game.server_id(), String.t(), String.t()) :: :ok
  def associate_role_with_user(server_id, user_id, role) do
    GenServer.cast(via_tuple(server_id), {:associate_role_with_user, user_id, role})
  end

  @doc """
  Returns the role associated with the `user_id`, or `nil` if
  user is not in the game.
  """
  @spec user_role(Game.server_id(), String.t()) :: Language.role() | nil
  def user_role(server_id, user_id) do
    GenServer.call(via_tuple(server_id), {:user_role, user_id})
  end

  @doc """
  Returns `true` has previously joined the game, otherwise `false`.
  """
  @spec user_in_game?(Game.server_id(), String.t()) :: boolean
  def user_in_game?(server_id, user_id) do
    GenServer.call(via_tuple(server_id), {:user_in_game?, user_id})
  end

  @doc """
  Returns a list of roles in the game.
  """
  @spec roles(Game.server_id()) :: [Language.role()]
  def roles(server_id) do
    GenServer.call(via_tuple(server_id), :roles)
  end

  @doc """
  Returns a list of all the user-ids eligible to join the game.
  """
  @spec list_users(Game.server_id()) :: [String.t()]
  def list_users(server_id) do
    GenServer.call(via_tuple(server_id), :list_users)
  end

  @impl true
  def init(%{}) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:user_in_game?, user_id}, _from, user_ids) do
    {:reply, Map.has_key?(user_ids, user_id), user_ids}
  end

  def handle_call({:user_role, user_id}, _from, user_ids) do
    {:reply, user_ids[user_id], user_ids}
  end

  def handle_call(:list_users, _from, user_ids) do
    {:reply, user_ids, user_ids}
  end

  def handle_call(:roles, _from, user_ids) do
    {:reply, Map.values(user_ids), user_ids}
  end

  @impl true
  def handle_cast({:register_user, user_id}, user_ids) do
    {:noreply, Map.put(user_ids, user_id, nil)}
  end

  def handle_cast({:associate_role_with_user, user_id, role}, user_ids) do
    {:noreply, Map.put(user_ids, user_id, role)}
  end
end
