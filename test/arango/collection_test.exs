defmodule CollectionTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Collection
  alias Arango.Document

  test "lists collections" do
    {:ok, collections} = Collection.collections() |> arango(database_name: "_system")

    names =
      collections
      |> Enum.map(fn c -> c.name end)
      |> Enum.sort()

    # Don't hardcode system collections — they differ between ArangoDB versions.
    # Just check that some known system collections exist.
    for expected <- ["_graphs", "_jobs", "_queues", "_statistics"] do
      assert expected in names, "Expected #{expected} in system collections"
    end
  end

  test "creates a collection", ctx do
    new_collname = Faker.Lorem.word()

    {:ok, original_colls} = Collection.collections() |> on_db(ctx)
    {:ok, coll} = Collection.create(%Collection{name: new_collname}) |> on_db(ctx)
    {:ok, after_colls} = Collection.collections() |> on_db(ctx)

    new_colls = after_colls -- original_colls
    assert length(new_colls) == 1
    [created] = new_colls
    assert created.name == new_collname
    assert coll.name == new_collname
  end

  test "drops a collection", ctx do
    new_coll = %Collection{name: Faker.Lorem.word()}

    # create one to drop
    {:ok, _} = Collection.create(new_coll) |> on_db(ctx)
    {:ok, colls} = Collection.collections() |> on_db(ctx)

    assert new_coll.name in Enum.map(colls, & &1.name)

    # drop and make sure it's gone
    {:ok, _} = Collection.drop(new_coll) |> on_db(ctx)
    {:ok, colls} = Collection.collections() |> on_db(ctx)

    refute new_coll.name in Enum.map(colls, & &1.name)
  end

  test "looks up collection information", ctx do
    {:ok, new_coll} = Collection.collection(ctx.coll) |> on_db(ctx)
    assert new_coll.id == ctx.coll.id
    assert new_coll.name == ctx.coll.name
    assert new_coll.type == ctx.coll.type
    assert new_coll.isSystem == ctx.coll.isSystem
  end

  test "loads a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, info} = Collection.load(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = info
    assert Map.has_key?(info, "count")

    {:ok, info} = Collection.load(ctx.coll, false) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = info
    refute Map.has_key?(info, "count")
  end

  test "unloads a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, info} = Collection.unload(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = info
  end

  test "looks up collection checksum", ctx do
    coll_name = ctx.coll.name
    {:ok, checksum} = Collection.checksum(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = checksum
    assert Map.has_key?(checksum, "checksum")
    assert Map.has_key?(checksum, "revision")
  end

  test "counts documents in a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, count} = Collection.count(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = count
    assert Map.has_key?(count, "count")
  end

  test "looks up statistics of a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, figures} = Collection.figures(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = figures
    assert Map.has_key?(figures, "figures")
  end

  test "looks up collection properties", ctx do
    coll_name = ctx.coll.name
    {:ok, properties} = Collection.properties(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = properties
    assert Map.has_key?(properties, "waitForSync")
  end

  test "sets collection properties", ctx do
    coll_name = ctx.coll.name

    {:ok, properties} = Collection.set_properties(ctx.coll, waitForSync: true) |> on_db(ctx)
    assert %{"name" => ^coll_name, "error" => false, "waitForSync" => true} = properties

    {:ok, properties} = Collection.set_properties(ctx.coll, waitForSync: false) |> on_db(ctx)
    assert %{"name" => ^coll_name, "error" => false, "waitForSync" => false} = properties
  end

  test "renames collection", ctx do
    {:ok, properties} = Collection.rename(ctx.coll, "foobar") |> on_db(ctx)
    assert %{"name" => "foobar", "error" => false} = properties
  end

  test "looks up collection revision id", ctx do
    coll_name = ctx.coll.name
    {:ok, revision} = Collection.revision(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = revision
    assert Map.has_key?(revision, "revision")
  end

  test "truncates a collection", ctx do
    coll_name = ctx.coll.name
    {:ok, truncate} = Collection.truncate(ctx.coll) |> on_db(ctx)

    assert %{"name" => ^coll_name, "error" => false} = truncate
  end

  # === Phase 4 additions ===

  test "create/2 with schema rejects invalid documents", ctx do
    schema = %{
      "rule" => %{
        "type" => "object",
        "properties" => %{"name" => %{"type" => "string"}},
        "required" => ["name"]
      },
      "level" => "strict",
      "message" => "name is required"
    }

    {:ok, _} =
      Collection.create(%Collection{name: "validated", schema: schema}) |> on_db(ctx)

    c = %Collection{name: "validated"}
    {:ok, _} = Document.create(c, %{"name" => "Alice"}) |> on_db(ctx)
    assert {:error, %{"code" => 400}} = Document.create(c, %{}) |> on_db(ctx)
  end

  test "create/2 with computedValues echoes the definition in properties", ctx do
    computed = [
      %{
        "name" => "x2",
        "expression" => "RETURN @doc.x * 2",
        "computeOn" => ["insert"],
        "overwrite" => true
      }
    ]

    {:ok, _} =
      Collection.create(%Collection{name: "with_cv", computedValues: computed})
      |> on_db(ctx)

    {:ok, props} = Collection.properties(%Collection{name: "with_cv"}) |> on_db(ctx)
    assert is_list(props["computedValues"])
    assert hd(props["computedValues"])["name"] == "x2"
  end

  test "create/2 with cacheEnabled echoes the flag in properties", ctx do
    {:ok, _} =
      Collection.create(%Collection{name: "cached", cacheEnabled: true}) |> on_db(ctx)

    {:ok, props} = Collection.properties(%Collection{name: "cached"}) |> on_db(ctx)
    assert props["cacheEnabled"] == true
  end

  test "set_properties/2 toggles cacheEnabled", ctx do
    {:ok, _} = Collection.set_properties(ctx.coll, cacheEnabled: true) |> on_db(ctx)
    {:ok, props} = Collection.properties(ctx.coll) |> on_db(ctx)
    assert props["cacheEnabled"] == true
  end

  test "compact/1 succeeds on a populated collection", ctx do
    for i <- 1..100, do: {:ok, _} = Document.create(ctx.coll, %{"i" => i}) |> on_db(ctx)
    assert {:ok, _} = Collection.compact(ctx.coll) |> on_db(ctx)
  end

  test "shards/1 builds a GET on the shards endpoint" do
    # Server-side behavior is cluster-only (single-server returns 400);
    # assert the wrapper produces the right request.
    op = Collection.shards(%Collection{name: "foo"})
    assert op.http_method == :get
    assert op.path == "collection/foo/shards"
  end

  test "responsible_shard/2 builds a PUT with the document as body" do
    op = Collection.responsible_shard(%Collection{name: "foo"}, %{"_key" => "abc"})
    assert op.http_method == :put
    assert op.path == "collection/foo/responsibleShard"
    assert op.body == %{"_key" => "abc"}
  end
end
