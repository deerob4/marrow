defmodule EditorWeb.GameController do
  use EditorWeb, :controller

  alias Editor.Games

  plug EditorWeb.CheckAuth

  action_fallback EditorWeb.FallbackController

  def create(conn, _params) do
    with {:ok, game} <- Games.create_game(conn.assigns.user.id) do
      render(conn, "created.json", game: game)
    end
  end

  def delete(conn, %{"id" => game_id}) do
    with {:ok, _game} <- Games.delete_game(game_id) do
      render(conn, "deleted.json")
    end
  end

  def update(conn, %{"id" => game_id, "game" => game_params}) do
    with {:ok, game} <- Games.update_game(game_id, game_params) do
      render(conn, "updated.json", game: game)
    end
  end
end
