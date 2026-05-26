defmodule Drizzle.Time do

  def now() do
    DateTime.utc_now()
    |> to_seconds() 
  end

  def from_seconds(seconds, time_zone) when is_integer(seconds) and is_binary(time_zone) do
    seconds
    |> DateTime.from_gregorian_seconds()
    |> DateTime.shift_zone!(time_zone)
    |> DateTime.to_naive()
  end

  def to_seconds(%DateTime{} = time) do
    time
    |> DateTime.to_gregorian_seconds() |> elem(0)
  end
end
