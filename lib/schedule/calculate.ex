defmodule Schedule.Calculate do
  alias Schedule.MonthServer
  alias Schedule.ResidentServer
  alias Schedule.AttendingServer
  alias Schedule.Repo
  use Timex

  # month setup
  def set_this_month(date, holidays \\ [], be_ordinary \\ [], should_be_removed \\ []) do
    GenServer.call(MonthServer, {:set_start, date, holidays, be_ordinary, should_be_removed})
  end

  def reset_month(default) do
    GenServer.cast(MonthServer, {:reset, default})
  end

  def get_current_month() do
    GenServer.call(MonthServer, {:get})
  end

  def update_month(date, new_data) do
    GenServer.cast(MonthServer, {:update, date, new_data})
  end

  def get_specific_date(date) do
    GenServer.call(MonthServer, {:get_day, date})
  end

  def save_to_database() do
    get_current_month()
    |> Map.values()
    |> Enum.each(fn day -> Repo.insert!(day) end)
  end

  # resident setup

  def get_residents_from_db(min_level, eda \\ 999) do
    GenServer.cast(ResidentServer, {:get_residents_db, min_level, eda})
  end

  def get_current_residents() do
    GenServer.call(ResidentServer, {:get})
  end

  def reset_residents(default) do
    GenServer.cast(ResidentServer, {:reset, default})
  end

  def set_holiday_points(id, max_point, max_holiday) do
    GenServer.cast(ResidentServer, {:set_holiday_points, id, max_point, max_holiday})
  end

  def set_reserve(id, weekdays \\ [], reserve_days \\ []) do
    GenServer.cast(ResidentServer, {:set_reserve, id, weekdays, reserve_days})
  end

  def update_resident(id, new_data) do
    GenServer.cast(ResidentServer, {:update, id, new_data})
  end

  # attending setup

  def get_attendings_from_db(min_sheng_id \\ 0) do
    GenServer.cast(AttendingServer, {:get_attending_db, min_sheng_id})
  end

  def get_current_attendings() do
    GenServer.call(AttendingServer, {:get_attending})
  end

  def attending_reserve(
        id,
        weekdays_reserve \\ [],
        reserve_days \\ [],
        duty_wish \\ [],
        weekday_wish \\ []
      ) do
    GenServer.cast(
      AttendingServer,
      {:attending_reserve, id, weekdays_reserve, reserve_days, duty_wish, weekday_wish}
    )
  end

  def reset_attendings(default) do
    GenServer.cast(AttendingServer, {:reset, default})
  end

  def update_attending(id, new_data) do
    GenServer.cast(AttendingServer, {:update, id, new_data})
  end

  def remove_attendings(list_ids) do
    GenServer.cast(AttendingServer, {:remove, list_ids})
  end

  def set_max_points(this_month) do
    GenServer.cast(AttendingServer, {:set_max_points, this_month})
  end

  # calculate residents
  def resident_result(_month, _people, 0) do
    {:error, "there is no result"}
  end

  def resident_result(default_month, default_resident, n) do
    if get_current_month() |> filter_no_resident_day() > 0 do
      reset_residents(default_resident)
      reset_month(default_month)
      set_the_holiday(n, :resident)
      set_the_ordinary(n, :resident)
      resident_result(default_month, default_resident, n - 1)
    else
      {:ok, get_current_month()}
    end
  end

  # calculate attending
  def attending_result(_month, _attending, 0) do
    {:error, "there is no result"}
  end

  def attending_result(default_month, default_attending, n) do
    if get_current_month() |> filter_no_attending_day() > 0 do
      reset_attendings(default_attending)
      reset_month(default_month)
      set_specific_day()
      attending_wish_day(n, :holiday)
      attending_random_holiday(n)
      attending_wish_day(n, :normal)
      attending_random_ordinary(n)
      attending_result(default_month, default_attending, n - 1)
    else
      {:ok, get_current_month()}
    end
  end

  def attending_random_holiday(0) do
    IO.puts("no result!")
  end

  def attending_random_holiday(n) do
    get_current_month()
    |> filter_holidays()
    |> Flow.filter(fn {_date, day_value} -> day_value.attending_id == 0 end)
    |> Enum.each(fn date ->
      seize_holiday(n, date, :attending)
    end)
  end

  def attending_random_ordinary(0) do
    IO.puts("no result!")
  end

  def attending_random_ordinary(n) do
    get_current_month()
    |> filter_ordinary_days()
    |> Stream.filter(fn {_date, day_value} -> day_value.attending_id == 0 end)
    |> Enum.each(fn date ->
      seize_the_day(n, date, :attending)
    end)
  end

  def attending_wish_day(n, :holiday) do
    filter_days =
      get_current_month()
      |> filter_holidays()
      |> Enum.map(fn keyword -> elem(keyword, 0) end)

    get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, person_info} ->
      Enum.any?(person_info.weekday_wish, fn weekday -> weekday == 6 || weekday == 7 end) &&
        person_info.current_point == 0
    end)
    |> Flow.each(fn attending -> loop_to_pick_wish_days(n, attending, filter_days, :holiday) end)
  end

  def attending_wish_day(n, :normal) do
    filter_days =
      get_current_month()
      |> filter_ordinary_days()
      |> Enum.map(fn keyword -> elem(keyword, 0) end)

    get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, person_info} ->
      Enum.any?(person_info.weekday_wish, fn weekday -> !(weekday == 6 || weekday == 7) end) &&
        person_info.current_point == 0
    end)
    |> Flow.each(fn attending -> loop_to_pick_wish_days(n, attending, filter_days, :normal) end)
  end

  def set_specific_day() do
    get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, value} -> value.duty_wish != [] end)
    |> Flow.each(fn {pick_id, person_info} ->
      Flow.each(person_info.duty_wish, fn date ->
        if Map.get(get_current_month(), date).is_holiday do
          update_attending(pick_id, %{
            person_info
            | current_point: person_info.current_point + 2,
              duty_days: [date | person_info.duty_days]
          })
        else
          update_attending(pick_id, %{
            person_info
            | current_point: person_info.current_point + 1,
              duty_days: [date | person_info.duty_days]
          })
        end

        new_days = %{
          Map.get(get_current_month(), date)
          | attend: person_info.name,
            attending_id: person_info.doctor_id
        }

        update_month(date, new_days)
      end)
    end)
  end

  def set_the_holiday(n, identity) do
    get_current_month()
    |> filter_holidays
    |> Enum.each(fn date ->
      seize_holiday(n, date, identity)
    end)
  end

  def set_the_ordinary(n, identity) do
    get_current_month()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_date, value} -> !value.is_holiday end)
    |> Enum.each(fn date -> seize_the_day(n, date, identity) end)
  end

  # private methods

  defp seize_holiday(0, _date, _identity) do
    {:error, "it does not work"}
  end

  defp seize_holiday(n, date, :attending) do
    {pick_id, person_info} =
      get_current_attendings()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 2
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | attending_id: pick_id, attend: person_info.name}

      update_attending(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days
      })

      update_month(elem(date, 0), new_days)
    else
      seize_holiday(n - 1, date, :attending)
    end
  end

  defp seize_holiday(n, date, :resident) do
    {pick_id, person_info} =
      get_current_residents()
      |> Enum.random()

    if can_be_reserved?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 2
      add_holiday = person_info.holidays_count + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | resident_id: pick_id, resident: person_info.name}

      update_resident(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days,
          holidays_count: add_holiday
      })

      update_month(elem(date, 0), new_days)
    else
      seize_holiday(n - 1, date, :resident)
    end
  end

  defp seize_the_day(0, _date, _identity) do
    {:error, "it does not work"}
  end

  defp seize_the_day(n, date, :resident) do
    {pick_id, person_info} =
      get_current_residents()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | resident_id: pick_id, resident: person_info.name}
      update_resident(pick_id, %{person_info | current_point: new_point, duty_days: duty_days})
      update_month(elem(date, 0), new_days)
    else
      seize_the_day(n - 1, date, :resident)
    end
  end

  defp seize_the_day(n, date, :attending) do
    {pick_id, person_info} =
      get_current_attendings()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | attending_id: pick_id, attend: person_info.name}

      update_attending(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days
      })

      update_month(elem(date, 0), new_days)
    else
      seize_the_day(n - 1, date, :attending)
    end
  end

  defp can_be_reserved?(person, date) do
    if Enum.member?(person.reserve_days, date) ||
         Enum.member?(person.weekday_reserve, Timex.weekday(date)) ||
         less_than_two?(person.duty_days, date) || exceed_maximum?(person, date) ||
         break_holiday_policy?(person) do
      false
    else
      true
    end
  end

  defp can_be_reserved_ordinary?(person, date) do
    if Enum.member?(person.reserve_days, date) ||
         Enum.member?(person.weekday_reserve, Timex.weekday(date)) ||
         less_than_two?(person.duty_days, date) || exceed_maximum?(person, date) do
      false
    else
      true
    end
  end

  defp less_than_two?(days_list, date) do
    Enum.reduce(days_list, false, fn duty_day, acc ->
      days_interval =
        Interval.new(from: date, until: duty_day)
        |> Interval.duration(:days)
        |> abs

      days_interval <= 3 || acc
    end)
  end

  defp exceed_maximum?(person, date) do
    person.current_point + get_specific_date(date).point > person.max_point
  end

  # resident holiday special function
  defp break_holiday_policy?(person) do
    person.max_holiday == person.holidays_count
  end

  # return keyword list
  defp filter_holidays(month) do
    month
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_date, value} -> value.is_holiday end)
  end

  defp filter_ordinary_days(month) do
    Enum.filter(month, fn {_date, value} -> !value.is_holiday end)
  end

  defp filter_no_resident_day(month) do
    month
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_date, value} -> value.resident_id == 0 end)
    |> Enum.count()
  end

  defp filter_no_attending_day(month) do
    Stream.filter(month, fn {_date, value} -> value.attending_id == 0 end)
    |> Enum.count()
  end

  defp loop_to_pick_wish_days(0, _attending, _filter_days, _holiday?) do
    IO.puts("No result")
  end

  defp loop_to_pick_wish_days(n, attending, filter_days, holiday?) do
    {pick_id, person_info} = attending
    pick_day = Enum.random(filter_days)

    if Enum.member?(person_info.weekday_wish, Timex.weekday(pick_day)) &&
         Map.fetch!(get_current_month(), pick_day).attending_id == 0 &&
         !Enum.member?(person_info.reserve_days, pick_day) &&
         !exceed_maximum?(person_info, pick_day) do
      if holiday? == :holiday do
        update_attending(pick_id, %{
          person_info
          | current_point: person_info.current_point + 2,
            duty_days: [pick_day | person_info.duty_days]
        })
      else
        update_attending(pick_id, %{
          person_info
          | current_point: person_info.current_point + 1,
            duty_days: [pick_day | person_info.duty_days]
        })
      end

      new_days = %{
        Map.get(get_current_month(), pick_day)
        | attend: person_info.name,
          attending_id: person_info.doctor_id
      }

      update_month(pick_day, new_days)
    else
      loop_to_pick_wish_days(n - 1, attending, filter_days, holiday?)
    end
  end

  # turn into Json
  def result_to_json do
    get_current_month() |> Map.values() |> Poison.encode!()
  end

  def resident_to_json do
    get_current_residents() |> Map.values() |> Poison.encode!()
  end

  def attending_to_json do
    get_current_attendings() |> Map.values() |> Poison.encode!()
  end

  # turn into csv
  def month_to_csv(month) do
    File.write!(
      "result.csv",
      month
      |> Map.values()
      |> Stream.map(&Map.take(&1, [:date_id, :attend, :resident]))
      |> Stream.map(&Map.put(&1, :date_id, Date.to_string(&1.date_id)))
      |> Stream.map(&(Map.values(&1) |> Enum.join(", ")))
      |> Enum.join("\n ")
    )
  end

  def staff_to_csv(staff, name) do
    File.write(
      "#{name}.csv",
      staff
      |> Map.values()
      |> Stream.map(&Map.take(&1, [:name, :duty_days]))
      |> Stream.map(
        &Map.put(&1, :duty_days, Enum.map(&1.duty_days, fn date -> Date.to_string(date) end))
      )
      |> Stream.map(fn person ->
        [Map.get(person, :name), Map.get(person, :duty_days)] |> List.flatten()
      end)
      |> Stream.map(&Enum.join(&1, ", "))
      |> Enum.join("\n ")
    )
  end
end
