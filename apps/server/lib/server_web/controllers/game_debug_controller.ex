defmodule ServerWeb.GameDebugController do
  use ServerWeb, :controller

  import Phoenix.LiveView.Controller

  alias ServerWeb.{LayoutView, GameDebugLive}

  def index(conn, _) do
    conn
    |> put_layout({LayoutView, "debug.html"})
    |> live_render(GameDebugLive, session: %{})
  end
end
