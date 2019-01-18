defmodule Server.Game.Lobby do
  @moduledoc """
  Lobby module.
  """

  use GenServer
  alias Server.{Game, GamesRegistry}

  @typep role :: String.t()

  @type role_info :: %{name: role, available?: boolean}

  @type select_role :: :ok | {:error, :already_taken}

  # Client

  def start_link({_roles, _password} = args) do
    GenServer.start_link(__MODULE__, args)
  end

  defp via_tuple(game_id) do
    GamesRegistry.via_tuple({__MODULE__, game_id})
  end

  @doc """
  Returns `true` if `password` matches the password required to
  join the game, otherwise `false.`

  If the game does not require a password to join, this function
  will always return `true`.
  """
  @spec valid_password?(Game.server_id(), String.t()) :: boolean
  def valid_password?(server_id, password) do
    GenServer.call(server_id, {:valid_password?, password})
  end

  @doc """
  Returns `true` if the game requires a password to join it,
  otherwise `false`.
  """
  @spec requires_password?(Game.server_id()) :: boolean
  def requires_password?(server_id) do
    GenServer.call(server_id, :requires_password?)
  end

  @doc """
  Returns a list of all the roles and whether or not they are
  available to play as.
  """
  @spec list_roles(Game.server_id()) :: [role_info]
  def list_roles(server_id) do
    GenServer.call(server_id, :list_roles)
  end

  @doc """
  Marks the given `role` as taken, reserving it for the player.

  This function will return `:ok` if the request is successful,
  or `{:error, :already_taken}` if `role` has already been
  reserved by another player.
  """
  @spec select_role(Game.server_id(), role) :: select_role
  def select_role(server_id, role) do
    GenServer.call(server_id, {:select_role, role})
  end

  @spec release_role(Game.server_id(), role) :: :ok
  def release_role(server_id, role) do
    GenServer.cast(server_id, {:release_role, role})
  end

  # Server

  @impl true
  def init({roles, password}) do
    state = %{
      password: password,
      roles: Map.new(roles, &{&1, :available})
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:available_roles, _from, %{roles: roles} = state),
    do: {:reply, available_roles(roles), state}

  def handle_call({:valid_password?, _password}, _from, %{password: nil} = state),
    do: {:reply, true, state}

  def handle_call({:valid_password?, password}, _from, %{password: pswd} = state),
    do: {:reply, password === pswd, state}

  def handle_call(:requires_password?, _from, %{password: password} = state),
    do: {:reply, password !== nil, state}

  def handle_call({:select_role, role}, _from, %{roles: roles} = state) do
    case roles[role] do
      :available ->
        {:reply, :ok, %{state | roles: Map.put(roles, role, :taken)}}

      :taken ->
        {:reply, {:error, :already_taken}, state}
    end
  end

  def handle_call(:list_roles, _from, %{roles: roles} = state) do
    role_info =
      Enum.map(roles, fn {name, status} ->
        %{
          name: name,
          available?: status === :available
        }
      end)

    {:reply, role_info, state}
  end

  @impl true
  def handle_cast({:release_role, role}, %{roles: roles} = state) do
    {:noreply, %{state | roles: Map.put(roles, role, :available)}}
  end

  @spec available_roles(%{role => boolean}) :: [role]
  defp available_roles(roles) do
    Enum.reduce(roles, [], fn
      {_, :taken}, acc -> acc
      {role, :available}, acc -> [role | acc]
    end)
  end
end
