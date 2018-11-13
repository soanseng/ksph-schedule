defmodule Schedule.AttendingServer do
  use GenServer
  alias Schedule.Person
  alias Schedule.Repo
  alias Schedule.Month
  import Ecto.Query

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get_attending}, _from, people) do
    {:reply, people, people}
  end

  def handle_cast({:get_attending_db, min_sheng_id}, people) do
    query =
      from(
        p in Person,
        where: p.is_attending == true and p.doctor_id != ^min_sheng_id
      )

    attendings =
      Repo.all(query)
      |> Map.new(fn attending -> {attending.doctor_id, attending} end)

    {:noreply, Map.merge(people, attendings)}
  end

  def handle_cast({:update, id, new_data}, people) do
    {:noreply, Map.put(people, id, new_data)}
  end

  def handle_cast({:remove, list_ids}, people) do
    attendings =
      Stream.filter(people, fn {key, value} -> !Enum.member?(list_ids, key) end) |> Enum.into(%{})

    {:noreply, attendings}
  end

  def handle_cast({:reset, default}, people) do
    {:noreply, Map.merge(people, default)}
  end

  def handle_cast({:set_max_points, this_month}, people) do
    extra_point = Enum.count(people) * 2 - Month.all_points(this_month)

    new_people =
      people
      |> Stream.map(fn {key, value} -> {key, %{value | max_point: 2}} end)
      |> Enum.into(%{})

    adjusted =
      new_people
      |> Enum.sort_by(fn {key, value} -> value.ranking end)
      |> Stream.take(extra_point)
      |> Stream.map(fn {key, value} -> {key, %{value | max_point: 1}} end)
      |> Enum.into(%{})

    {:noreply, Map.merge(new_people, adjusted)}
  end

  def handle_cast(
        {:attending_reserve, id, weekdays_reserve, reserve_days, duty_wish, weekday_wish},
        people
      ) do
    person = Map.get(people, id)

    new_person = %{
      person
      | reserve_days: reserve_days,
        weekday_reserve: weekdays_reserve,
        duty_wish: duty_wish,
        weekday_wish: [weekday_wish | person.weekday_wish] |> List.flatten()
    }

    {:noreply, Map.put(people, id, new_person)}
  end
end
