defmodule CursorTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Cursor
  alias Arangoex.Collection
  alias Arangoex.Document

  setup ctx do
    {:ok, coll} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Alice", "age" => 11}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Bob", "age" => 22}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Charlie", "age" => 33}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Dave", "age" => 44}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Eve", "age" => 55}) |> on_db(ctx)
    {:ok, _} = Document.create(coll, %{"name" => "Frank", "age" => 66}) |> on_db(ctx)
    ctx
  end

  test "Create cursor (execute a query and extract the result in a single go)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products LIMIT 2 RETURN p",
      count: true,
      batch_size: 2
    }

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "error" => false,
        "count" => 2,
        "hasMore" => false,
        "result" => result,
        "extra" => %{
          "stats" => %{
            "executionTime" => _,
            "filtered" => 0,
            "scannedFull" => 2,
            "scannedIndex" => 0,
            "writesExecuted" => 0,
            "writesIgnored" => 0
          },
          "warnings" => []
        },
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
    assert Enum.count(result) == 2
  end

  test "Create cursor (execute a query and extract a part of the result)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products LIMIT 5 RETURN p",
      count: true,
      batch_size: 2
    }

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "error" => false,
        "count" => 5,
        "hasMore" => true,
        "result" => result,
        "extra" => %{
          "stats" => %{
            "executionTime" => _,
            "filtered" => 0,
            "scannedFull" => 5,
            "scannedIndex" => 0,
            "writesExecuted" => 0,
            "writesIgnored" => 0
          },
          "warnings" => []
        },
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
    assert Enum.count(result) == 2
  end

  test "Create cursor (execute a query with bind_vars)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products FILTER p.age == @age RETURN p.name",
      count: true,
      batch_size: 2,
      bind_vars: [age: 11]
    }

    assert {
      :ok, %{
        "cached" => false,
        "code" => 201,
        "error" => false,
        "count" => 1,
        "hasMore" => false,
        "result" => ["Alice"],
        "extra" => %{
          "stats" => %{
            "executionTime" => _,
            "filtered" => 5,
            "scannedFull" => 6,
            "scannedIndex" => 0,
            "writesExecuted" => 0,
            "writesIgnored" => 0
          },
          "warnings" => []
        },
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (using the query option \"fullCount\")", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR i IN 1..1000 FILTER i > 500 LIMIT 10 RETURN i",
      count: true,
      full_count: true
    }

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "hasMore" => false,
        "count" => 10,
        "cached" => false,
        "result" => [501, 502, 503, 504, 505, 506, 507, 508, 509, 510],
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 0,
            "writesIgnored" => 0,
            "scannedFull" => 0,
            "scannedIndex" => 0,
            "filtered" => 500,
            "fullCount" => 500,
            "executionTime" => _
          },
          "warnings" => []
        }
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (enabling and disabling optimizer rules)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR i IN 1..10 LET a = 1 LET b = 2 FILTER a + b == 3 RETURN i",
      count: true,
      max_plans: 1,
      optimizer_rules: ["-all", "+remove-unnecessary-filters"]
    }

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "hasMore" => false,
        "count" => 10,
        "cached" => false,
        "result" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 0,
            "writesIgnored" => 0,
            "scannedFull" => 0,
            "scannedIndex" => 0,
            "filtered" => 0,
            "executionTime" => _,
          },
          "warnings" => []
        },
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (execute a data-modification query and retrieve the number of modified documents)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products REMOVE p IN products",
    }

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "hasMore" => false,
        "cached" => false,
        "result" => [],
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 6,
            "writesIgnored" => 0,
            "scannedFull" => 6,
            "scannedIndex" => 0,
            "filtered" => 0,
            "executionTime" => _,
          },
          "warnings" => []
        }
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (execute a data-modification query with option ignoreErrors)", ctx do
    cursor = %Cursor.Cursor{
      query: "REMOVE 'bar' IN products OPTIONS { ignoreErrors: true }",
    }

    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
        "hasMore" => false,
        "cached" => false,
        "result" => [],
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 0,
            "writesIgnored" => 1,
            "scannedFull" => 0,
            "scannedIndex" => 0,
            "filtered" => 0,
            "executionTime" => _
          },
          "warnings" => []
        }
      }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (bad query - missing body)", ctx do
    cursor = %Cursor.Cursor{
      query: "",
    }

    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "query is empty (while parsing)",
        "errorNum" => 1502
      }
    } == Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (bad query - unknown collection)", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR u IN unknowncoll LIMIT 2 RETURN u",
      count: true,
      batch_size: 2
    }

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "collection not found (unknowncoll)",
        "errorNum" => 1203
      }
    } == Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Create cursor (bad query - execute a data-modification query that attempts to remove a non-existing document)", ctx do
    cursor = %Cursor.Cursor{
      query: "REMOVE 'foo' IN products"
    }

    assert {
     :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "document not found (while executing)",
        "errorNum" => 1202
      }
    } == Cursor.cursor_create(cursor) |> on_db(ctx)
  end

  test "Delete cursor", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products LIMIT 5 RETURN p",
      count: true,
      batch_size: 2
    }

    {:ok, %{"id" => id}} = Cursor.cursor_create(cursor) |> on_db(ctx)

    # delete the cursor
    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "id" => _
      }
    } = Cursor.cursor_delete(id) |> on_db(ctx)

    # cannot delete again
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "cursor not found",
        "errorNum" => 1600
      }
    } == Cursor.cursor_delete(id) |> on_db(ctx)
  end

  test "Read next batch from cursor", ctx do
    cursor = %Cursor.Cursor{
      query: "FOR p IN products LIMIT 5 RETURN p",
      count: true,
      batch_size: 2
    }

    {:ok, %{
        "id" => id,
        "result" => result,
     }
    } = Cursor.cursor_create(cursor) |> on_db(ctx)
    assert Enum.count(result) == 2

    # get another batch
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "hasMore" => true,
        "id" => id,
        "count" => 5,
        "cached" => false,
        "result" => result,
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 0,
            "writesIgnored" => 0,
            "scannedFull" => 5,
            "scannedIndex" => 0,
            "filtered" => 0,
            "executionTime" => _
          },
          "warnings" => []
        }
      }
    } = Cursor.cursor_next(id) |> on_db(ctx)
    assert Enum.count(result) == 2

    # get another batch
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "hasMore" => false,
        # "id" => id,
        "count" => 5,
        "cached" => false,
        "result" => result,
        "extra" => %{
          "stats" => %{
            "writesExecuted" => 0,
            "writesIgnored" => 0,
            "scannedFull" => 5,
            "scannedIndex" => 0,
            "filtered" => 0,
            "executionTime" => _
          },
          "warnings" => []
        }
      }
    } = Cursor.cursor_next(id) |> on_db(ctx)
    assert Enum.count(result) == 1
  end
end
