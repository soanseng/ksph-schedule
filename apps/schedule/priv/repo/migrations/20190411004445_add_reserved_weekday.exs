defmodule Schedule.Repo.Migrations.AddReservedWeekday do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :weekday_reserve, {:array, :integer}
    end
  end
end
