defmodule Schedule.Repo.Migrations.CreatePerson do
  use Ecto.Migration

  def change do
    create table(:people, primary_key: false) do
      add :name, :string
      add :level, :integer
      add :ranking, :integer
      add :doctor_id, :id, primary: true
      add :is_attending, :boolean
      add :weekday_wish, {:array, :integer}
      timestamps()
    end
  end
end
