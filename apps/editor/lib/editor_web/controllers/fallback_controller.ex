defmodule EditorWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, _, %Ecto.Changeset{} = cset, %{}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EditorWeb.ChangesetView)
    |> render("error.json", changeset: cset)
  end

  def call(conn, {:error, "unauthorised"}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(EditorWeb.ErrorView)
    |> render("unauthorised.json")
  end

  def call(conn, {:error, %Ecto.Changeset{} = cset}) do
    conn
    |> put_status(500)
    |> put_view(EditorWeb.ChangesetView)
    |> render("error.json", changeset: cset)
  end
end
