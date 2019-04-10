defmodule ScheduleWebWeb.PeopleLive.Index do
  use Phoenix.LiveView
  alias Schedule.Repo
  alias Schedule.Person
  alias ScheduleWebWeb.PeopleView

  def mount(_session, socket) do
    people = Repo.all(Person)
    {:ok, assign(socket, people: people)}
  end

  def render(assigns) do
    PeopleView.render("index.html", assigns)
  end
end
