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

  test "looks up the WAL properties" do
    expected_wal = %Arango.Wal{
      allowOversizeEntries: false,
      historicLogfiles: 9,
      logfileSize: 635_544,
      reserveLogfiles: 5,
      syncInterval: 100,
      throttleWait: 14_890,
      throttleWhenPending: 2
    }
    {:ok, _} = Wal.set_properties(expected_wal) |> arango()

    assert {:ok, expected_wal} == Wal.properties() |> arango()
  end

  test "sets wal properties" do
    {:ok, properties} = Wal.set_properties(%Wal{}) |> arango()
    assert %Wal{} = properties

    {:ok, properties} = Wal.set_properties(reserveLogfiles: 7) |> arango()
    assert %Wal{reserveLogfiles: 7} = properties
  end

  test "looks up running transactions" do
    {:ok, transactions} = Wal.transactions() |> arango()

    assert %{"minLastCollected" => nil, "minLastSealed" => nil, "runningTransactions" => _} = transactions
  end
end
