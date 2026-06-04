defmodule DrizzleTest do
  use ExUnit.Case
  doctest Drizzle
  import Mock

  use ExUnit.Case, async: false

  describe "server" do
    test "starts" do
      assert {:ok, _pid} = Drizzle.start_link(%{
  
      records: [%{crontab: "* * * * * *", time_zone: "Europe/Berlin", module: Enum, function: :reverse, args: [[]]}],
      last_evaluation: nil,
      evaluation_time_fun: fn(_) -> :ok end
      })
    end

    test "starts with config" do
      config = 
        %{
          records: [%{crontab: "* * * * * *", time_zone: "Europe/Berlin", module: Enum, function: :reverse, args: [[]]}],
          last_evaluation: nil,
          evaluation_time_fun: nil
        }
      with_mock Drizzle.Config, [get: fn() -> config end] do
        assert {:ok, _pid} = Drizzle.start_link([])
      end
    end
    
    test "doesn't start without config" do
      assert {:error, :invalid_config} == Drizzle.start_link([])
    end
  end

  describe "triggering jobs" do

    test "initilzed with nil last_evaluation" do
      {:ok, init_state} = Drizzle.init([[], nil, nil])
      le = init_state.last_evaluation
      assert is_integer(le)
    end
    
    test "initilzed with integer last_evaluation" do
      {:ok, init_state} = Drizzle.init([[], 42, nil])
      assert 42 == init_state.last_evaluation
    end
    
    test "initilzed with fun last_evaluation" do
      {:ok, init_state} = Drizzle.init([[], fn() -> 13 end, nil])
      assert 13 == init_state.last_evaluation
    end

    test "triggering every second second" do
     record = %{
        crontab: "*/2 * * * * *",
        time_zone: :utc,
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }
      {:ok, init_state} = Drizzle.init([[record], 0, nil])
      assert_receive :evaluate
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {5, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, init_state)
        assert 5 == next_state.last_evaluation
        assert_receive :trigger
        assert_receive :trigger
        refute_receive :trigger
      end
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {10, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, %{init_state|last_evaluation: 5})
        assert 10 == next_state.last_evaluation
        assert_receive :trigger
        assert_receive :trigger
        assert_receive :trigger
        refute_receive :trigger
      end
    end
    
    test "triggering every day at 12:00" do
     record = %{
        crontab: "0 0 12 * * *",
        time_zone: :utc,
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }
      start = ~U[2026-05-26 11:59:59Z] |> to_seconds()
      now   = ~U[2026-05-26 12:00:00Z] |> to_seconds()

      {:ok, init_state} = Drizzle.init([[record], start, nil])
      assert_receive :evaluate
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {now, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, init_state)
        assert now == next_state.last_evaluation
        assert_receive :trigger
        refute_receive :trigger
      end
      next_now   = ~U[2026-05-26 12:10:00Z] |> to_seconds()
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {next_now, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, %{init_state|last_evaluation: now})
        assert next_now == next_state.last_evaluation
        refute_receive :trigger
      end
    end
  end
  
  describe "timezones" do

    test "trigger during daylight saving time 2h past UTC" do
     record = %{
        crontab: "0 0 16 * * *",
        time_zone: "Europe/Berlin",
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }
      start = ~U[2026-05-26 13:59:59Z] |> to_seconds()
      now   = ~U[2026-05-26 14:00:00Z] |> to_seconds()

      {:ok, init_state} = Drizzle.init([[record], start, nil])
      assert_receive :evaluate
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {now, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, init_state)
        assert now == next_state.last_evaluation
        assert_receive :trigger
        refute_receive :trigger
      end
    end
  end

  test "on the day when daylight saving time ends the hour between 2am ans 3am happens twice" do
     record = %{
        crontab: "0 30 2 * * *",
        time_zone: "Europe/Berlin",
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }
      start = ~U[2025-10-25 23:59:59Z] |> to_seconds()
      now   = ~U[2025-10-26 02:00:00Z] |> to_seconds()

      {:ok, init_state} = Drizzle.init([[record], start, nil])
      assert_receive :evaluate
      with_mocks [{Drizzle.Time, [:passthrough], [now: fn() -> {now, 0} end]}] do
        {:noreply, next_state} = Drizzle.handle_info(:evaluate, init_state)
        assert now == next_state.last_evaluation
        assert_receive :trigger
        assert_receive :trigger
        refute_receive :trigger
      end
    end
  describe "updating records" do

    test "malformed records don't crash the server" do
     broken_record = %{
        crontab: "0 30 2 * * *",
        time_zone: "Europe/Schmerlin",
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }

      {:ok, init_state} = Drizzle.init([[], nil, nil])
      {:noreply, next_state} = Drizzle.handle_cast({:update_records, [broken_record]}, init_state)
      assert init_state == next_state
    end

    test "new records are picked up" do
     record = %{
        crontab: "0 30 2 * * *",
        time_zone: "Europe/Berlin",
        module: Process,
        function: :send,
        args: [self(), :trigger, []]
      }

      {:ok, init_state} = Drizzle.init([[], nil, nil])
      {:noreply, next_state} = Drizzle.handle_cast({:update_records, [record]}, init_state)
      assert 1 == length(next_state.records)
    end

    end

  def to_seconds(%DateTime{} = time) do
    time
    |> DateTime.to_gregorian_seconds() |> elem(0)
  end
  end
