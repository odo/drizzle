defmodule Drizzle.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Mix.env() do
        :test -> []
          _   -> [Drizzle]
      end
    Supervisor.start_link(
      children,
      [strategy: :one_for_one, name: Drizzle.Supervisor]
    )
  end
end
