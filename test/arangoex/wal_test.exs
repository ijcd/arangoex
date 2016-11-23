defmodule WalTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Wal

  test "flushes the WAL", ctx do
    assert {:ok, %{"error" => false}} = ctx.endpoint |> Wal.flush
    assert {:ok, %{"error" => false}} = ctx.endpoint |> Wal.flush(waitForSync: true)
    assert {:ok, %{"error" => false}} = ctx.endpoint |> Wal.flush(waitForCollector: true)
    assert {:ok, %{"error" => false}} = ctx.endpoint |> Wal.flush(waitForSync: true, waitForCollector: true)
  end

  test "looks up the WAL properties", ctx do
    expected_wal = %Arangoex.Wal{
      allowOversizeEntries: false,
      historicLogfiles: 9,
      logfileSize: 635_544,
      reserveLogfiles: 5,
      syncInterval: 100,
      throttleWait: 14_890,
      throttleWhenPending: 2
    }
    {:ok, _} = Wal.set_properties(ctx.endpoint, expected_wal)
    
    assert {:ok, ^expected_wal} = ctx.endpoint |> Wal.properties
  end

  test "sets wal properties", ctx do
    {:ok, properties} = Wal.set_properties(ctx.endpoint, %Wal{})
    assert %Wal{} = properties

    {:ok, properties} = Wal.set_properties(ctx.endpoint, reserveLogfiles: 7)
    assert %Wal{reserveLogfiles: 7} = properties
  end

  test "looks up running transactions", ctx do
    {:ok, transactions} = Wal.transactions(ctx.endpoint)
    
    assert %{"code" => 200, "error" => false, "minLastCollected" => nil, "minLastSealed" => nil, "runningTransactions" => 0} = transactions
  end
end
