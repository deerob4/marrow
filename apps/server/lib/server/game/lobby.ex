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

  @spec start_link([role]) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(roles) do
    GenServer.start_link(__MODULE__, roles)
  end

  defp via_tuple(game_id) do
    GamesRegistry.via_tuple({__MODULE__, game_id})
  end

  @doc """
  Returns a list of all the roles and whether or not they are
  available to play as.
  """
  @spec list_roles(Game.server_id()) :: [role_info]
  def list_roles(server_id) do
    GenServer.call(via_tuple(server_id), :list_roles)
  end

  @doc """
  Marks the given `role` as taken, reserving it for the player.

  This function will return `:ok` if the request is successful,
  or `{:error, :already_taken}` if `role` has already been
  reserved by another player.
  """
  @spec select_role(Game.server_id(), role) :: select_role
  def select_role(server_id, role) do
    GenServer.call(via_tuple(server_id), {:select_role, role})
  end

  @doc """
  Releases the previously taken `role`, allowing it to be
  selected again by other players.
  """
  @spec release_role(Game.server_id(), role) :: :ok
  def release_role(server_id, role) do
    GenServer.cast(via_tuple(server_id), {:release_role, role})
  end

  # Server

  @impl true
  def init(roles) do
    state = %{
      roles: Map.new(roles, &{&1, :available})
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:available_roles, _from, %{roles: roles} = state),
    do: {:reply, available_roles(roles), state}

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
    for {:available, role} <- roles, do: role
  end
end
