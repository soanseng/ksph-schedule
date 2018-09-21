defmodule Schedule.Application do
  use Application

  def start(_type, _arges) do
    children = [
      %{
        id: MonthServer,
        start: {Schedule.MonthServer, :start_link, []}
      },
      %{
        id: PeopleServer,
        start: {Schedule.PeopleServer, :start_link, []}
      }
    ]

    options = [
      name: Schedule.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end