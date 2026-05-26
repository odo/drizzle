defmodule Drizzle.Config do

  def get() do
    %{
      records: Application.get_env(:config_server, :records),
      update_interval: Application.get_env(:config_server, :update_interval),
      last_evaluation: Application.get_env(:config_server, :last_evaluation),
      evaluation_time_fun: Application.get_env(:config_server, :evaluation_time_fun)
    }
  end
end
