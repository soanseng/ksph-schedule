defmodule Schedule.Calculate do
  alias Schedule.MonthServer
  alias Schedule.ResidentServer
  alias Schedule.AttendingServer
  alias Schedule.Repo
  use Timex


  # calculate residents
  def resident_result(_month, _people, 0) do
    {:error, "there is no result"}
  end

  def resident_result(default_month, default_resident, n) do
    if MonthServer.get_current_month() |> filter_no_resident_day() > 0 do
      ResidentServer.reset_residents(default_resident)
      MonthServer.reset_month(default_month)
      set_the_holiday(n, :resident)
      set_the_ordinary(n, :resident)
      resident_result(default_month, default_resident, n - 1)
    else
      {:ok, MonthServer.get_current_month()}
    end
  end

  # calculate attending
  def attending_result(_month, _attending, 0) do
    {:error, "there is no result"}
  end

  def attending_result(default_month, default_attending, n) do
    if MonthServer.get_current_month() |> filter_no_attending_day() > 0 do
      AttendingServer.reset_attendings(default_attending)
      MonthServer.reset_month(default_month)
      set_specific_day()
      attending_wish_day(n, :holiday)
      attending_random_holiday(n)
      attending_wish_day(n, :normal)
      attending_random_ordinary(n)
      attending_result(default_month, default_attending, n - 1)
    else
      {:ok, MonthServer.get_current_month()}
    end
  end

  def attending_random_holiday(0) do
    IO.puts("no result!")
  end

  def attending_random_holiday(n) do
    MonthServer.get_current_month()
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
    MonthServer.get_current_month()
    |> filter_ordinary_days()
    |> Stream.filter(fn {_date, day_value} -> day_value.attending_id == 0 end)
    |> Enum.each(fn date ->
      seize_the_day(n, date, :attending)
    end)
  end

  def attending_wish_day(n, :holiday) do
    filter_days =
      MonthServer.get_current_month()
      |> filter_holidays()
      |> Enum.map(fn keyword -> elem(keyword, 0) end)

    AttendingServer.get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, person_info} ->
      Enum.any?(person_info.weekday_wish, fn weekday -> weekday == 6 || weekday == 7 end) &&
        person_info.current_point == 0
    end)
    |> Flow.each(fn attending -> loop_to_pick_wish_days(n, attending, filter_days, :holiday) end)
  end

  def attending_wish_day(n, :normal) do
    filter_days =
      MonthServer.get_current_month()
      |> filter_ordinary_days()
      |> Enum.map(fn keyword -> elem(keyword, 0) end)

    AttendingServer.get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, person_info} ->
      Enum.any?(person_info.weekday_wish, fn weekday -> !(weekday == 6 || weekday == 7) end) &&
        person_info.current_point == 0
    end)
    |> Flow.each(fn attending -> loop_to_pick_wish_days(n, attending, filter_days, :normal) end)
  end

  def set_specific_day() do
    AttendingServer.get_current_attendings()
    |> Flow.from_enumerable()
    |> Flow.filter(fn {_pick_id, value} -> value.duty_wish != [] end)
    |> Flow.each(fn {pick_id, person_info} ->
      Flow.each(person_info.duty_wish, fn date ->
        if Map.get(MonthServer.get_current_month(), date).is_holiday do
          AttendingServer.update_attending(pick_id, %{
            person_info
            | current_point: person_info.current_point + 2,
              duty_days: [date | person_info.duty_days]
          })
        else
          AttendingServer.update_attending(pick_id, %{
            person_info
            | current_point: person_info.current_point + 1,
              duty_days: [date | person_info.duty_days]
          })
        end

        new_days = %{
          Map.get(MonthServer.get_current_month(), date)
          | attend: person_info.name,
            attending_id: person_info.doctor_id
        }

        MonthServer.update_month(date, new_days)
      end)
    end)
  end

  def set_the_holiday(n, identity) do
    MonthServer.get_current_month()
    |> filter_holidays
    |> Enum.each(fn date ->
      seize_holiday(n, date, identity)
    end)
  end

  def set_the_ordinary(n, identity) do
    MonthServer.get_current_month()
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
      AttendingServer.get_current_attendings()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 2
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | attending_id: pick_id, attend: person_info.name}

      AttendingServer.update_attending(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days
      })

      MonthServer.update_month(elem(date, 0), new_days)
    else
      seize_holiday(n - 1, date, :attending)
    end
  end

  defp seize_holiday(n, date, :resident) do
    {pick_id, person_info} =
      ResidentServer.get_current_residents()
      |> Enum.random()

    if can_be_reserved?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 2
      add_holiday = person_info.holidays_count + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | resident_id: pick_id, resident: person_info.name}

      ResidentServer.update_resident(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days,
          holidays_count: add_holiday
      })

      MonthServer.update_month(elem(date, 0), new_days)
    else
      seize_holiday(n - 1, date, :resident)
    end
  end

  defp seize_the_day(0, _date, _identity) do
    {:error, "it does not work"}
  end

  defp seize_the_day(n, date, :resident) do
    {pick_id, person_info} =
      ResidentServer.get_current_residents()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | resident_id: pick_id, resident: person_info.name}
      ResidentServer.update_resident(pick_id, %{person_info | current_point: new_point, duty_days: duty_days})
      MonthServer.update_month(elem(date, 0), new_days)
    else
      seize_the_day(n - 1, date, :resident)
    end
  end

  defp seize_the_day(n, date, :attending) do
    {pick_id, person_info} =
      AttendingServer.get_current_attendings()
      |> Enum.random()

    if can_be_reserved_ordinary?(person_info, elem(date, 0)) do
      new_point = person_info.current_point + 1
      duty_days = [elem(date, 0) | person_info.duty_days]
      new_days = %{elem(date, 1) | attending_id: pick_id, attend: person_info.name}

      AttendingServer.update_attending(pick_id, %{
        person_info
        | current_point: new_point,
          duty_days: duty_days
      })

      MonthServer.update_month(elem(date, 0), new_days)
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
    person.current_point + MonthServer.get_specific_date(date).point > person.max_point
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
         Map.fetch!(MonthServer.get_current_month(), pick_day).attending_id == 0 &&
         !Enum.member?(person_info.reserve_days, pick_day) &&
         !exceed_maximum?(person_info, pick_day) do
      if holiday? == :holiday do
        AttendingServer.update_attending(pick_id, %{
          person_info
          | current_point: person_info.current_point + 2,
            duty_days: [pick_day | person_info.duty_days]
        })
      else
        AttendingServer.update_attending(pick_id, %{
          person_info
          | current_point: person_info.current_point + 1,
            duty_days: [pick_day | person_info.duty_days]
        })
      end

      new_days = %{
        Map.get(MonthServer.get_current_month(), pick_day)
        | attend: person_info.name,
          attending_id: person_info.doctor_id
      }

      MonthServer.update_month(pick_day, new_days)
    else
      loop_to_pick_wish_days(n - 1, attending, filter_days, holiday?)
    end
  end

  # turn into Json
  def result_to_json do
    MonthServer.get_current_month() |> Map.values() |> Poison.encode!()
  end

  def resident_to_json do
    ResidentServer.get_current_residents() |> Map.values() |> Poison.encode!()
  end

  def attending_to_json do
    AttendingServer.get_current_attendings() |> Map.values() |> Poison.encode!()
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
