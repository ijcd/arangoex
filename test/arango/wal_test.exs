defmodule WalTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Wal

  test "flushes the WAL" do
    assert {:ok, %{}} = Wal.flush() |> arango()
    assert {:ok, %{}} = Wal.flush(waitForSync: true) |> arango()
    assert {:ok, %{}} = Wal.flush(waitForCollector: true) |> arango()
    assert {:ok, %{}} = Wal.flush(waitForSync: true, waitForCollector: true) |> arango()
  end
end
