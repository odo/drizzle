defmodule Drizzle do
  @moduledoc """
  A server for second-granularity execution of jobs from a cron tab
  """
  use GenServer

  require Logger

  alias Drizzle.{Config, Parser, Time}

  @execute_fun_every 30

  defmodule Record do
    defstruct crontab: nil, time_zone: nil, module: nil, function: nil, args: nil
  end

  defstruct records: [], last_evaluation: nil, evaluation_time_fun: nil

  # Server functions
  @spec start_link([]) :: {:ok, pid()}
  def start_link([]) do
    Config.get() |> start_link()
  end

  # Initialization
  def start_link(%{
    records:             records,
    last_evaluation:     last_evaluation,
    evaluation_time_fun: evaluation_time_fun}) when is_list(records) do
    GenServer.start_link(__MODULE__, [records, last_evaluation, evaluation_time_fun], [name: __MODULE__])
  end
  def start_link(_), do: {:error, :invalid_config}

  def init([records, last_evaluation, evaluation_time_fun]) do
    # we are setting the last time to one second in the past
    # so we start with the current second
    initial_state = %Drizzle{
      records:             Parser.parse_records!(records),
      last_evaluation:     last_evaluation || (Time.now() |> elem(0)) - 1,
      evaluation_time_fun: evaluation_time_fun || fn(_) -> :noop end
    }
    schedule_evaluation(0)
    {:ok, initial_state}
  end

  # API
  def update(records) when is_list(records) do
    GenServer.cast(__MODULE__, {:update_records, records})
  end

  # Callbacks
  def handle_cast({:update_records, records}, state) do
    case Parser.parse_records(records) do
      {:ok, records} ->
        next_state = %{state | records: records}
        {:noreply, next_state}
      {:error, _} ->
        {:noreply, state}
      end
  end

  def handle_info(:evaluate, state = %Drizzle{last_evaluation: last_evaluation}) do
    {now, microseconds} = Time.now()
    schedule_evaluation((1_000_000 - microseconds) / 1_000)
    case {last_evaluation, now} do 
      {same, same} ->
        # we are still in the same second, so nothing to do
        {:noreply, state}
      {last, now} when last > now ->
        # for some reason the last evaluation is in the future
        # we reset it to now
        Logger.error("last evaluation is #{last - now}s in the future - resetting.")
        {:noreply, %Drizzle{state | last_evaluation: now}}
      {last, now} ->
        evaluate(last, now, state)
        {:noreply, %Drizzle{state | last_evaluation: now}}
    end
  end

  # Internal
  defp evaluate(last, now, %Drizzle{records: records, evaluation_time_fun: evaluation_time_fun}) do
    # we start with the first second after the one we already evaluated
    executed = last+1..now |> execute_for_interval(records)
    # maybe we want to persist the time stamp
    if (Enum.any?(executed) or (rem(now, @execute_fun_every) == 0)) do
      spawn(fn() -> evaluation_time_fun.(now) end)
    end
  end

  defp schedule_evaluation(delay) do
    Process.send_after(self(), :evaluate, trunc(delay))
  end

  defp execute_for_interval(times, records) do
    for time <- times, record = %Record{crontab: crontab, time_zone: time_zone} <- records do
      if Cron.match?(crontab, Time.from_seconds(time, time_zone)), do: execute(record)
    end
  end

  defp execute(%Record{module: module, function: function, args: args}) do
    spawn(fn() -> apply(module, function, args) end)
  end

end
