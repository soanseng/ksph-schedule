defmodule Schedule.Recordings do
  import Ecto.Query, warn: false
  alias Schedule.Person
  alias Schedule.Repo
  alias Schedule.Month

  def get_by_doctor_id(id) do
    Person
    |> Repo.get_by!(doctor_id: id)
  end

  def change_person(%Person{} = person) do
    Person.person_changeset(person, %{})
  end


  def update_person(%Person{} = person, attrs) do
    person
    |> Person.person_changeset(attrs)
    |> Repo.update()
  end

  def update_weekday(%Person{} = person, attrs) do
    weekday_list= attrs["weekday_reserve"]
    |> String.split(", ")
    |> Enum.map(&String.to_integer(&1))

    person
    |> Person.person_changeset(%{"weekday_reserve": weekday_list})
    |> Repo.update()

  end

  def update_reserve(%Person{} = person, attrs, month) do
    reserves= attrs["reserve_days"] |> String.split(", ")
    day_list = reserves |> parse_days

    reserve_days = Month.generate_reserve_list(2019, String.to_integer(month), day_list)

    person
    |> Person.person_changeset(%{"reserve_days": reserve_days})
    |> Repo.update()

  end

  def reset_all_reserve() do
    Repo.update_all(Person, set: [reserve_days: []])
  end

  defp parse_days(reserves) do
    Enum.map(reserves, fn word ->
      if String.contains?(word, "..") do

        tuple = String.split(word, "..")
        |> List.to_tuple

        Enum.to_list(String.to_integer(elem(tuple, 0))..String.to_integer(elem(tuple, 1)))
      else
       String.to_integer(word)
      end
    end)
    |> List.flatten
    |> Enum.uniq
  end
end
