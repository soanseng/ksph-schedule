defmodule Schedule.Repo.Migrations.CreateDay do
  use Ecto.Migration

  def change do
    create table(:day, primary_key: false) do
      add :date_id, :date, primary: true
      add :point, :integer
      add :is_friday, :boolean
      add :is_holiday, :boolean
      add :resident, :string
      add :attend, :string
      timestamps()
    end
  end
end
