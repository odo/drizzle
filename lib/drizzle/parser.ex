defmodule Drizzle.Parser do

  @validation_time NaiveDateTime.new!(1970, 1, 1, 0, 0, 0)
  require Logger

  alias Drizzle.Record

  def parse_records!(records) do
    {:ok, records} = parse_records(records)
    records
  end

  def parse_records(records) when is_list(records) do
    Enum.reduce_while(
      records,
      [],
      fn(e, acc) ->
        case parse_record(e) do
          {:ok, record} ->
            {:cont, [record | acc]}
          {:error, error} ->
            Logger.error("Records parsing failed #{inspect(error)}")
            {:halt, {:error, error}}
        end
      end
    )
    |> wrap_ok()
  end
  def parse_records(_), do: {:error, :no_records_provided}

  defp wrap_ok({:error, error}), do: {:error, error}
  defp wrap_ok(results), do: {:ok, results}

  defp parse_record(%{crontab: crontab, time_zone: :utc, module: module, function: function, args: args}) do
    parse_record(%{crontab: crontab, time_zone: "Etc/UTC", module: module, function: function, args: args})
  end
  defp parse_record(%{crontab: crontab, time_zone: time_zone, module: module, function: function, args: args})
    when is_binary(crontab) and is_binary(time_zone) and is_atom(module) and is_atom(module) and is_list(args) do
    with {:ok, _} <- DateTime.from_naive(@validation_time, time_zone),
        {:ok, crontab} <- Cron.new(crontab) do 
          {:ok,
            %Record{
              crontab: crontab,
              time_zone: time_zone,
              module: module,
              function: function,
              args: args
            }
          }
    else 
        :error -> {:error, :invalid_crontab}
        {:error, error} -> {:error, error} 
    end
  end
  defp parse_record(_), do: {:error, :invalid_record}
end
