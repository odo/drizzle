
defmodule  ParserTest do
  use ExUnit.Case
  doctest Drizzle

  alias Drizzle.Parser

  @base_record %{
    crontab: "* * * * *",
    time_zone: :utc,
    module: :module,
    function: :function,
    args: []
  }

  describe "crontab parsing" do

    test "valid minute crontab" do
      assert {:ok, _recods} = Parser.parse_records(
        [Map.put(
          @base_record,
          :crontab,
          "0 * * * Mon-Fri"
        )]
      )
    end

    test "valid second crontab" do
      assert {:ok, _recods} = Parser.parse_records(
        [Map.put(
          @base_record,
          :crontab,
          "*/30 * * * * *"
        )]
      )
    end
    
    test "invalid crontab" do
      assert {:error, error} = Parser.parse_records(
        [Map.put(
          @base_record,
          :crontab,
          "61 * * * * *"
        )]
      )
      assert [second: "61"] == error
    end
  end
  
  describe "timezone parsing" do

    test ":utc works" do
      assert {:ok, _recods} = Parser.parse_records(
        [Map.put(
          @base_record,
          :time_zone,
          :utc
        )]
      )
    end

    test "Berlin works" do
      assert {:ok, _recods} = Parser.parse_records(
        [Map.put(
          @base_record,
          :time_zone,
          "Europe/Berlin"
        )]
      )
    end

    test "Invalid timezone fails" do
      assert {:error, error} = Parser.parse_records(
        [Map.put(
          @base_record,
          :time_zone,
          "Ocean/Atlantis"
        )]
      )
      assert :time_zone_not_found == error
    end
  end
  
  describe "general record format" do

    test "missing keys fail" do
      assert {:error, error} = Parser.parse_records(
        [Map.delete(
          @base_record,
          :time_zone
        )]
      )
      assert :invalid_record == error
    end

    test "wrong types fail" do
      assert {:error, error} = Parser.parse_records(
        [Map.put(
          @base_record,
          :module,
          fn() -> :fail end
        )]
      )
      assert :invalid_record == error
    end
  end

end
