defmodule Drizzle.MixProject do
  use Mix.Project

  def project do
    [
      app: :drizzle,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cron, "~> 0.1"},
      {:tz, "~> 0.28"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
