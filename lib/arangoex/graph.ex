defmodule Arangoex.Graph do
  @moduledoc "ArangoDB Graph methods"

  alias Arangoex.Endpoint

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
  @spec graphs(Endpoint.t) :: Arangoex.ok_error(map)
  def graphs(endpoint) do
    endpoint
    |> Endpoint.get("gharial")
  end

  @doc """
  Create a graph

  POST /_api/gharial
  """
  @spec create(Endpoint.t, String.t, list(EdgeDefinition.t), list(String.t)) :: Arangoex.ok_error(map)
  def create(endpoint, graph_name, edge_definitions \\ [], orphan_collections \\ []) do
    body = %{
      "name" => graph_name,
      "edgeDefinitions" => edge_definitions,
      "orphanCollections" => orphan_collections
    }

    endpoint
    |> Endpoint.post("gharial", body)
  end

  @doc """
  Drop a graph

  DELETE /_api/gharial/{graph-name}
  """
  @spec drop(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def drop(endpoint, graph_name) do
    endpoint
    |> Endpoint.delete("gharial/#{graph_name}")
  end

  @doc """
  Get a graph

  GET /_api/gharial/{graph-name}
  """
  @spec graph(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def graph(endpoint, graph_name) do
    endpoint
    |> Endpoint.get("gharial/#{graph_name}")
  end

  @doc """
  List edge definitions

  GET /_api/gharial/{graph-name}/edge
  """
  @spec edges(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def edges(endpoint, graph_name) do
    endpoint
    |> Endpoint.get("gharial/#{graph_name}/edge")
  end

  @doc """
  Add edge definition

  POST /_api/gharial/{graph-name}/edge
  """
  @spec extend_edge_definintions(Endpoint.t, String.t, EdgeDefinition.t) :: Arangoex.ok_error(map)
  def extend_edge_definintions(endpoint, graph_name, edge_definition) do
    body = Map.from_struct(edge_definition)

    endpoint
    |> Endpoint.post("gharial/#{graph_name}/edge", body)
  end

  @doc """
  Create an edge

  POST /_api/gharial/{graph-name}/edge/{collection-name}
  """
  @spec edge_create(Endpoint.t, String.t, String.t, Edge.t) :: Arangoex.ok_error(map)
  def edge_create(endpoint, graph_name, collection_name, edge) do
    body = %{
      "type" => edge.type,
      "_from" => edge.from,
      "_to" => edge.to,
    } |> Map.merge(edge.data || %{})
    
    endpoint
    |> Endpoint.post("gharial/#{graph_name}/edge/#{collection_name}", body)
  end

  @doc """
  Remove an edge

  DELETE /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_delete(Endpoint.t, String.t, String.t, String.t) :: Arangoex.ok_error(map)
  def edge_delete(endpoint, graph_name, collection_name, edge_key) do
    endpoint
    |> Endpoint.delete("gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}")
  end

  @doc """
  Get an edge

  GET /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge(Endpoint.t, String.t, String.t, String.t) :: Arangoex.ok_error(map)
  def edge(endpoint, graph_name, collection_name, edge_key) do
    endpoint
    |> Endpoint.get("gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}")
  end

  @doc """
  Modify an edge

  PATCH /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_update(Endpoint.t, String.t, String.t, String.t, map) :: Arangoex.ok_error(map)
  def edge_update(endpoint, graph_name, collection_name, edge_key, edge_body) do
    endpoint
    |> Endpoint.patch("gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}", edge_body)
  end

  @doc """
  Replace an edge

  PUT /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  """
  @spec edge_replace(Endpoint.t, String.t, String.t, String.t, Edge.t) :: Arangoex.ok_error(map)
  def edge_replace(endpoint, graph_name, collection_name, edge_key, edge) do
    body = %{
      "type" => edge.type,
      "_from" => edge.from,
      "_to" => edge.to,
    } |> Map.merge(edge.data || %{})
    
    endpoint
    |> Endpoint.put("gharial/#{graph_name}/edge/#{collection_name}/#{edge_key}", body)
  end

  @doc """
  Remove an edge definition from the graph

  DELETE /_api/gharial/{graph-name}/edge/{definition-name}
  """
  @spec edge_definition_delete(Endpoint.t, String.t, String.t) :: Arangoex.ok_error(map)
  def edge_definition_delete(endpoint, graph_name, edge_definition_name) do
    endpoint
    |> Endpoint.delete("gharial/#{graph_name}/edge/#{edge_definition_name}")
  end

  @doc """
  Replace an edge definition

  PUT /_api/gharial/{graph-name}/edge/{definition-name}
  """
  @spec edge_definition_replace(Endpoint.t, String.t, String.t, EdgeDefinition.t) :: Arangoex.ok_error(map)
  def edge_definition_replace(endpoint, graph_name, edge_definition_name, edge_definition) do
    endpoint
    |> Endpoint.put("gharial/#{graph_name}/edge/#{edge_definition_name}", edge_definition)
  end

  @doc """
  List vertex collections

  GET /_api/gharial/{graph-name}/vertex
  """
  @spec vertex_collections(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def vertex_collections(endpoint, graph_name) do
    endpoint
    |> Endpoint.get("gharial/#{graph_name}/vertex")
  end

  @doc """
  Add vertex collection

  POST /_api/gharial/{graph-name}/vertex
  """
  @spec vertex_collection_create(Endpoint.t, String.t, VertexCollection.t) :: Arangoex.ok_error(map)
  def vertex_collection_create(endpoint, graph_name, vertex_collection) do
    body = Map.from_struct(vertex_collection)
    
    endpoint
    |> Endpoint.post("gharial/#{graph_name}/vertex", body)
  end

  @doc """
  Remove vertex collection

  DELETE /_api/gharial/{graph-name}/vertex/{collection-name}
  """
  @spec vertex_collection_delete(Endpoint.t, String.t, String.t) :: Arangoex.ok_error(map)
  def vertex_collection_delete(endpoint, graph_name, collection_name) do
    endpoint
    |> Endpoint.delete("gharial/#{graph_name}/vertex/#{collection_name}")
  end

  @doc """
  Create a vertex

  POST /_api/gharial/{graph-name}/vertex/{collection-name}
  """
  @spec vertex_create(Endpoint.t, String.t, String.t, map) :: Arangoex.ok_error(map)
  def vertex_create(endpoint, graph_name, collection_name, vertex_body) do
    endpoint
    |> Endpoint.post("gharial/#{graph_name}/vertex/#{collection_name}", vertex_body)
  end

  @doc """
  Remove a vertex

  DELETE /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_delete(Endpoint.t, String.t, String.t, String.t) :: Arangoex.ok_error(map)
  def vertex_delete(endpoint, graph_name, collection_name, vertex_key) do
    endpoint
    |> Endpoint.delete("gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}")
  end

  @doc """
  Get a vertex

  GET /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex(Endpoint.t, String.t, String.t, String.t) :: Arangoex.ok_error(map)
  def vertex(endpoint, graph_name, collection_name, vertex_key) do
    endpoint
    |> Endpoint.get("gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}")
  end

  @doc """
  Modify a vertex

  PATCH /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_update(Endpoint.t, String.t, String.t, String.t, map) :: Arangoex.ok_error(map)
  def vertex_update(endpoint, graph_name, collection_name, vertex_key, vertex_body) do
    endpoint
    |> Endpoint.patch("gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}", vertex_body)
  end

  @doc """
  Replace a vertex

  PUT /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  """
  @spec vertex_replace(Endpoint.t, String.t, String.t, String.t, map) :: Arangoex.ok_error(map)
  def vertex_replace(endpoint, graph_name, collection_name, vertex_key, vertex_body) do
    endpoint
    |> Endpoint.put("gharial/#{graph_name}/vertex/#{collection_name}/#{vertex_key}", vertex_body)
  end
end
