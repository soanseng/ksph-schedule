defmodule Schedule.MonthServer do
  use GenServer
  alias Schedule.Month

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
