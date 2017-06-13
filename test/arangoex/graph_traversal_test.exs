defmodule GraphTraversalTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.GraphTraversal
  alias Arangoex.Graph

  setup ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "knows_graph", [%Graph.EdgeDefinition{collection: "people", from: ["persons"], to: ["persons"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "knows_graph", "persons", %{_key: "alice", name: "Alice"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "knows_graph", "persons", %{_key: "bob", name: "Bob"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "knows_graph", "persons", %{_key: "charlie", name: "Charlie"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "knows_graph", "persons", %{_key: "dave", name: "Dave"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "knows_graph", "persons", %{_key: "eve", name: "Eve"})

    # alice knows bob
    # bob knows charlie
    # bob knows dave
    # eve knows alice
    # eve knows bob
    Graph.edge_create(ctx.endpoint, "knows_graph", "people", %Graph.Edge{type: "people", from: "persons/alice", to: "persons/bob"})
    Graph.edge_create(ctx.endpoint, "knows_graph", "people", %Graph.Edge{type: "people", from: "persons/bob", to: "persons/charlie"})
    Graph.edge_create(ctx.endpoint, "knows_graph", "people", %Graph.Edge{type: "people", from: "persons/bob", to: "persons/dave"})
    Graph.edge_create(ctx.endpoint, "knows_graph", "people", %Graph.Edge{type: "people", from: "persons/eve", to: "persons/alice"})
    Graph.edge_create(ctx.endpoint, "knows_graph", "people", %Graph.Edge{type: "people", from: "persons/eve", to: "persons/bob"})
  end

  test "executes a traversal (Follow only outbound edges)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
    ] = visited_vertices

    assert [
      %{"edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
       },
      %{"edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{"edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob"},
          %{"_from" => "persons/bob", "_to" => "persons/charlie"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Follow only inbound edges)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "inbound"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}]
        },
        %{
          "edges" => [
            %{"_from" => "persons/eve", "_to" => "persons/alice"}
          ],
          "vertices" => [
            %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
            %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
          ]
        }
    ] = visited_paths
  end

  test "executes a traversal (Follow any direction of edges)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
        "vertices" => visited_vertices,
        "paths" => visited_paths,
      }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "any", uniqueness: %{"vertices" => "none", "edges" => "global"}})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Excluding Charlie and Bob)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", filter: "if (vertex.name === \"Bob\" || vertex.name === \"Charlie\") { return \"exclude\"; } return;" })

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Do not follow edges from Bob)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
        "vertices" => visited_vertices,
        "paths" => visited_paths,
      }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", filter: "if (vertex.name === \"Bob\") { return \"prune\"; } return;" })

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
        %{"_from" => "persons/alice", "_to" => "persons/bob",}
      ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Visit only nodes in a depth of at least 2)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
        "vertices" => visited_vertices,
        "paths" => visited_paths,
      }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", minDepth: 2})

    assert [
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Visit only nodes in a depth of at most 1)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", maxDepth: 1})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Using a visitor function to return vertex ids only)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", visitor: "result.visited.vertices.push(vertex._id);"})

    assert [
      "persons/alice",
      "persons/bob",
      "persons/charlie",
      "persons/dave"
    ] = visited_vertices

    assert [
    ] = visited_paths
  end

  test "executes a traversal (Count all visited nodes and return a list of nodes only)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => 4,
          "myVertices" => visited_vertices,
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "outbound", init: "result.visited = 0; result.myVertices = [];", visitor: "result.visited++; result.myVertices.push(vertex);"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
    ] = visited_vertices
  end

  test "executes a traversal (Expand only inbound edges of Alice and outbound edges of Eve)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", expander: "var connections = [ ];if (vertex.name === \"Alice\") {config.datasource.getInEdges(vertex).forEach(function (e) {connections.push({ vertex: require(\"internal\").db._document(e._from), edge: e});});}if (vertex.name === \"Eve\") {config.datasource.getOutEdges(vertex).forEach(function (e) {connections.push({vertex: require(\"internal\").db._document(e._to), edge: e});});}return connections;"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Follow the depthfirst strategy)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "any", strategy: "depthfirst"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob"},
          %{"_from" => "persons/eve", "_to" => "persons/alice"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice"},
          %{"_from" => "persons/eve", "_to" => "persons/bob"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice"},
          %{"_from" => "persons/eve", "_to" => "persons/bob"},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice"},
          %{"_from" => "persons/eve", "_to" => "persons/bob"},
          %{"_from" => "persons/bob", "_to" => "persons/dave"}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice"},
          %{"_from" => "persons/eve", "_to" => "persons/bob"},
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Using postorder ordering)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
            "vertices" => visited_vertices,
            "paths" => visited_paths,
          }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "any", order: "postorder"})

    assert [
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      }
    ] = visited_paths
 end

  test "executes a traversal (Using backward item-ordering=>)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
        "vertices" => visited_vertices,
        "paths" => visited_paths,
      }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "any", itemOrder: "backward"})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/eve", "_to" => "persons/alice",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (Edges should only be included once globally, but nodes are included every time they are visited)", ctx do
    assert {
      :ok, %{
        "error" => false,
        "code" => 200,
        "result" => %{
          "visited" => %{
        "vertices" => visited_vertices,
        "paths" => visited_paths,
      }
        }
      }
    } = GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "persons/alice", graphName: "knows_graph", direction: "any", uniqueness: %{"vertices" => "none", "edges" => "global"}})

    assert [
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
      %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
      %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"},
      %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"},
      %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
      %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
    ] = visited_vertices

    assert [
      %{
        "edges" => [],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/charlie",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "charlie", "_id" => "persons/charlie", "name" => "Charlie"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/bob", "_to" => "persons/dave",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "dave", "_id" => "persons/dave", "name" => "Dave"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"}
        ]
      },
      %{
        "edges" => [
          %{"_from" => "persons/alice", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/bob",},
          %{"_from" => "persons/eve", "_to" => "persons/alice",}
        ],
        "vertices" => [
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"},
          %{"_key" => "bob", "_id" => "persons/bob", "name" => "Bob"},
          %{"_key" => "eve", "_id" => "persons/eve", "name" => "Eve"},
          %{"_key" => "alice", "_id" => "persons/alice", "name" => "Alice"}
        ]
      }
    ] = visited_paths
  end

  test "executes a traversal (If the underlying graph is cyclic, maxIterations should be set)", ctx do
    {:ok, _} = Graph.create(ctx.endpoint, "cyclic_graph", [%Graph.EdgeDefinition{collection: "cylons", from: ["cylon"], to: ["cylon"]}])
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "cyclic_graph", "cylon", %{_key: "alice", name: "Alice"})
    {:ok, _} = Graph.vertex_create(ctx.endpoint, "cyclic_graph", "cylon", %{_key: "bob", name: "Bob"})

    # alice knows bob
    # bob knows alice
    Graph.edge_create(ctx.endpoint, "cyclic_graph", "cylons", %Graph.Edge{type: "cylons", from: "cylon/alice", to: "cylon/bob"})
    Graph.edge_create(ctx.endpoint, "cyclic_graph", "cylons", %Graph.Edge{type: "cylons", from: "cylon/bob", to: "cylon/alice"})

    assert {
      :error, %{
        "error" => true,
        "code" => 500,
        "errorNum" => 1909,
        "errorMessage" => "too many iterations - try increasing the value of 'maxIterations'"
      }
    } == GraphTraversal.traversal(ctx.endpoint, %GraphTraversal.Traversal{startVertex: "cylon/alice", graphName: "cyclic_graph", direction: "any", uniqueness: %{"vertices" => "none", "edges" => "none"}, maxIterations: 5})
  end
end
