defmodule ScheduleWebWeb.PeopleController do
  use ScheduleWebWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
