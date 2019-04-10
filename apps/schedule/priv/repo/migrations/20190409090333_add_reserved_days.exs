defmodule Schedule.Repo.Migrations.AddReservedDays do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :reserve_days, {:array, :date}
    end
  end
end
