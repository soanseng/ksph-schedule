defmodule Schedule.Person do
  use Timex
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:doctor_id, :id, autogenerate: false}
  @derive {Poison.Encoder, only: [:name, :duty_days]}
  schema "people" do
    field(:current_point, :integer, virtual: true, default: 0)
    field(:holidays_count, :integer, virtual: true, default: 0)
    field(:reserve_days, {:array, :date}, virtual: true, default: [])
    field(:weekday_reserve, {:array, :date}, virtual: true, default: [])
    field(:weekday_wish, {:array, :integer}, default: [])
    field(:duty_wish, {:array, :date}, virtual: true, default: [])
    field(:name, :string)
    field(:duty_days, {:array, :date}, virtual: true, default: [])
    field(:max_point, :integer, default: 8, virtual: true)
    field(:max_holiday, :integer, default: 0, virtual: true)
    field(:level, :integer)
    field(:ranking, :integer)
    field(:is_attending, :boolean, default: false)

    timestamps()
  end

  def person_changeset(person, params \\ %{}) do
    person
    |> cast(params, [
      :name,
      :level,
      :ranking,
      :doctor_id,
      :holidays_count,
      :max_holiday,
      :max_point,
      :reserve_days,
      :weekday_wish,
      :weekday_reserve,
      :duty_days,
      :current_point,
      :holidays_count,
      :is_attending
    ])
    |> validate_required([:name, :doctor_id, :is_attending])
  end

  def convert_weekday_to_day(person, start_day) do
    pick =
      Interval.new(from: start_day, until: [months: 1])
      |> Stream.filter(fn day ->
        Enum.member?(person.weekday_reserve, Timex.weekday(day))
      end)
      |> Enum.map(fn day -> Timex.to_date(day) end)

    %{person | reserve_days: person.reserve_days |> Stream.concat(pick) |> Enum.uniq()}
  end

  def setting_point(total_points, max_point) do
    sum = total_points - max_point

    if sum > 0 do
      "everyone on should add more points: #{sum}"
    else
      "everyone should reduce points: #{sum}"
    end
  end

  def r1(person), do: %{person | max_point: 7}
  def r2(person), do: %{person | max_point: 6}
  def r3(person), do: %{person | max_point: 5}
  def r4(person), do: %{person | max_point: 4}
end
