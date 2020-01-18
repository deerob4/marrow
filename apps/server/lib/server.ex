defmodule Server do
  @moduledoc """
  Server keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Server.Configuration
  alias Server.GamesSupervisor

  @typedoc """
  A unique id at which every game can be accessed.
  """
  @type game_id :: String.t()

  @doc """
  Start up a new game for the game description file with the
  given `game_id`.
  """
  @spec host_game(integer, map) :: {:ok, game_id}
  def host_game(game_id, config) do
    cset = Configuration.changeset(%Configuration{}, config)

    if cset.valid? do
      config = Ecto.Changeset.apply_changes(cset)
      server_id = UUID.uuid4(:hex)
      {:ok, _} = GamesSupervisor.start_game(game_id, server_id, config)
      {:ok, server_id}
    else
      cset
    end
  end

  @doc """
  Cancels the game with the given `game_id`.

  This will kill the associated processes, so if the game is
  currently in progess it will end immediately.
  """
  @spec cancel_game(game_id) :: :ok
  def cancel_game(_game_id) do
    :ok
  end
end
