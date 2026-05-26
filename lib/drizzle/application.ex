
defmodule ConfigServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [Drizzle]

    opts = [strategy: :one_for_one, name: Drizzle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
