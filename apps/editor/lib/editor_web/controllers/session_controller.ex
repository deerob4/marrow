defmodule EditorWeb.SessionController do
  use EditorWeb, :controller

  alias Editor.{Accounts, Games}

  action_fallback EditorWeb.FallbackController

  def create(conn, %{"credentials" => %{"email" => email, "password" => password}}) do
    with {:ok, user, token} <- Accounts.signin(email, password) do
      login_success(conn, user, token)
    end
  end

  def show(conn, %{"token" => token}) do
    with {:ok, user} <- Accounts.get_from_token(token) do
      login_success(conn, user, token)
    end
  end

  defp login_success(conn, user, token) do
    conn
    |> assign(:user, user)
    |> assign(:games, Games.list_games_for_user(user.id))
    |> assign(:token, token)
    |> render("created.json")
  end

  def delete(conn, %{"token" => token}) do
    with {:ok, _} <- Accounts.signout(token) do
      render(conn, "deleted.json")
    end
  end
end
