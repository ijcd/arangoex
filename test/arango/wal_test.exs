defmodule WalTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Wal
  alias Arango.Document

  test "flushes the WAL" do
    assert {:ok, %{}} = Wal.flush() |> arango()
    assert {:ok, %{}} = Wal.flush(waitForSync: true) |> arango()
    assert {:ok, %{}} = Wal.flush(waitForCollector: true) |> arango()
    assert {:ok, %{}} = Wal.flush(waitForSync: true, waitForCollector: true) |> arango()
  end

  test "last_tick/0 returns a numeric tick string" do
    {:ok, %{"tick" => tick}} = Wal.last_tick() |> arango()
    assert tick =~ ~r/^\d+$/
  end

  test "range/0 returns tickMin <= tickMax (numeric strings)" do
    {:ok, %{"tickMin" => tick_min, "tickMax" => tick_max}} = Wal.range() |> arango()
    assert tick_min =~ ~r/^\d+$/
    assert tick_max =~ ~r/^\d+$/
    assert String.to_integer(tick_min) <= String.to_integer(tick_max)
  end

  test "tail/1 returns NDJSON operations as a raw string", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"tail_test" => true}) |> on_db(ctx)
    {:ok, _} = Wal.flush(waitForSync: true) |> arango()

    {:ok, body} = Wal.tail(from: 0) |> arango()
    assert is_binary(body)

    ops = body |> String.split("\n", trim: true) |> Enum.map(&Jason.decode!/1)
    assert Enum.any?(ops, &Map.has_key?(&1, "tick"))
  end
end
