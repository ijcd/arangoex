defmodule GraphTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Graph

  test "List all graphs", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "graphs" => []}
    } = Graph.graphs(ctx.endpoint)
  end

  test "Create a graph", ctx do
    graph = Graph.create(
      ctx.endpoint,
      "foobar",
      [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}],
      ["orphans1", "orphans2"]
    )

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
    Graph.create(ctx.endpoint, "toDrop")

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true
      }
    } = Graph.drop(ctx.endpoint, "toDrop")

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "graph not found",
        "errorNum" => 1924
      }
    } = Graph.drop(ctx.endpoint, "doesNotExist")
  end

  test "Get a graph", ctx do
    Graph.create(ctx.endpoint, "toGet")

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
    } = Graph.graph(ctx.endpoint, "toGet")

    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "graph not found",
        "errorNum" => 1924
      }
    } = Graph.graph(ctx.endpoint, "doesNotExist")
  end

  test "List edge definitions", ctx do
    Graph.create(
      ctx.endpoint,
      "foobar",
      [
        %Graph.EdgeDefinition{collection: "foos", from: ["fooFrom"], to: ["fooTo"]},
        %Graph.EdgeDefinition{collection: "bars", from: ["barFrom"], to: ["barTo"]},
        %Graph.EdgeDefinition{collection: "bangs", from: ["bangFrom"], to: ["bangTo"]},
      ]
    )

    assert {
      :ok, %{
        "code" => 200,
        "collections" => ["bangs", "bars", "foos"],
        "error" => false
       }
    } = Graph.edges(ctx.endpoint, "foobar")
  end

  test "Add edge definition", ctx do
    Graph.create(ctx.endpoint, "foobar")

    assert {
      :ok, %{
        "code" => 200,
        "collections" => [],
        "error" => false
       }
    } = Graph.edges(ctx.endpoint, "foobar")

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
    } = Graph.extend_edge_definintions(ctx.endpoint, "foobar", %Graph.EdgeDefinition{collection: "bangs", from: ["bangFrom"], to: ["bangTo"]})
  end

  test "Create an edge", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "males", %{_key: "Glenn", name: "Glenn"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Maria", name: "Maria"})

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
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"})
  end

  test "Remove an edge", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "males", %{_key: "Glenn", name: "Glenn"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Maria", name: "Maria"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true
      }
    } = Graph.edge_delete(ctx.endpoint, "social", "friends", edge_key)
  end

  test "Get an edge", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "males", %{_key: "Glenn", name: "Glenn"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Maria", name: "Maria"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Nancy", name: "Nancy"})

    # create an edge with extra data
    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria"})

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
    } = Graph.edge(ctx.endpoint, "social", "friends", edge_key)

    # create an edge with extra data
    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Nancy", data: %{random: "string"}})

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
    } = Graph.edge(ctx.endpoint, "social", "friends", edge_key)
  end

  test "Modify an edge", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "males", %{_key: "Glenn", name: "Glenn"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Maria", name: "Maria"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria", data: %{since: "when"}})

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
    } = Graph.edge_update(ctx.endpoint, "social", "friends", edge_key, %{"since" => "then"})

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
    } = Graph.edge(ctx.endpoint, "social", "friends", edge_key)
  end

  test "Replace an edge", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "males", %{_key: "Glenn", name: "Glenn"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Maria", name: "Maria"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "social", "females", %{_key: "Nancy", name: "Nancy"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => edge_key
        }
      }
    } = Graph.edge_create(ctx.endpoint, "social", "friends", %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Maria", data: %{since: "when"}})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "edge" => %{
          "_key" => ^edge_key
        }
      }
    } = Graph.edge_replace(ctx.endpoint, "social", "friends", edge_key, %Graph.Edge{type: "friends", from: "males/Glenn", to: "females/Nancy", data: %{after: "tomorrow"}})

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
    } = Graph.edge(ctx.endpoint, "social", "friends", edge_key)
  end

  test "Remove an edge definition from the graph", ctx do
    Graph.create(ctx.endpoint, "foobar", [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}], ["orphans1", "orphans2"])

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
    } = Graph.graph(ctx.endpoint, "foobar")

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
    } = Graph.edge_definition_delete(ctx.endpoint, "foobar", "edges")
  end

  test "Replace an edge definition", ctx do
    Graph.create(ctx.endpoint, "foobar", [%Graph.EdgeDefinition{collection: "edges", from: ["startVertices"], to: ["endVertices"]}], ["orphans1", "orphans2"])

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
    } = Graph.graph(ctx.endpoint, "foobar")

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
    } = Graph.edge_definition_replace(ctx.endpoint, "foobar", "edges", %Graph.EdgeDefinition{collection: "edges", from: ["newStartVertices"], to: ["newEndVertices"]})
  end

  test "List vertex collections", ctx do
    Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "friends", from: ["females", "males"], to: ["females", "males"]}])

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["females", "males"]
      }
    } = Graph.vertex_collections(ctx.endpoint, "social")
  end


  test "Add vertex collection", ctx do
    Graph.create(ctx.endpoint, "social", [])

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => []
      }
    } = Graph.vertex_collections(ctx.endpoint, "social")

    assert {
      :ok, %{
        "graph" => %{
          "name" => "social",
          "edgeDefinitions" => [],
          "orphanCollections" => ["cats"]
        }
      }
    } = Graph.vertex_collection_create(ctx.endpoint, "social", %Graph.VertexCollection{collection: "cats"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["cats"]
      }
    } = Graph.vertex_collections(ctx.endpoint, "social")
  end

  test "Remove vertex collection", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "collections" => ["cats", "dogs"]
      }
    } = Graph.vertex_collections(ctx.endpoint, "social")

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "graph" => %{
          "orphanCollections" => ["cats"]
        }
      }
    } = Graph.vertex_collection_delete(ctx.endpoint, "social", "dogs")
  end

  test "Create a vertex", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create(ctx.endpoint, "social", "dogs", %{name: "meowington", size: "medium"})
  end

  test "Remove a vertex", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create(ctx.endpoint, "social", "dogs", %{_key: "mton", name: "meowington", size: "medium"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "removed" => true,
      }
    } = Graph.vertex_delete(ctx.endpoint, "social", "dogs", "mton")
  end

  test "Get a vertex", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create(ctx.endpoint, "social", "dogs", %{_key: "mton", name: "meowington", size: "medium"})

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
    } = Graph.vertex(ctx.endpoint, "social", "dogs", "mton")
  end

  test "Modify a vertex", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create(ctx.endpoint, "social", "dogs", %{_key: "mton", name: "meowington", size: "medium"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_update(ctx.endpoint, "social", "dogs", "mton", %{age: 9})

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
    } = Graph.vertex(ctx.endpoint, "social", "dogs", "mton")
  end

  test "Replace a vertex", ctx do
    Graph.create(ctx.endpoint, "social", [], ["cats", "dogs"])

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
      }
    } = Graph.vertex_create(ctx.endpoint, "social", "dogs", %{_key: "mton", name: "meowington", size: "medium"})

    assert {
      :ok, %{
        "code" => 202,
        "error" => false,
        "vertex" => %{
          "_key" => "mton",
        }
      }
    } = Graph.vertex_replace(ctx.endpoint, "social", "dogs", "mton", %{age: 9})

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
    } = Graph.vertex(ctx.endpoint, "social", "dogs", "mton")

    refute Map.has_key?(mton, "name")
    refute Map.has_key?(mton, "size")
    assert Map.has_key?(mton, "age")
  end
end
