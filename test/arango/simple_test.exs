defmodule SimpleTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Simple
  alias Arango.Document
  alias Arango.Index

  setup do
    %{
      data1: %{"name" =>"Jim", "age" => 22, "fruit" => %{"apple" => 3, "pear" => 4}},
      data2: %{"name" =>"John", "age" => 33, "cars" => %{"honda" => 5, "ford" => 6}},
      data3: %{"name" =>"Jack", "age" => 44, "sports" => %{"hockey" => 7, "soccer" => 8}},
    }
  end

  test "return all documents", ctx do
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "count" => 3,
        "error" => false,
        "extra" => _,
        "hasMore" => false,
        "result" => result,
      }
    } = Simple.all(ctx.coll) |> on_db(ctx)
    assert [22, 33, 44] = result |> Enum.map(& &1["age"]) |> Enum.sort

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "count" => 1,
        "error" => false,
        "extra" => _,
        "hasMore" => false,
        "result" => result,
      }
    } = Simple.all(ctx.coll, skip: 2) |> on_db(ctx)
    assert length(result) == 1

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "count" => 2,
        "error" => false,
        "extra" => _,
        "hasMore" => false,
        "result" => result,
      }
    } = Simple.all(ctx.coll, skip: 1) |> on_db(ctx)
    assert length(result) == 2
  end

  test "Return a random document", ctx do
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "document" => %{"_id" => _, "_key" => _, "_rev" => _, "age" => _, "name" => _,}
      }
    } = Simple.any(ctx.coll) |> on_db(ctx)
  end

  test "Simple query by-example", ctx do
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201, "count" => 2, "error" => false, "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}}
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{age: 33}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201, "count" => 2, "error" => false, "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}}
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"cars.honda": 5}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201, "count" => 2, "error" => false, "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}}
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"cars" => %{"honda" => 5, "ford" => 6}}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201, "count" => 1, "error" => false, "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}}
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{age: 33}, skip: 1) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201, "count" => 1, "error" => false, "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5}}
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{age: 33}, limit: 1) |> on_db(ctx)
  end

  test "Find document matching an example", ctx do
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200, "error" => false,
        "document" => %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5},
        },
      }
    } = Simple.find_by_example(ctx.coll, %{age: 33}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200, "error" => false,
        "document" => %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5},
        },
      }
    } = Simple.find_by_example(ctx.coll, %{"cars.honda": 5}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200, "error" => false,
        "document" => %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "name" => "John", "cars" => %{"ford" => 6, "honda" => 5},
        },
      }
    } = Simple.find_by_example(ctx.coll, %{"cars" => %{"honda" => 5, "ford" => 6}}) |> on_db(ctx)
  end

  test "Fulltext index query", ctx do
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

    {:ok, %{"id" => index_id}} = Index.create_fulltext(ctx.coll.name, "name") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 3,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.query_fulltext(ctx.coll, "name", "john") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 3,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.query_fulltext(ctx.coll, "name", "john", index: index_id) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.query_fulltext(ctx.coll, "name", "john", limit: 1) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.query_fulltext(ctx.coll, "name", "john", skip: 1) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.query_fulltext(ctx.coll, "name", "john", skip: 1, limit: 1) |> on_db(ctx)
  end

  test "Lookup documents by their keys", ctx do
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data1, %{"_key" => "foo1"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data2, %{"_key" => "foo2"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data3, %{"_key" => "foo3"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data1, %{"_key" => "foo4"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data2, %{"_key" => "foo5"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data3, %{"_key" => "foo6"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data1, %{"_key" => "foo7"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data2, %{"_key" => "foo8"})) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, Map.merge(ctx.data3, %{"_key" => "foo9"})) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "documents" => [
          %{"_id" => _, "_key" => "foo2", "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => "foo5", "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"},
          %{"_id" => _, "_key" => "foo8", "_rev" => _, "age" => 33, "cars" => %{"ford" => 6, "honda" => 5}, "name" => "John"}
        ]
      }
    } = Simple.lookup_by_keys(ctx.coll, ["foo2", "foo5", "foo8"]) |> on_db(ctx)
  end

  test "Simple range query", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"size" => 0}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 2}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 8}) |> on_db(ctx)
    {:ok, %{"id" => _id1}} = Index.create_skiplist(ctx.coll.name, ["size"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 3,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 2},
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 6},
        ]
      }
    } = Simple.range(ctx.coll, "size", 2, 8) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 4,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 2},
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 6},
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 8},
        ]
      }
    } = Simple.range(ctx.coll, "size", 2, 8, closed: true) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "size" => 6},
        ]
      }
    } = Simple.range(ctx.coll, "size", 2, 8, skip: 2, limit: 2) |> on_db(ctx)
  end

  test "Remove documents by example", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"size" => 0}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 2}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"size" => 8}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "deleted" => 3,
      }
    } = Simple.remove_by_example(ctx.coll, %{"size" => 4}, waitForSync: true) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "deleted" => 2,
        "error" => false
      }
    } = Simple.remove_by_example(ctx.coll, %{"size" => 6}, limit: 2) |> on_db(ctx)
  end

  test "Remove documents by their keys", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "a", "name" => "aa"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "b", "name" => "bb"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "c", "name" => "cc"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "d", "name" => "dd"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "e", "name" => "ee"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "f", "name" => "ff"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "g", "name" => "gg"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"_key" => "h", "name" => "hh"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "ignored" => 0,
        "removed" => 2,
      }
    } = Simple.remove_by_keys(ctx.coll, ["b", "d"], waitForSync: true) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "ignored" => 0,
        "removed" => 2,
        "old" => [
          %{"_id" => _, "_key" => "a", "_rev" => _},
          %{"_id" => _, "_key" => "c", "_rev" => _}
        ],
      }
    } = Simple.remove_by_keys(ctx.coll, ["a", "c"], silent: false, returnOld: false) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "ignored" => 0,
        "removed" => 2,
        "old" => [
          %{"_id" => _, "_key" => "e", "_rev" => _, "name" => "ee"},
          %{"_id" => _, "_key" => "f", "_rev" => _, "name" => "ff"},
        ],
      }
    } = Simple.remove_by_keys(ctx.coll, ["e", "f"], silent: false, returnOld: true) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "ignored" => 0,
        "removed" => 2,
      } = res
    } = Simple.remove_by_keys(ctx.coll, ["g", "h"], silent: true, returnOld: true) |> on_db(ctx)
    refute Map.has_key?(res, "old")
  end

  test "Replace documents by example", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"name" => "a"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "a"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "b"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "b"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "c"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "c"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "replaced" => 2
      }
    } = Simple.replace_by_example(ctx.coll, %{"name" => "a"}, %{"foo" => 1}, waitForSync: true) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "foo" => 1},
          %{"_id" => _, "_key" => _, "_rev" => _, "foo" => 1},
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"foo" => 1}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "replaced" => 1
      }
    } = Simple.replace_by_example(ctx.coll, %{"name" => "b"}, %{"bar" => 2}, limit: 1) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "bar" => 2},
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"bar" => 2}) |> on_db(ctx)
  end

  test "Update documents by example", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"name" => "a"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "a"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "b"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "b"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "c"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "c"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "d"}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"name" => "e"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "updated" => 2
      }
    } = Simple.update_by_example(ctx.coll, %{"name" => "a"}, %{"foo" => 1}, waitForSync: true) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "foo" => 1},
          %{"_id" => _, "_key" => _, "_rev" => _, "foo" => 1},
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"foo" => 1}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "updated" => 1
      }
    } = Simple.update_by_example(ctx.coll, %{"name" => "b"}, %{"bar" => 2}, limit: 1) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "bar" => 2},
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"bar" => 2}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "updated" => 2
      }
    } = Simple.update_by_example(ctx.coll, %{"name" => "c"}, %{"bang" => 3}, mergeObjects: true) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "name" => "c", "bang" => 3},
          %{"_id" => _, "_key" => _, "_rev" => _, "name" => "c", "bang" => 3},
        ]
      }
    } = Simple.query_by_example(ctx.coll, %{"bang" => 3}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "updated" => 1
      }
    } = Simple.update_by_example(ctx.coll, %{"name" => "d"}, %{"dog" => nil}, keepNull: false) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "name" => "d"},
        ] = res
      }
    } = Simple.query_by_example(ctx.coll, %{"name" => "d"}) |> on_db(ctx)
    refute res |> Enum.at(0) |> Map.has_key?("dog")

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "updated" => 1
      }
    } = Simple.update_by_example(ctx.coll, %{"name" => "e"}, %{"dog" => nil}, keepNull: true) |> on_db(ctx)
    assert {
      :ok, %{
        "code" => 201,
        "count" => 1,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "name" => "e"},
        ] = res
      }
    } = Simple.query_by_example(ctx.coll, %{"name" => "e"}) |> on_db(ctx)
    assert res |> Enum.at(0) |> Map.has_key?("dog")
  end

  test "Returns documents near a coordinate", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 0, "long" => 0, "lat2" => 4, "long2" => 8}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 1, "long" => 2, "lat2" => 3, "long2" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 2, "long" => 4, "lat2" => 2, "long2" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 3, "long" => 6, "lat2" => 1, "long2" => 2}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 4, "long" => 8, "lat2" => 0, "long2" => 0}) |> on_db(ctx)
    {:ok, %{"id" => _id1}} = Index.create_geo(ctx.coll.name, ["lat", "long"]) |> on_db(ctx)
    {:ok, %{"id" => _id2}} = Index.create_geo(ctx.coll.name, ["lat2", "long2"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 5,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 3, "long" => 6},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 4, "long" => 8},
        ]
      }
    } = Simple.near(ctx.coll, 0, 0) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 5,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 4, "long" => 8},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 3, "long" => 6},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0},
        ]
      }
    } = Simple.near(ctx.coll, 10, 10) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
        ]
      }
    } = Simple.near(ctx.coll, 10, 10, skip: 2, limit: 2) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 5,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 4, "long" => 8, "dist" => 702_702.8525777259},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 3, "long" => 6, "dist" => 894_925.4721965357},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4, "dist" => 1_109_425.0718353987},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2, "dist" => 1_335_621.8882911967},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0, "dist" => 1_568_520.556798576},
        ]
      }
    } = Simple.near(ctx.coll, 10, 10, distance: "dist") |> on_db(ctx)

    # This seems to be broken...
    # assert {
    #   :ok, %{
    #     "code" => 201,
    #     "count" => 5,
    #     "error" => false,
    #     "hasMore" => false,
    #     "result" => [
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0, "lat2" => 4, "long2" => 8, "dist" => 1568520.556798576},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2, "lat2" => 3, "long2" => 6, "dist" => 1335621.8882911967},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4, "lat2" => 2, "long2" => 4, "dist" => 1109425.0718353987},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 3, "long" => 6, "lat2" => 1, "long2" => 2, "dist" => 894925.4721965357},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 4, "long" => 8, "lat2" => 0, "long2" => 0, "dist" => 702702.8525777259},
    #     ]
    #   }
    # } = Simple.near(ctx.coll, 10, 10, distance: "dist", geo: id2) |> on_db(ctx)
  end

  test "Find documents within a radius around a coordinate", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 0, "long" => 0, "lat2" => 4, "long2" => 8}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 1, "long" => 2, "lat2" => 3, "long2" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 2, "long" => 4, "lat2" => 2, "long2" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 3, "long" => 6, "lat2" => 1, "long2" => 2}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 4, "long" => 8, "lat2" => 0, "long2" => 0}) |> on_db(ctx)
    {:ok, %{"id" => _id1}} = Index.create_geo(ctx.coll.name, ["lat", "long"]) |> on_db(ctx)
    {:ok, %{"id" => _id2}} = Index.create_geo(ctx.coll.name, ["lat2", "long2"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
        ]
      }
    } = Simple.within(ctx.coll, 0, 0, 250_000) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 3, "long" => 6},
        ]
      }
    } = Simple.within(ctx.coll, 0, 0, 1_000_000, skip: 2, limit: 2) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0, "dist" => 0},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2, "dist" => 248_629.31484681246},
        ]
      }
    } = Simple.within(ctx.coll, 0, 0, 250_000, distance: "dist") |> on_db(ctx)

    # This seems to be broken...
    # assert {
    #   :ok, %{
    #     "code" => 201,
    #     "count" => 2,
    #     "error" => false,
    #     "hasMore" => false,
    #     "result" => [
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat2" => 0, "long2" => 0},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat2" => 1, "long2" => 2},
    #     ]
    #   }
    # } = Simple.within(ctx.coll, 0, 0, 250_000, geo: id2)
  end

  test "Within rectangle query", ctx do
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 0, "long" => 0, "lat2" => 4, "long2" => 8}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 1, "long" => 2, "lat2" => 3, "long2" => 6}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 2, "long" => 4, "lat2" => 2, "long2" => 4}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 3, "long" => 6, "lat2" => 1, "long2" => 2}) |> on_db(ctx)
    {:ok, _} = Document.create(ctx.coll, %{"lat" => 4, "long" => 8, "lat2" => 0, "long2" => 0}) |> on_db(ctx)
    {:ok, %{"id" => _id1}} = Index.create_geo(ctx.coll.name, ["lat", "long"]) |> on_db(ctx)
    {:ok, %{"id" => _id2}} = Index.create_geo(ctx.coll.name, ["lat2", "long2"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 0, "long" => 0},
        ]
      }
    } = Simple.within_rectangle(ctx.coll, 0, 0, 3, 3) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 201,
        "count" => 2,
        "error" => false,
        "hasMore" => false,
        "result" => [
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 2, "long" => 4},
          %{"_id" => _, "_key" => _, "_rev" => _, "lat" => 1, "long" => 2},
        ]
      }
    } = Simple.within_rectangle(ctx.coll, 0, 0, 10, 10, skip: 2, limit: 2) |> on_db(ctx)

    # This seems to be broken...
    # assert {
    #   :ok, %{
    #     "code" => 201,
    #     "count" => 2,
    #     "error" => false,
    #     "hasMore" => false,
    #     "result" => [
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat2" => 0, "long2" => 0},
    #       %{"_id" => _, "_key" => _, "_rev" => _, "lat2" => 1, "long2" => 2},
    #     ]
    #   }
    # } = Simple.within_rectangle(ctx.coll, 0, 0, 250_000, geo: id2)
  end
end
