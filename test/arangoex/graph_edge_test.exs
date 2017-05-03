defmodule GraphEdgeTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Graph  
  alias Arangoex.GraphEdge
  
  test "Read in or outbound edges", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "social", [%Graph.EdgeDefinition{collection: "people", from: ["person"], to: ["person"]}])
    {:ok, %{"vertex" => %{"_id" => amy_id}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Amy", name: "Amy"})
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Brad", name: "Brad"})
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Cindy", name: "Cindy"})
    {:ok, %{"vertex" => %{"_id" => derek_id}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Derek", name: "Derek"})
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Erin", name: "Erin"})
    {:ok, %{"vertex" => %{"_id" => fred_id}}} = Graph.vertex_create(ctx.endpoint, "social", "person", %{_key: "Fred", name: "Fred"})        

    # (amy, brad, cindy) -> derek
    Graph.edge_create(ctx.endpoint, "social", "people", %Graph.Edge{type: "people", from: "person/Amy", to: "person/Derek"})
    Graph.edge_create(ctx.endpoint, "social", "people", %Graph.Edge{type: "people", from: "person/Brad", to: "person/Derek"})
    Graph.edge_create(ctx.endpoint, "social", "people", %Graph.Edge{type: "people", from: "person/Cindy", to: "person/Derek"})

    # derek -> (erin, fred)
    Graph.edge_create(ctx.endpoint, "social", "people", %Graph.Edge{type: "people", from: "person/Derek", to: "person/Erin"})
    Graph.edge_create(ctx.endpoint, "social", "people", %Graph.Edge{type: "people", from: "person/Derek", to: "person/Fred"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 3},
        "edges" => edges
      }
    } = GraphEdge.edges(ctx.endpoint, "people", derek_id, "in")
    assert [
      %{"_from" => "person/Amy", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Brad", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Cindy", "_to" => "person/Derek", "type" => "people"},
    ] = Enum.sort(edges)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 2},
        "edges" => edges,
      }
    } = GraphEdge.edges(ctx.endpoint, "people", derek_id, "out")
    assert [
      %{"_from" => "person/Derek", "_id" => _, "_key" => _, "_rev" => _, "_to" => "person/Erin", "type" => "people"},
      %{"_from" => "person/Derek", "_id" => _, "_key" => _, "_rev" => _, "_to" => "person/Fred", "type" => "people"},
    ] = Enum.sort(edges)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 0},
        "edges" => [],
      }
    } = GraphEdge.edges(ctx.endpoint, "people", amy_id, "in")

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 0},
        "edges" => [],
      }
    } = GraphEdge.edges(ctx.endpoint, "people", fred_id, "out")

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 5},
        "edges" => edges,
      }
    } = GraphEdge.edges(ctx.endpoint, "people", derek_id)
    assert [
      %{"_from" => "person/Amy", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Brad", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Cindy", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Derek", "_to" => "person/Erin", "type" => "people"},
      %{"_from" => "person/Derek", "_to" => "person/Fred", "type" => "people"},
    ] = Enum.sort(edges)
  end
end
