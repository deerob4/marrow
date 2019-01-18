defmodule Server do
  @moduledoc """
  Server keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Server.Configuration

  @typedoc """
  A unique id at which every game can be accessed.
  """
  @type game_id :: String.t()

  @doc """
  Start up a new game for the game description file with the
  given `game_id`.
  """
  @spec host_game(integer, map) :: {:ok, game_id}
  def host_game(_source_id, config) do
    cset = Configuration.changeset(%Configuration{}, config)

    if cset.valid? do
      key = generate_key(32)
      {:ok, key}
    else
      cset
    end
  end

  defp generate_key(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
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
