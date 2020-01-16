defmodule EditorWeb.AssetView do
  use EditorWeb, :view

  def render("updated.json", %{name: name}) do
    %{message: "updated", data: %{name: name}}
  end

  def render("deleted.json", _) do
    %{message: "deleted"}
  end
end
