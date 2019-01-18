defmodule AccountViewTest do
  use EditorWeb.ConnCase, async: true

  import Phoenix.View

  @user %{id: 1, name: "John Smith", email: "john@gmail.com"}

  test "renders created.json" do
    game = %{
      title: "game",
      description: "",
      source: "a",
      is_private: true,
      min_players: 2,
      max_players: 2,
      cover_image: ""
    }

    assert render(EditorWeb.AccountView, "created.json", user: @user, game: game) === %{
             message: "created",
             data: %{user: @user, game: game}
           }
  end

  test "renders deleted.json" do
    assert render(EditorWeb.AccountView, "deleted.json", user: @user) === %{
             message: "deleted",
             data: %{user: @user}
           }
  end
end
