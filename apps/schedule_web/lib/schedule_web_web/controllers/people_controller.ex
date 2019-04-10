defmodule ScheduleWebWeb.PeopleController do
  use ScheduleWebWeb, :controller
  alias Schedule.Repo
  alias Schedule.Person

  def index(conn, _params) do
    people = Repo.all(Person)
    render(conn, "index.html", people: people)
  end
end
