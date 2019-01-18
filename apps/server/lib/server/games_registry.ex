defmodule Server.GamesRegistry do
  @moduledoc """
  Process registry for games.
  """

  def start_link(_) do
    Registry.start_link(name: __MODULE__, keys: :unique)
  end

  @doc """
  Returns a `via_tuple` that can be used for process
  registration with the given `key`.

  ## Examples

      iex> Server.GamesRegistry.via_tuple(10)
      {:via, Registry, {Server.GamesRegistry, 10}}

  """
  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(opts) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    )
  end
end
