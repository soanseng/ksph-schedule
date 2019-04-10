defmodule ScheduleWebWeb.Router do
  use ScheduleWebWeb, :router

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

  scope "/", ScheduleWebWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/people", PeopleController, only: [:index]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ScheduleWebWeb do
  #   pipe_through :api
  # end
end
