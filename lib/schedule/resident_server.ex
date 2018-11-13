defmodule Schedule.ResidentServer do
  use GenServer
  alias Schedule.Person
  alias Schedule.Repo
  import Ecto.Query

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get}, _from, people) do
    {:reply, people, people}
  end

  def handle_cast({:get_residents_db, min_level, eda}, people) do
    query =
      from(
        p in Person,
        where: p.is_attending == false and p.level >= ^min_level and p.doctor_id != ^eda
      )

    residents =
      Repo.all(query)
      |> Map.new(fn resident -> {resident.doctor_id, resident} end)

    {:noreply, Map.merge(people, residents)}
  end

  def handle_cast({:set_holiday_points, id, max_point, max_holiday}, people) do
    person = Map.get(people, id)
    new_person = %{person | max_holiday: max_holiday, max_point: max_point}
    {:noreply, Map.put(people, id, new_person)}
  end

  def handle_cast({:set_reserve, id, weekdays, reserve_days}, people) do
    person = Map.get(people, id)
    new_person = %{person | reserve_days: reserve_days, weekday_reserve: weekdays}
    {:noreply, Map.put(people, id, new_person)}
  end

  def handle_cast({:update, id, new_data}, people) do
    {:noreply, Map.put(people, id, new_data)}
  end

  def handle_cast({:reset, default}, people) do
    {:noreply, Map.merge(people, default)}
  end
end
