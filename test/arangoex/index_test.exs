defmodule IndexTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Index

  test "Read index", ctx do
    id = "#{ctx.coll.name}/0"

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "fields" => ["_key"],
        "id" => ^id,
        "selectivityEstimate" => 1,
        "sparse" => false,
        "type" => "primary",
        "unique" => true
      }
    } = Index.index(id) |> on_db(ctx)
  end

  test "Fails to read an index", ctx do
    id = "#{ctx.coll.name}/123"

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "unknown index '123'",
        "errorNum" => 1212
      }
    } = Index.index(id) |> on_db(ctx)
  end

  test "Read all indexes of a collection", ctx do
    id = "#{ctx.coll.name}/0"

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "identifiers" => %{
          ^id => %{
            "fields" => ["_key"],
            "id" => ^id,
            "selectivityEstimate" => 1,
            "sparse" => false,
            "type" => "primary",
            "unique" => true
          }
        },
        "indexes" => [
          %{
            "fields" => ["_key"],
            "id" => ^id,
            "selectivityEstimate" => 1,
            "sparse" => false,
            "type" => "primary",
            "unique" => true
           }
        ]
      }
    } = Index.indexes(ctx.coll.name) |> on_db(ctx)
  end

  test "Create general index", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["bar"],
        "id" => _,
        "isNewlyCreated" => true,
        "minLength" => 3,
        "sparse" => true,
        "type" => "fulltext",
        "unique" => false
      }
    } = Index.create_general(ctx.coll.name, %{"type" => "fulltext", "fields" => ["bar"], "minLength" => 3}) |> on_db(ctx)
  end

  test "Create fulltext index", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["foo"],
        "id" => _,
        "isNewlyCreated" => true,
        "minLength" => _,
        "sparse" => true,
        "type" => "fulltext",
        "unique" => false
      }
    } = Index.create_fulltext(ctx.coll.name, "foo") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["bar"],
        "id" => _,
        "isNewlyCreated" => true,
        "minLength" => 10,
        "sparse" => true,
        "type" => "fulltext",
        "unique" => false
      }
    } = Index.create_fulltext(ctx.coll.name, "bar", minLength: 10) |> on_db(ctx)
  end

  test "Create geo-spatial index", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["lat", "long"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => true,
        "type" => "geo2",
        "unique" => false,
        "constraint" => false,
        "ignoreNull" => true
      }
    } = Index.create_geo(ctx.coll.name, ["lat", "long"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["latlong_array"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => true,
        "type" => "geo1",
        "unique" => false,
        "constraint" => false,
        "ignoreNull" => true,
        "geoJson" => false
      }
    } = Index.create_geo(ctx.coll.name, ["latlong_array"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "fields" => ["latlong_array2"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => true,
        "type" => "geo1",
        "unique" => false,
        "constraint" => false,
        "ignoreNull" => true,
        "geoJson" => true
      }
    } = Index.create_geo(ctx.coll.name, ["latlong_array2"], geoJson: true) |> on_db(ctx)
  end

  test "Create hash index", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["bang", "bar", "foo"],
        "id" => _,
        "isNewlyCreated" => true,
        "selectivityEstimate" => 1,
        "sparse" => false,
        "type" => "hash",
        "unique" => false,
      }
    } = Index.create_hash(ctx.coll.name, ["bang", "bar", "foo"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["bang", "bar", "foo"],
        "id" => _,
        "isNewlyCreated" => true,
        "selectivityEstimate" => 1,
        "sparse" => true,
        "type" => "hash",
        "unique" => true,
      }
    } = Index.create_hash(ctx.coll.name, ["bang", "bar", "foo"], unique: true, sparse: true) |> on_db(ctx)
  end

  test "Create a persistent index", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["foo", "bar", "bang"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => false,
        "type" => "persistent",
        "unique" => false,
      }
    } = Index.create_persistent(ctx.coll.name, ["foo", "bar", "bang"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["foo", "bar", "bang"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => true,
        "type" => "persistent",
        "unique" => true,
      }
    } = Index.create_persistent(ctx.coll.name, ["foo", "bar", "bang"], unique: true, sparse: true) |> on_db(ctx)
  end

  test "Create skip list", ctx do
    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["foo", "bar", "bang"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => false,
        "type" => "skiplist",
        "unique" => false,
      }
    } = Index.create_skiplist(ctx.coll.name, ["foo", "bar", "bang"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "error" => false, "fields" => ["foo", "bar", "bang"],
        "id" => _,
        "isNewlyCreated" => true,
        "sparse" => true,
        "type" => "skiplist",
        "unique" => true,
      }
    } = Index.create_skiplist(ctx.coll.name, ["foo", "bar", "bang"], unique: true, sparse: true) |> on_db(ctx)
  end

  test "Delete index", ctx do
    {:ok, %{"id" => id}} = Index.create_fulltext(ctx.coll.name, "foo") |> on_db(ctx)

    assert {
      :ok, %{"code" => 200, "error" => false, "id" => ^id}
    } = Index.delete(id) |> on_db(ctx)

    msg = "unknown index '#{id}'"
    assert {
      :error, %{"code" => 404, "error" => true, "errorMessage" => ^msg, "errorNum" => 1212}
    } = Index.delete(id) |> on_db(ctx)
  end
end
