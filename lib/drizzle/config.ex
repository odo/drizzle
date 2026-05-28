defmodule Drizzle.Config do

  def get() do
    %{
      records:             Application.get_env(:drizzle, :records),
      last_evaluation:     Application.get_env(:drizzle, :last_evaluation),
      evaluation_time_fun: Application.get_env(:drizzle, :evaluation_time_fun)
    }
  end
end
