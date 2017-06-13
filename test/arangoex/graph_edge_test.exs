defmodule GraphEdgeTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Graph
  alias Arangoex.GraphEdge

  test "Read in or outbound edges", ctx do
    {:ok, _} = Graph.create("social", [%Graph.EdgeDefinition{collection: "people", from: ["person"], to: ["person"]}]) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => amy_id}}} = Graph.vertex_create("social", "person", %{_key: "Amy", name: "Amy"}) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create("social", "person", %{_key: "Brad", name: "Brad"}) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create("social", "person", %{_key: "Cindy", name: "Cindy"}) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => derek_id}}} = Graph.vertex_create("social", "person", %{_key: "Derek", name: "Derek"}) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => _}}} = Graph.vertex_create("social", "person", %{_key: "Erin", name: "Erin"}) |> on_db(ctx)
    {:ok, %{"vertex" => %{"_id" => fred_id}}} = Graph.vertex_create("social", "person", %{_key: "Fred", name: "Fred"}) |> on_db(ctx)

    # (amy, brad, cindy) -> derek
    Graph.edge_create("social", "people", %Graph.Edge{type: "people", from: "person/Amy", to: "person/Derek"}) |> on_db(ctx)
    Graph.edge_create("social", "people", %Graph.Edge{type: "people", from: "person/Brad", to: "person/Derek"}) |> on_db(ctx)
    Graph.edge_create("social", "people", %Graph.Edge{type: "people", from: "person/Cindy", to: "person/Derek"}) |> on_db(ctx)

    # derek -> (erin, fred)
    Graph.edge_create("social", "people", %Graph.Edge{type: "people", from: "person/Derek", to: "person/Erin"}) |> on_db(ctx)
    Graph.edge_create("social", "people", %Graph.Edge{type: "people", from: "person/Derek", to: "person/Fred"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 3},
        "edges" => edges
      }
    } = GraphEdge.edges("people", derek_id, "in") |> on_db(ctx)
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
    } = GraphEdge.edges("people", derek_id, "out") |> on_db(ctx)
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
    } = GraphEdge.edges("people", amy_id, "in") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 0},
        "edges" => [],
      }
    } = GraphEdge.edges("people", fred_id, "out") |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "stats" => %{"filtered" => 0, "scannedIndex" => 5},
        "edges" => edges,
      }
    } = GraphEdge.edges("people", derek_id) |> on_db(ctx)
    assert [
      %{"_from" => "person/Amy", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Brad", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Cindy", "_to" => "person/Derek", "type" => "people"},
      %{"_from" => "person/Derek", "_to" => "person/Erin", "type" => "people"},
      %{"_from" => "person/Derek", "_to" => "person/Fred", "type" => "people"},
    ] = Enum.sort(edges)
  end
end
