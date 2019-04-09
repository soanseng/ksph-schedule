defmodule Schedule.Month do
  alias Schedule.Day
  use Timex

  @doc """
  ## generate this month's data
  - start_day: is the begining of the month
  - holidays: you can set ordiary day to holidays;
  - turn_ordinay: you also can set sat or sunday to ordinary day.
  - remove_days: some contineuos holidays should be removed due to hand-made decision
  """
  def generate_month(start_day, holidays \\ [], be_ordinary \\ [], should_be_removed \\ []) do
    Interval.new(from: start_day, until: [months: 1])
    |> Stream.map(fn date -> {Timex.to_date(date), %Day{date_id: Timex.to_date(date)}} end)
    |> Stream.filter(fn {date, _day} -> !Enum.member?(should_be_removed, date) end)
    |> Stream.map(fn {date, day} -> {date, change_points({date, day})} end)
    |> Stream.map(fn {date, day} -> {date, set_holidays({date, day}, holidays)} end)
    |> Stream.map(fn {date, day} -> {date, turn_ordinary({date, day}, be_ordinary)} end)
    |> Map.new()
  end

  def generate_continuous_reserve(start_day, end_day) do
    Interval.new(from: start_day, until: end_day, right_open: false)
    |> Interval.with_step(days: 1)
    |> Stream.map(fn date -> Timex.to_date(date) end)
    |> Enum.to_list()
  end

  def generate_reserve_list(year, month, day_list) do
    Enum.map(day_list, fn number ->
      Timex.parse!("#{year}-#{month}-#{number}", "{YYYY}-{M}-{D}") |> Timex.to_date()
    end)
  end


  defp change_points({date, day}) do
    case Timex.weekday(date) do
      5 -> %{day | is_friday: true}
      6 -> %{day | is_holiday: true, point: 2}
      7 -> %{day | is_holiday: true, point: 2}
      _ -> day
    end
  end

  defp set_holidays({date, day}, holidays) do
    if Enum.member?(holidays, date) do
      %{day | is_holiday: true, point: 2}
    else
      day
    end
  end

  defp turn_ordinary({date, day}, turn_days) do
    if Enum.member?(turn_days, date) do
      %{day | is_holiday: false, point: 1}
    else
      day
    end
  end
end
