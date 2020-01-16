defmodule EditorWeb.GameView do
  use EditorWeb, :view

  def render("created.json", %{game: game}) do
    %{message: "created", data: render("simple.json", game: game)}
  end

  def render("updated.json", %{game: game}) do
    %{message: "updated", data: render("simple.json", game: game)}
  end

  def render("deleted.json", _) do
    %{message: "deleted"}
  end

  def render("show.json", %{game: game}) do
    %{id: game.id,
      title: game.title,
      description: game.description,
      source: game.source,
      is_public: game.is_public,
      min_players: game.min_players,
      max_players: game.max_players,
      author: game.user.name,
      cover_image: game.cover_image}
  end

  def render("simple.json", %{game: game}) do
    %{id: game.id,
      title: game.title,
      description: game.description,
      coverUrl: game.cover_image,
      isPublic: game.is_public}
  end
end
