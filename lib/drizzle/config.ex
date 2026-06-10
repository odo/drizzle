defmodule Drizzle.Config do

  def get() do
    %{
      records:             Application.get_env(:drizzle, :records),
      last_evaluation:     Application.get_env(:drizzle, :last_evaluation),
      evaluation_time_fun: Application.get_env(:drizzle, :evaluation_time_fun),
      wait_for_update:     Application.get_env(:drizzle, :wait_for_update, false)
    }
  end
end
