defmodule EditorWeb.SessionView do
  use EditorWeb, :view

  def render("created.json", %{user: user, games: games, token: token}) do
    %{
      status: "signed in",
      data: %{
        token: token,
        user: EditorWeb.UserView.render("show.json", user: user),
        games: Enum.map(games, &EditorWeb.GameView.render("simple.json", game: &1))
      }
    }
  end

  def render("deleted.json", _) do
    %{status: "signed out"}
  end
end
