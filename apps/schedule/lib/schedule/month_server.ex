defmodule Schedule.MonthServer do
  use GenServer
  alias Schedule.Month
  alias Schedule.Repo

  #api
  def set_this_month(date, holidays \\ [], be_ordinary \\ [], should_be_removed \\ []) do
    GenServer.call(__MODULE__, {:set_start, date, holidays, be_ordinary, should_be_removed})
  end

  def reset_month(default) do
    GenServer.cast(__MODULE__, {:reset, default})
  end

  def get_current_month() do
    GenServer.call(__MODULE__, {:get})
  end

  def update_month(date, new_data) do
    GenServer.cast(__MODULE__, {:update, date, new_data})
  end

  def get_specific_date(date) do
    GenServer.call(__MODULE__, {:get_day, date})
  end

  def save_to_database() do
    get_current_month()
    |> Map.values()
    |> Enum.each(fn day -> Repo.insert!(day) end)
  end


  def all_points() do
    get_current_month() |> Enum.reduce(0, fn {_day, value}, acc -> value.point + acc end)
  end

  # callback
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:set_start, date, holidays, be_ordinary, should_be_removed}, _from, _months) do
    months = Month.generate_month(date, holidays, be_ordinary, should_be_removed)
    {:reply, months, months}
  end

  def handle_call({:get}, _from, months) do
    {:reply, months, months}
  end

  def handle_call({:get_day, date}, _from, months) do
    {:reply, Map.get(months, date), months}
  end

  def handle_cast({:update, date, new_data}, month) do
    {:noreply, Map.put(month, date, new_data)}
  end

  def handle_cast({:reset, default}, month) do
    {:noreply, Map.merge(month, default)}
  end
end
