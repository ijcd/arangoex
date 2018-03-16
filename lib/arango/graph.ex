defmodule Arango.Graph do
  @moduledoc "ArangoDB Graph methods"

  alias Arango.Request

  defmodule EdgeDefinition do
    @moduledoc false

    defstruct [:collection, :from, :to]

    @type t :: %__MODULE__{
      # The name of the collection
      collection: String.t,

      # The vertex types an edge can come from
      from: list(String.t),

      # The vertex types an edge can go to
      to: list(String.t),
    }
  end

  defmodule Edge do
    @moduledoc false

    defstruct [:type, :from, :to, :data]

    @type t :: %__MODULE__{
      # The edge type
      type: String.t,

      # The from document
      from: String.t,

      # The to document
      to: String.t,

      data: map
    }
  end

  # TODO: do we need a struct for structs with a single value?
  defmodule VertexCollection do
    @moduledoc false

    defstruct [:collection]

    @type t :: %__MODULE__{
      # The name of the collection
      collection: String.t,
    }
  end

  @doc """
  List all graphs

  GET /_api/gharial
  """
  @spec graphs() :: Arango.ok_error(map)
  def graphs() do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial"
    }
  end

  @doc """
  Create a graph

  POST /_api/gharial
  """
  @spec create(String.t, list(EdgeDefinition.t), list(String.t)) :: Arango.ok_error(map)
  def create(graph_name, edge_definitions \\ [], orphan_collections \\ []) do
    body = %{
      "name" => graph_name,
      "edgeDefinitions" => edge_definitions,
      "orphanCollections" => orphan_collections
    }

    %Request{
      endpoint: :graph,
      http_method: :post,
      path: "gharial",
      body: body
    }
  end

  @doc """
  Drop a graph

  DELETE /_api/gharial/{graph-name}
  """
  @spec drop(String.t) :: Arango.ok_error(map)
  def drop(graph_name) do
    %Request{
      endpoint: :graph,
      http_method: :delete,
      path: "gharial/#{graph_name}"
    }
  end

  @doc """
  Get a graph

  GET /_api/gharial/{graph-name}
  """
  @spec graph(String.t) :: Arango.ok_error(map)
  def graph(graph_name) do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial/#{graph_name}"
    }
  end

  @doc """
  List edge definitions

  GET /_api/gharial/{graph-name}/edge
  """
  @spec edges(String.t) :: Arango.ok_error(map)
  def edges(graph_name) do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial/#{graph_name}/edge"
    }
  end

  @doc """
  Add edge definition

  POST /_api/gharial/{graph-name}/edge
  """
  @spec extend_edge_definintions(String.t, EdgeDefinition.t) :: Arango.ok_error(map)
  def extend_edge_definintions(graph_name, edge_definition) do
    body = Map.from_struct(edge_definition)

    %Request{
      endpoint: :graph,
      http_method: :post,
      path: "gharial/#{graph_name}/edge",
      body: body
    }
  end

  @doc """
  Create an edge

  POST /_api/gharial/{graph-name}/edge/{collection-name}
  """
  @spec edge_create(String.t, String.t, Edge.t) :: Arango.ok_error(map)
  def edge_create(graph_name, collection_name, edge) do
    body = %{
      "type" => edge.type,
      "_from" => edge.from,
      "_to" => edge.to,
    } |> Map.merge(edge.data || %{})

    %Request{
      endpoint: :graph,
      http_method: :post,
      path: "gharial/#{graph_name}/edge/#{collection_name}",
      body: body
    }
  end

  @doc """
  Remove an edge

  DELETE /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_delete(String.t, String.t, String.t) :: Arango.ok_error(map)
  def edge_delete(graph_name, collection_name, edge_key) do
    %Request{
      endpoint: :graph,
      http_method: :delete,
      path: "gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}"
    }
  end

  @doc """
  Get an edge

  GET /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge(String.t, String.t, String.t) :: Arango.ok_error(map)
  def edge(graph_name, collection_name, edge_key) do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}"
    }
  end

  @doc """
  Modify an edge

  PATCH /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_update(String.t, String.t, String.t, map) :: Arango.ok_error(map)
  def edge_update(graph_name, collection_name, edge_key, edge_body) do
    %Request{
      endpoint: :graph,
      http_method: :patch,
      path: "gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}",
      body: edge_body
    }
  end

  @doc """
  Replace an edge

  PUT /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_replace(String.t, String.t, String.t, Edge.t) :: Arango.ok_error(map)
  def edge_replace(graph_name, collection_name, edge_key, edge) do
    body = %{
      "type" => edge.type,
      "_from" => edge.from,
      "_to" => edge.to,
    } |> Map.merge(edge.data || %{})

    %Request{
      endpoint: :graph,
      http_method: :put,
      path: "gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}",
      body: body
    }
  end

  @doc """
  Remove an edge definition from the graph

  DELETE /_api/gharial/{graph-name}/edge/{definition-name}
  """
  @spec edge_definition_delete(String.t, String.t) :: Arango.ok_error(map)
  def edge_definition_delete(graph_name, edge_definition_name) do
    %Request{
      endpoint: :graph,
      http_method: :delete,
      path: "gharial/#{graph_name}/edge/#{edge_definition_name}"
    }
  end

  @doc """
  Replace an edge definition

  PUT /_api/gharial/{graph-name}/edge/{definition-name}
  """
  @spec edge_definition_replace(String.t, String.t, EdgeDefinition.t) :: Arango.ok_error(map)
  def edge_definition_replace(graph_name, edge_definition_name, edge_definition) do
    %Request{
      endpoint: :graph,
      http_method: :put,
      path: "gharial/#{graph_name}/edge/#{edge_definition_name}",
      body: edge_definition
    }
  end

  @doc """
  List vertex collections

  GET /_api/gharial/{graph-name}/vertex
  """
  @spec vertex_collections(String.t) :: Arango.ok_error(map)
  def vertex_collections(graph_name) do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial/#{graph_name}/vertex",
    }
  end

  @doc """
  Add vertex collection

  POST /_api/gharial/{graph-name}/vertex
  """
  @spec vertex_collection_create(String.t, VertexCollection.t) :: Arango.ok_error(map)
  def vertex_collection_create(graph_name, vertex_collection) do
    body = Map.from_struct(vertex_collection)

    %Request{
      endpoint: :graph,
      http_method: :post,
      path: "gharial/#{graph_name}/vertex",
      body: body
    }
  end

  @doc """
  Remove vertex collection

  DELETE /_api/gharial/{graph-name}/vertex/{collection-name}
  """
  @spec vertex_collection_delete(String.t, String.t) :: Arango.ok_error(map)
  def vertex_collection_delete(graph_name, collection_name) do
    %Request{
      endpoint: :graph,
      http_method: :delete,
      path: "gharial/#{graph_name}/vertex/#{collection_name}",
    }
  end

  @doc """
  Create a vertex

  POST /_api/gharial/{graph-name}/vertex/{collection-name}
  """
  @spec vertex_create(String.t, String.t, map) :: Arango.ok_error(map)
  def vertex_create(graph_name, collection_name, vertex_body) do
    %Request{
      endpoint: :graph,
      http_method: :post,
      path: "gharial/#{graph_name}/vertex/#{collection_name}",
      body: vertex_body
    }
  end

  @doc """
  Remove a vertex

  DELETE /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_delete(String.t, String.t, String.t) :: Arango.ok_error(map)
  def vertex_delete(graph_name, collection_name, vertex_key) do
    %Request{
      endpoint: :graph,
      http_method: :delete,
      path: "gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}",
    }
  end

  @doc """
  Get a vertex

  GET /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex(String.t, String.t, String.t) :: Arango.ok_error(map)
  def vertex(graph_name, collection_name, vertex_key) do
    %Request{
      endpoint: :graph,
      http_method: :get,
      path: "gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}",
    }
  end

  @doc """
  Modify a vertex

  PATCH /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_update(String.t, String.t, String.t, map) :: Arango.ok_error(map)
  def vertex_update(graph_name, collection_name, vertex_key, vertex_body) do
    %Request{
      endpoint: :graph,
      http_method: :patch,
      path: "gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}",
      body: vertex_body
    }
  end

  @doc """
  Replace a vertex

  PUT /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_replace(String.t, String.t, String.t, map) :: Arango.ok_error(map)
  def vertex_replace(graph_name, collection_name, vertex_key, vertex_body) do
    %Request{
      endpoint: :graph,
      http_method: :put,
      path: "gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}",
      body: vertex_body
    }
  end
end
