defmodule Schedule.Repo do
  use Ecto.Repo, otp_app: :schedule,
    adapter: Ecto.Adapters.Postgres
end
