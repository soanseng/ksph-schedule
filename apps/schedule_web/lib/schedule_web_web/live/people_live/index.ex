defmodule ScheduleWebWeb.PeopleLive.Index do
  use Phoenix.LiveView
  alias Schedule.Repo
  alias Schedule.Person
  alias Schedule.Recordings
  alias ScheduleWebWeb.PeopleView
  alias ScheduleWebWeb.Router.Helpers, as: Routes

  def mount(_session, socket) do
    people = Repo.all(Person)
    {:ok, assign(socket, people: people, editable_id: nil)}
  end

  def render(assigns) do
    PeopleView.render("index.html", assigns)
  end

  def handle_event("edit" <> person_id, _, socket) do
    person_id = String.to_integer(person_id)
    changeset = socket.assigns.people
    |> Enum.find(&(&1.doctor_id == person_id))
    |> Recordings.change_person()
    |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset, editable_id: person_id)}
  end

  def handle_event("save", %{"id" => person_id, "person" => person_params}, socket) do
    person_id = String.to_integer(person_id)
    person = Enum.find(socket.assigns.people, &(&1.doctor_id == person_id))
    case Recordings.update_person(person, person_params) do
      {:ok, _person} ->
        {:stop,
         socket
         |> put_flash(:info, "Person updated successfully")
         |> redirect(to: Routes.people_path(socket, :index))}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

end
