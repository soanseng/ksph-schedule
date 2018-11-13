defmodule Schedule do
  use Application
  alias Schedule.{MonthServer, ResidentServer, AttendingServer, Repo}

  def start(_type, _arges) do
    children = [
      Repo,
      MonthServer,
      ResidentServer,
      AttendingServer
    ]

    options = [
      name: Schedule.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end
