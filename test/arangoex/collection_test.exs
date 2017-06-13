defmodule CollectionTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Collection
  alias Arangoex.Document
  alias Arangoex.Wal

  test "lists collections" do
    {:ok, collections} = Collection.collections(test_endpoint(), "_system")
    names =
      collections
      |> Enum.map(fn c -> c.name end)
      |> Enum.sort

    assert names == [
      "_apps", "_aqlfunctions", "_frontend", "_graphs", "_jobs", "_modules",
      "_queues", "_routing", "_statistics", "_statistics15", "_statisticsRaw",
      "_users"
    ]
  end

  test "creates a collection", ctx do
    new_collname = Faker.Lorem.word

    {:ok, original_colls} = Collection.collections(ctx.endpoint)
    {:ok, coll} = Collection.create(ctx.endpoint, %Collection{name: new_collname})
    {:ok, after_colls} = Collection.collections(ctx.endpoint)

    assert [coll] == after_colls -- original_colls
    assert coll.name == new_collname
  end

  test "drops a collection", ctx do
    new_coll = %Collection{name: Faker.Lorem.word}

    # create one to drop
    {:ok, _} = Collection.create(ctx.endpoint, new_coll)
    {:ok, colls} = Collection.collections(ctx.endpoint)

    assert new_coll.name in Enum.map(colls, & &1.name)

    # drop and make sure it's gone
    {:ok, _} = Collection.drop(ctx.endpoint, new_coll)
    {:ok, colls} = Collection.collections(ctx.endpoint)

    refute new_coll.name in Enum.map(colls, & &1.name)
  end

  test "looks up collection information", ctx do
    {:ok, new_coll} = Collection.collection(ctx.endpoint, ctx.coll)
    assert new_coll == ctx.coll
  end

  test "loads a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, info} = Collection.load(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = info
    assert Map.has_key?(info, "count")

    {:ok, info} = Collection.load(ctx.endpoint, ctx.coll, false)

    assert %{"name" => ^coll_name, "error" => false} = info
    refute Map.has_key?(info, "count")
  end

  test "unloads a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, info} = Collection.unload(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = info
  end

  test "looks up collection checksum", ctx do
    coll_name = ctx.coll.name
    {:ok, checksum} = Collection.checksum(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = checksum
    assert Map.has_key?(checksum, "checksum")
    assert Map.has_key?(checksum, "revision")
  end

  test "counts documents in a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, count} = Collection.count(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = count
    assert Map.has_key?(count, "count")
  end

  test "looks up statistics of a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, figures} = Collection.figures(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = figures
    assert Map.has_key?(figures, "figures")
  end

  test "looks up collection properties", ctx do
    coll_name = ctx.coll.name
    {:ok, properties} = Collection.properties(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = properties
    assert Map.has_key?(properties, "waitForSync")
    assert Map.has_key?(properties, "doCompact")
    assert Map.has_key?(properties, "journalSize")
    assert Map.has_key?(properties, "isVolatile")
  end

  test "sets collection properties", ctx do
    coll_name = ctx.coll.name

    {:ok, properties} = Collection.set_properties(ctx.endpoint, ctx.coll, waitForSync: true)
    assert %{"name" => ^coll_name, "error" => false, "waitForSync" => true} = properties

    {:ok, properties} = Collection.set_properties(ctx.endpoint, ctx.coll, journalSize: 1_048_576)
    assert %{"name" => ^coll_name, "error" => false, "journalSize" => 1_048_576} = properties

    {:ok, properties} = Collection.set_properties(ctx.endpoint, ctx.coll, journalSize: 2_048_576, waitForSync: false)
    assert %{"name" => ^coll_name, "error" => false, "waitForSync" => false, "journalSize" => 2_048_576} = properties
  end

  test "renames collection", ctx do
    {:ok, properties} = Collection.rename(ctx.endpoint, ctx.coll, "foobar")
    assert %{"name" => "foobar", "error" => false} = properties
  end

  test "looks up collection revision id", ctx do
    coll_name = ctx.coll.name
    {:ok, revision} = Collection.revision(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = revision
    assert Map.has_key?(revision, "revision")
  end

  test "rotates a collection journal", ctx do
    {:ok, _} = Document.create(ctx.endpoint, ctx.coll, %{name: "RotateMe"})
    {:ok, _} = Wal.flush(ctx.endpoint, waitForSync: true, waitForCollector: true)
    assert {:ok, %{"result" => true, "error" => false, "code" => 200}} = Collection.rotate(ctx.endpoint, ctx.coll)
  end

  test "truncates a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, truncate} = Collection.truncate(ctx.endpoint, ctx.coll)

    assert %{"name" => ^coll_name, "error" => false} = truncate
  end
end
