defmodule Arangoex.Graph do
  @moduledoc "ArangoDB Graph methods"

  # @doc """
  # List all graphs

  # GET /_api/gharial
  # """
  # @spec graphs(Endpoint.t) :: Arangoex.ok_error(map)
  # def graphs(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Create a graph

  # POST /_api/gharial
  # """
  # @spec graph_create(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_create(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # 0@doc """
  # Drop a graph

  # DELETE /_api/gharial/{graph-name}
  # """
  # @spec graph_drop(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_drop(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Get a graph

  # GET /_api/gharial/{graph-name}
  # """
  # @spec graph(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # List edge definitions

  # GET /_api/gharial/{graph-name}/edge
  # """
  # @spec graph_edges(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edges(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Add edge definition

  # POST /_api/gharial/{graph-name}/edge
  # """
  # @spec graph_edge_define(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_define(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Create an edge

  # POST /_api/gharial/{graph-name}/edge/{collection-name}
  # """
  # @spec graph_edge_create(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_create(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Remove an edge

  # DELETE /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  # """
  # @spec graph_edge_delete(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_delete(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Get an edge

  # GET /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  # """
  # @spec graph_edge(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Modify an edge

  # PATCH /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  # """
  # @spec graph_edge_update(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_update(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Replace an edge

  # PUT /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key}
  # """
  # @spec graph_edge_replace(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_replace(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Remove an edge definition from the graph

  # DELETE /_api/gharial/{graph-name}/edge/{definition-name}
  # """
  # @spec graph_edge_delete(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_delete(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Replace an edge definition

  # PUT /_api/gharial/{graph-name}/edge/{definition-name}
  # """
  # @spec graph_edge_definition_replace(Endpoint.t) :: Arangoex.ok_error(map)
  # def graph_edge_definition_replace(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # List vertex collections

  # GET /_api/gharial/{graph-name}/vertex
  # """
  # @spec vertexes(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertexes(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Add vertex collection

  # POST /_api/gharial/{graph-name}/vertex
  # """
  # @spec vertexes_add(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertexes_add(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Remove vertex collection

  # DELETE /_api/gharial/{graph-name}/vertex/{collection-name}
  # """
  # @spec vertexes_delete(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertexes_delete(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Create a vertex

  # POST /_api/gharial/{graph-name}/vertex/{collection-name}
  # """
  # @spec vertex_create(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertex_create(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Remove a vertex

  # DELETE /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  # """
  # @spec vertex_delete(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertex_delete(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Get a vertex

  # GET /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  # """
  # @spec vertex(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertex(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Modify a vertex

  # PATCH /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  # """
  # @spec vertex_update(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertex_update(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Replace a vertex

  # PUT /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key}
  # """
  # @spec vertex_replace(Endpoint.t) :: Arangoex.ok_error(map)
  # def vertex_replace(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end
end
