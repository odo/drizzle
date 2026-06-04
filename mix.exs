defmodule Drizzle.MixProject do
  use Mix.Project

  def project do
    [
      app: :drizzle,
      version: "0.1.2",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Drizzle.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cron, "~> 0.1"},
      {:tz, "~> 0.28"},
      {:mock, "~> 0.3.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
  
  defp package() do
    [
     name: "drizzle",
     description: "Schedule tasks with seconds precision",
     links: %{"GitHub" => "https://github.com/odo/drizzle"},
     licenses: ["MIT"],
    ]
  end
end
