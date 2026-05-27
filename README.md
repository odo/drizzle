# Drizzle

Drizzle is a Elixir application to schedule repeated tasks.

## Characteristics

* Cron notation
* Seconds resolution
* Time zone support per job
* Jobs can be updated during runtime
* Fast-forward of time spend offline due to restarts

## Configuration

This basic example tells Drizzle to output "hello" every second: 
```elixir
config :drizzle,
      records: [%{
        crontab: "* * * * * *",
        time_zone: :utc,
        module: IO,
        function: :puts,
        args: ["hello"]
      }]
```

Each record consist of different fields:
- `crontab`: defines when a job is run (details [here](https://hex.pm/packages/cron))
- `timezone`: either `:utc` or a time zone like "Europe/Berlin"
- `module`, `function`, `args`: what will be called when the matching time has come

Here is a more involved example:

```elixir
config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :drizzle,
      records: [%{
        crontab: "0 20 * * Sat",
        time_zone: "Australia/Adelaide",
        module: IO,
        function: :puts,
        args: ["cheers from down under"]
      }],
      update_interval: 5_000,
      last_evaluation: (case File.read("/tmp/drizzle_time") do {:error, _} -> nil; {:ok, time} -> String.to_integer(time) end),
      evaluation_time_fun: fn(time) -> File.write!("/tmp/drizzle_time", inspect(time)) end
```

Here we are greeting every Saturday at 8pm Australian Central Standard Time.
Please note that you need to configure a time zone DB to do this.

These keys are optional:
- `update_interval` [ms]: how often Drizzle checks the clock (larger numbers are less precise, small numbers are wasteful)
- `last_evaluation`: the last known output of `evaluation_time_fun` (see below)
- `evaluation_time_fun`: a function to store the time stamp of the last evaluation (see below)

Drizzle counts time in Gregorian seconds (as in `DateTime.utc_now |> DateTime.to_gregorian_seconds |> elem(0)`). The problem is that when the application is stopped for restarts or upgrades, some seconds might not be observed. If you use `evaluation_time_fun` to capture and store this time, you can later pass it to `last_evaluation` so Drizzle can catch up and potentially trigger jobs that where scheduled while it was out.

`evaluation_time_fun` will be called whenever a job is executed and every 30 seconds.

## Updating cron tab
You can update the cron tab at runtime:
`Drizzle.update([%{ crontab: "* * * * * *", time_zone: :utc, module: IO, function: :puts, args: ["olleh"] }])`

## Performance
Drizzle evaluates the cron tab for each second.
On a modern machine evaluating one year (31536000 seconds) for one cron tab line takes about 30 CPU seconds.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `drizzle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:drizzle, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/drizzle>.

