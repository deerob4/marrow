defmodule EditorWeb.AccountView do
  use EditorWeb, :view

  def render("created.json", %{user: user, game: game, token: token}) do
    IO.inspect user
    IO.inspect game
    %{
      message: "created",
      data: %{
        token: token,
        user: EditorWeb.UserView.render("show.json", %{user: user}),
        games: [EditorWeb.GameView.render("simple.json", %{game: game})]
      }
    }
  end

  def render("deleted.json", %{user: user}) do
    %{message: "deleted", data: %{user: EditorWeb.UserView.render("show.json", %{user: user})}}
  end
end
