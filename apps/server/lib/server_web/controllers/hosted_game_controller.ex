defmodule ServerWeb.HostedGameController do
  @moduledoc """
  Controller for managing the hosted game resources.

  This controller deals entirely with creating, updating, and
  deleting hosted games, and does not actually run the games.
  """

  use ServerWeb, :controller

  alias Server

  def create(conn, %{"game_id" => game_id, "configuration" => config_params}) do
    IO.inspect config_params
    with {:ok, id} <- Server.host_game(game_id, config_params) do
      render(conn, "created.json", id: id)
    end
  end

  def delete(conn, %{"game_id" => game_id}) do
    with :ok <- Server.cancel_game(game_id) do
      render(conn, "deleted.json")
    end
  end
end
