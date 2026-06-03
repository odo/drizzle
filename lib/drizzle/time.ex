defmodule Drizzle.Time do
  @moduledoc """
  This module deals with time
  """

  def now() do
    DateTime.utc_now()
    |> DateTime.to_gregorian_seconds() 
  end

  def from_seconds(seconds, time_zone) when is_integer(seconds) and is_binary(time_zone) do
    seconds
    |> DateTime.from_gregorian_seconds()
    |> DateTime.shift_zone!(time_zone)
    |> DateTime.to_naive()
  end
end
