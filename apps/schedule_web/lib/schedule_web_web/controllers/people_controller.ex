defmodule ScheduleWebWeb.PeopleController do
  use ScheduleWebWeb, :controller
  alias Phoenix.LiveView
  alias ScheduleWebWeb.PeopleLive.Index

  def index(conn, _params) do
    LiveView.Controller.live_render(conn, Index, session: %{})
  end
end
