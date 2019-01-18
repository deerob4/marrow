defmodule ServerWeb.HostedGameView do
  use ServerWeb, :view

  def render("created.json", %{id: id}) do
    %{status: "created", data: %{id: id}}
  end

  def render("deleted.json", _) do
    %{status: "deleted"}
  end
end
