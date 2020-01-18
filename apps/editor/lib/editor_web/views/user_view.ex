defmodule EditorWeb.UserView do
  use EditorWeb, :view

  def render("show.json", %{user: user}) do
    %{id: user.id, name: user.name, email: user.email}
  end
end
