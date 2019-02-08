defmodule Server.Game.RoleSupervisor do
  @moduledoc """

  """

  use Supervisor
  alias Server.GamesRegistry
  alias Server.Game.Role

  def start_link({server_id, roles}) do
    Supervisor.start_link(__MODULE__, roles, name: via_tuple(server_id))
  end

  defp via_tuple(server_id) do
    GamesRegistry.via_tuple({__MODULE__, server_id})
  end

  def init(roles) do
    children = Enum.map(roles, &{Role, &1})
    Supervisor.init(children, strategy: :one_for_one)
  end
end
