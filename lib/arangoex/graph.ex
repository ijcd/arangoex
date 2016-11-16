defmodule Arangoex.Graph do
  @moduledoc "ArangoDB Graph methods"

  # GET /_api/gharial List all graphs
  # POST /_api/gharial Create a graph
  # DELETE /_api/gharial/{graph-name} Drop a graph
  # GET /_api/gharial/{graph-name} Get a graph
  # GET /_api/gharial/{graph-name}/edge List edge definitions
  # POST /_api/gharial/{graph-name}/edge Add edge definition
  # POST /_api/gharial/{graph-name}/edge/{collection-name} Create an edge
  # DELETE /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key} Remove an edge
  # GET /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key} Get an edge
  # PATCH /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key} Modify an edge
  # PUT /_api/gharial/{graph-name}/edge/{collection-name}/{edge-key} Replace an edge
  # DELETE /_api/gharial/{graph-name}/edge/{definition-name} Remove an edge definition from the graph
  # PUT /_api/gharial/{graph-name}/edge/{definition-name} Replace an edge definition
  # GET /_api/gharial/{graph-name}/vertex List vertex collections
  # POST /_api/gharial/{graph-name}/vertex Add vertex collection
  # DELETE /_api/gharial/{graph-name}/vertex/{collection-name} Remove vertex collection
  # POST /_api/gharial/{graph-name}/vertex/{collection-name} Create a vertex
  # DELETE /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key} Remove a vertex
  # GET /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key} Get a vertex
  # PATCH /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key} Modify a vertex
  # PUT /_api/gharial/{graph-name}/vertex/{collection-name}/{vertex-key} Replace a vertex
end
