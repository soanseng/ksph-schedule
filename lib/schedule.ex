defmodule Schedule do
  use Application

  def start(_type, _arges) do
    children = [
      Schedule.Repo,
      %{
        id: MonthServer,
        start: {Schedule.MonthServer, :start_link, []}
      },
      %{
        id: ResidentServer,
        start: {Schedule.ResidentServer, :start_link, []}
      },
      %{
        id: AttendingServer,
        start: {Schedule.AttendingServer, :start_link, []}
      }
    ]

    options = [
      name: Schedule.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end
