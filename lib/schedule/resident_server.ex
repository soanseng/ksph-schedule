defmodule Schedule.ResidentServer do
  use GenServer
  alias Schedule.Person
  alias Schedule.Repo
  import Ecto.Query

  #api call
  def get_residents_from_db(min_level, eda \\ 999) do
    GenServer.cast(__MODULE__, {:get_residents_db, min_level, eda})
  end

  def get_current_residents() do
    GenServer.call(__MODULE__, {:get})
  end

  def reset_residents(default) do
    GenServer.cast(__MODULE__, {:reset, default})
  end

  def set_holiday_points(id, max_point, max_holiday) do
    GenServer.cast(__MODULE__, {:set_holiday_points, id, max_point, max_holiday})
  end

  def set_reserve(id, weekdays \\ [], reserve_days \\ []) do
    GenServer.cast(__MODULE__, {:set_reserve, id, weekdays, reserve_days})
  end

  def update_resident(id, new_data) do
    GenServer.cast(__MODULE__, {:update, id, new_data})
  end


  def add_tempo(id, new_data) do
    GenServer.cast(__MODULE__, {:add_tempo, id, new_data})
  end

  def all_points do
    get_current_residents() |> Map.values |> Enum.reduce(0, fn person, acc ->
      person.current_point + acc
    end)
  end

  def all_max_points do
    get_current_residents() |> Map.values |> Enum.reduce(0, fn person, acc ->
      person.max_point + acc
    end)
  end




  # callback
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

  def handle_cast({:add_tempo, id, new_data}, people) do
    {:noreply, Map.put(people, id, new_data)}
  end
end
