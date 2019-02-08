defmodule Server.Game.Role do
  @moduledoc """

  """

  use GenServer
  alias Server.GamesRegistry

  def start_link({name, _variables}) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name) do
    GamesRegistry.via_tuple({__MODULE__, name})
  end

  @impl true
  def init(name) do
    {:ok, %{name: name, taken?: false}}
  end
end
