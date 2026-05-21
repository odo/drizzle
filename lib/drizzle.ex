defmodule Drizzle do
  @moduledoc """
  A server for second-granularity execution
  of jobs from several crontabs
  """
  use GenServer

  defmodule Record do
    defstruct crontab: nil, module: nil, function: nil, args: nil
  end

  defstruct records: [], last_evaluation: nil, update_interval: nil 

  # Initialization
  def start_link(records, update_interval \\ 500) do
    GenServer.start_link(__MODULE__, [records, update_interval], [name: __MODULE__])
  end

  def init([records, update_interval]) do
    # we are setting the last time to one second in the past
    # so we start with the current second
    initial_state = %Drizzle{
      records: parse_records(records),
      last_evaluation: now() - 1,
      update_interval: update_interval
    }
    schedule_evaluation(0)
    {:ok, initial_state}
  end

  # API
  def update(records) do
    GenServer.cast(__MODULE__, {:update_records, records})
  end

  # Callbacks
  def handle_cast({:update_records, records}, state) do
    next_state = %{state | records: parse_records(records)}
    {:noreply, next_state}
  end

  def handle_info(:evaluate, state = %Drizzle{records: records, last_evaluation: last_evaluation, update_interval: update_interval}) do
    schedule_evaluation(update_interval)
    case {last_evaluation, now()} do 
      {same, same} ->
        {:noreply, state}
      {last, now} ->
        times = last+1..now |> Enum.map(fn(second) -> time(second) end)
        execute_for_interval(records, times)
        {:noreply, %Drizzle{state | last_evaluation: now}}
    end
  end
 
  # Internal
  defp schedule_evaluation(delay) do
    Process.send_after(self(), :evaluate, delay)
  end

  defp execute_for_interval(records, times) do
    for time <- times, record = %Record{crontab: crontab} <- records do
      if Cron.match?(crontab, time), do: execute(record)
    end
  end

  defp execute(%Record{module: module, function: function, args: args}) do
    spawn(fn() -> apply(module, function, args) end)
  end

  defp parse_records(records) do
    records |> Enum.map(&parse_record(&1))
  end

  defp parse_record(%{crontab: crontab, module: module, function: function, args: args})
    when is_binary(crontab) and is_atom(module) and is_atom(module) and is_list(args) do
    %Record{
      crontab: Cron.new!(crontab),
      module: module,
      function: function,
      args: args
    }
  end

  defp now() do
    DateTime.utc_now() |> DateTime.to_gregorian_seconds() |> elem(0)
  end

  defp time(second) do
    DateTime.from_gregorian_seconds(second)
  end

end
