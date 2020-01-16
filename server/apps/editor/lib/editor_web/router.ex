defmodule EditorWeb.Router do
  use EditorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", EditorWeb do
    pipe_through :api

    resources "/games", GameController, only: [:create, :update, :delete]
    resources "/accounts", AccountController
    resources "/assets", AssetController, only: [:create, :update, :delete]
    resources "/sessions", SessionController, only: [:show, :create, :delete], param: "token"
  end

  scope "/", EditorWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/games", PageController, :index
    get "/signup", PageController, :index
    get "/signin", PageController, :index
    get "/games/:game", PageController, :index
  end
end
