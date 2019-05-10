defmodule ScheduleWebWeb.PeopleLive.Index do
  use Phoenix.LiveView
  alias Schedule.Repo
  alias Schedule.Person
  alias Schedule.Recordings
  alias ScheduleWebWeb.PeopleView
  alias ScheduleWebWeb.Router.Helpers, as: Routes

  import Ecto.Query, only: [order_by: 3]

  def mount(_session, socket) do
    people = Person|> order_by([p], asc: p.is_attending, asc: p.doctor_id) |> Repo.all()
    {:ok, assign(socket, people: people,
        weekday_id: nil,
        reserve_id: nil,
        month: nil
      )}
  end

  def render(assigns) do
    PeopleView.render("index.html", assigns)
  end

  def handle_event("update_month", %{"year"=> year, "month"=> month, "r_start" => r_start, "r_end" => r_end}, socket) do
    date = Date.from_iso8601!("#{year}-#{month}-01")
    if r_start != "" && r_end !="" do
      start_day = Date.from_iso8601!(("#{year}-#{month}-#{r_start}"))
      end_day = Date.from_iso8601!(("#{year}-#{month}-#{r_end}"))
      should_be_removed = Schedule.Month.generate_continuous_reserve(start_day, end_day)
    Schedule.MonthServer.set_this_month(date, [], [], should_be_removed)
    else
    Schedule.MonthServer.set_this_month(date)
    end
    {:noreply, socket}
  end

  def handle_event("reset_month",_ , socket) do
    case Recordings.reset_all_reserve() do
      {_, _term } ->
        {:stop,
         socket
         |> put_flash(:info, "all reserved are reset successfully")
         |> redirect(to: Routes.people_path(socket, :index))}
      {_, nil} ->
        {:noreply, socket}
    end
  end



  def handle_event("weekday" <> person_id, _, socket) do
    person_id = String.to_integer(person_id)
    changeset = socket.assigns.people
    |> Enum.find(&(&1.doctor_id == person_id))
    |> Recordings.change_person()
    |> Map.put(:action, :update)
    {:noreply, assign(socket, changeset: changeset, weekday_id: person_id)}
  end


  def handle_event("reserve" <> person_id, _, socket) do
    person_id = String.to_integer(person_id)
    changeset = socket.assigns.people
    |> Enum.find(&(&1.doctor_id == person_id))
    |> Recordings.change_person()
    |> Map.put(:action, :update)
    {:noreply, assign(socket, changeset: changeset, reserve_id: person_id)}
  end


  def handle_event("save_wk_day", %{"id" => person_id, "person" => person_params}, socket) do
    person_id = String.to_integer(person_id)
    person = Enum.find(socket.assigns.people, &(&1.doctor_id == person_id))
    case Recordings.update_weekday(person, person_params) do
      {:ok, _person} ->
        {:stop,
         socket
         |> put_flash(:info, "Week day updated successfully")
         |> redirect(to: Routes.people_path(socket, :index))}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end


  def handle_event("save_reserve", %{"id" => person_id, "person" => person_params}, socket) do
    person_id = String.to_integer(person_id)
    person = Enum.find(socket.assigns.people, &(&1.doctor_id == person_id))

    case Recordings.update_reserve(person, person_params) do
      {:ok, _person} ->
        {:stop,
         socket
         |> put_flash(:info, "Reserve Days updated successfully")
         |> redirect(to: Routes.people_path(socket, :index))}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end


end
