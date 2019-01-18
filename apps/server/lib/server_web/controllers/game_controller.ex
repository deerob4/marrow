defmodule ServerWeb.GameController do
  use ServerWeb, :controller

  alias Editor.Games

  def index(conn, _params) do
    games = Games.list_public_games()
    render(conn, "index.html", games: games)
  end
end
