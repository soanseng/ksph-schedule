defmodule Schedule.Recordings do
  import Ecto.Query, warn: false
  alias Schedule.Person
  alias Schedule.Repo

  def change_person(%Person{} = person) do
    Person.person_changeset(person, %{})
  end


  def update_person(%Person{} = person, attrs) do
    person
    |> Person.person_changeset(attrs)
    |> Repo.update()
  end
end
