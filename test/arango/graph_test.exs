defmodule GraphTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Graph

  test "List all graphs", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "graphs" => []}
    } = Graph.graphs() |> on_db(ctx)
  end

  test "Create a graph", ctx do
    graph = Graph.create(
      "foobar",
      [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}],
      ["orphans1", "orphans2"]
    ) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => ["orphans1", "orphans2"],
          "edgeDefinitions" => [
            %{
              "collection" => "edges",
              "from" => ["startVertices"],
              "to" => ["endVertices"]
            }
          ]
        }
      }
    } = graph
  end

  test "Drop a graph", ctx do
    Graph.create("toDrop") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true
      }
    } = Graph.drop("toDrop") |> on_db(ctx)

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "graph not found",
        "errorNum" => 1924
      }
    } = Graph.drop("doesNotExist") |> on_db(ctx)
  end

  test "Get a graph", ctx do
    Graph.create("toGet") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/toGet",
          "_rev" => _,
          "name" => "toGet",
          "edgeDefinitions" => [],
          "orphanCollections" => []
        }
      }
    } = Graph.graph("toGet") |> on_db(ctx)

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "graph not found",
        "errorNum" => 1924
      }
    } = Graph.graph("doesNotExist") |> on_db(ctx)
  end

  test "List edge definitions", ctx do
    Graph.create(
      "foobar",
      [
        %Graph.EdgeDefinition{collection: "foos", from: ["fooFrom"], to: ["fooTo"]},
        %Graph.EdgeDefinition{collection: "bars", from: ["barFrom"], to: ["barTo"]},
        %Graph.EdgeDefinition{collection: "bangs", from: ["bangFrom"], to: ["bangTo"]},
      ]
    ) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "collections" => ["bangs", "bars", "foos"],
        "error" => false
       }
    } = Graph.edges("foobar") |> on_db(ctx)
  end

  test "Add edge definition", ctx do
    Graph.create("foobar") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "collections" => [],
        "error" => false
       }
    } = Graph.edges("foobar") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => [],
          "edgeDefinitions" => [
            %{"collection" => "bangs", "from" => ["bangFrom"], "to" => ["bangTo"]}
          ]
        }
      }
    } = Graph.extend_edge_definintions("foobar", %Graph.EdgeDefinition{collection: "bangs", from: ["bangFrom"], to: ["bangTo"]}) |> on_db(ctx)
  end

  test "Create an edge", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "males", %{_key: "Glenn", name: "Glenn"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Maria", name: "Maria"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_id" => _,
          "_key" => _,
          "_rev" => _,
        },
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"}) |> on_db(ctx)
  end

  test "Remove an edge", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "males", %{_key: "Glenn", name: "Glenn"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Maria", name: "Maria"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true
      }
    } = Graph.edge_delete("social", "friends", edge_key) |> on_db(ctx)
  end

  test "Get an edge", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "males", %{_key: "Glenn", name: "Glenn"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Maria", name: "Maria"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Nancy", name: "Nancy"}) |> on_db(ctx)

    # create an edge with extra data
    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key,
          "_from" => "males/Glenn",
          "_to" => "females/Maria",
          "type" => "friends"
        },
      }
    } = Graph.edge("social", "friends", edge_key) |> on_db(ctx)

    # create an edge with extra data
    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Nancy", data: %{random: "string"}}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key,
          "_from" => "males/Glenn",
          "_to" => "females/Nancy",
          "type" => "friends",
          "random" => "string"
        },
      }
    } = Graph.edge("social", "friends", edge_key) |> on_db(ctx)
  end

  test "Modify an edge", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "males", %{_key: "Glenn", name: "Glenn"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Maria", name: "Maria"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria", data: %{since: "when"}}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key,
          "_id" => _,
          "_oldRev" => _,
          "_rev" => _,
        },
      }
    } = Graph.edge_update("social", "friends", edge_key, %{"since" => "then"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key,
          "_from" => "males/Glenn",
          "_to" => "females/Maria",
          "type" => "friends",
          "since" => "then"
        },
      }
    } = Graph.edge("social", "friends", edge_key) |> on_db(ctx)
  end

  test "Replace an edge", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "males", %{_key: "Glenn", name: "Glenn"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Maria", name: "Maria"}) |> on_db(ctx)
    {:ok, _} = Graph.vertex_create("social", "females", %{_key: "Nancy", name: "Nancy"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create("social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria", data: %{since: "when"}}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key
        }
      }
    } = Graph.edge_replace("social", "friends", edge_key, %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Nancy", data: %{after: "tomorrow"}}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key,
          "_from" => "males/Glenn",
          "_to" => "females/Nancy",
          "type" => "friends",
          "after" => "tomorrow"
        },
      }
    } = Graph.edge("social", "friends", edge_key) |> on_db(ctx)
  end

  test "Remove an edge definition from the graph", ctx do
    Graph.create("foobar", [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}], ["orphans1", "orphans2"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => ["orphans1", "orphans2"],
          "edgeDefinitions" => [
            %{
              "collection" => "edges",
              "from" => ["startVertices"],
              "to" => ["endVertices"]
            }
          ]
        }
      }
    } = Graph.graph("foobar") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => ["orphans1", "orphans2", "startVertices", "endVertices"],
          "edgeDefinitions" => [],
        }
      }
    } = Graph.edge_definition_delete("foobar", "edges") |> on_db(ctx)
  end

  test "Replace an edge definition", ctx do
    Graph.create("foobar", [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}], ["orphans1", "orphans2"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => ["orphans1", "orphans2"],
          "edgeDefinitions" => [
            %{
              "collection" => "edges",
              "from" => ["startVertices"],
              "to" => ["endVertices"]
            }
          ]
        }
      }
    } = Graph.graph("foobar") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "_id" => "_graphs/foobar",
          "_rev" => _,
          "name" => "foobar",
          "orphanCollections" => ["orphans1", "orphans2", "startVertices", "endVertices"],
          "edgeDefinitions" => [
            %{
              "collection" => "edges",
              "from" => ["newStartVertices"],
              "to" => ["newEndVertices"]
            }
          ],
        }
      }
    } = Graph.edge_definition_replace("foobar", "edges", %Graph.EdgeDefinition{collection: "edges", from: ["newStartVertices"], to: ["newEndVertices"]}) |> on_db(ctx)
  end

  test "List vertex collections", ctx do
    Graph.create("social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["females", "males"]
      }
    } = Graph.vertex_collections("social") |> on_db(ctx)
  end


  test "Add vertex collection", ctx do
    Graph.create("social", []) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => []
      }
    } = Graph.vertex_collections("social") |> on_db(ctx)

    assert {
      :ok, %{
        "graph" => %{
          "name" => "social",
          "edgeDefinitions" => [],
          "orphanCollections" => ["cats"]
        }
      }
    } = Graph.vertex_collection_create("social", %Graph.VertexCollection{collection: "cats"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["cats"]
      }
    } = Graph.vertex_collections("social") |> on_db(ctx)
  end

  test "Remove vertex collection", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["cats", "dogs"]
      }
    } = Graph.vertex_collections("social") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "orphanCollections" => ["cats"]
        }
      }
    } = Graph.vertex_collection_delete("social", "dogs") |> on_db(ctx)
  end

  test "Create a vertex", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create("social", "dogs", %{name: "meowington", size: "medium"}) |> on_db(ctx)
  end

  test "Remove a vertex", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create("social", "dogs", %{_key: "mton", name: "meowington", size: "medium"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true,
      }
    } = Graph.vertex_delete("social", "dogs", "mton") |> on_db(ctx)
  end

  test "Get a vertex", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create("social", "dogs", %{_key: "mton", name: "meowington", size: "medium"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "vertex" => %{
          "_id" => _,
          "_key" => "mton",
          "_rev" => _,
          "name" => "meowington",
          "size" => "medium"
        }
      }
    } = Graph.vertex("social", "dogs", "mton") |> on_db(ctx)
  end

  test "Modify a vertex", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create("social", "dogs", %{_key: "mton", name: "meowington", size: "medium"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_update("social", "dogs", "mton", %{age: 9}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "vertex" => %{
          "_id" => _,
          "_key" => "mton",
          "_rev" => _,
          "name" => "meowington",
          "size" => "medium",
          "age" => 9,
        }
      }
    } = Graph.vertex("social", "dogs", "mton") |> on_db(ctx)
  end

  test "Replace a vertex", ctx do
    Graph.create("social", [], ["cats", "dogs"]) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create("social", "dogs", %{_key: "mton", name: "meowington", size: "medium"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "vertex" => %{
          "_key" => "mton",
        }
      }
    } = Graph.vertex_replace("social", "dogs", "mton", %{age: 9}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "vertex" => mton = %{
          "_id" => _,
          "_key" => "mton",
          "_rev" => _,
          "age" => 9,
        }
      }
    } = Graph.vertex("social", "dogs", "mton") |> on_db(ctx)

    refute Map.has_key?(mton, "name")
    refute Map.has_key?(mton, "size")
    assert Map.has_key?(mton, "age")
  end
end
