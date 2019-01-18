defmodule EditorWeb.AccountController do
  use EditorWeb, :controller
  alias Editor.Accounts

  action_fallback EditorWeb.FallbackController

  def create(conn, %{"account" => account_params}) do
    with {:ok, %{user: user, game: game, token: token}} <- Accounts.create_account(account_params) do
      conn
      |> assign(:user, user)
      |> assign(:game, game)
      |> assign(:token, token)
      |> render("created.json")
    end
  end

  def delete(conn, %{"user_id" => user_id}) do
    with {:ok, %{id: ^user_id}} <- Accounts.delete_account(user_id) do
      render(conn, "deleted.json")
    end
  end
end
