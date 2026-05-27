defmodule Drizzle.Config do

  def get() do
    %{
      records:             Application.get_env(:drizzle, :records),
      update_interval:     Application.get_env(:drizzle, :update_interval),
      last_evaluation:     Application.get_env(:drizzle, :last_evaluation),
      evaluation_time_fun: Application.get_env(:drizzle, :evaluation_time_fun)
    }
  end
end
