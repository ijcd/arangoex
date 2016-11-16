defmodule Arangoex.Aql do
  @moduledoc "ArangoDB AQL methods"
  
  # GET /_api/aqlfunction Return registered AQL user functions
  # POST /_api/aqlfunction Create AQL user function
  # DELETE /_api/aqlfunction/{name} Remove existing AQL user function
  # POST /_api/explain Explain an AQL query
  # POST /_api/query Parse an AQL query
  # DELETE /_api/query-cache Clears any results in the AQL query cache
  # GET /_api/query-cache/properties Returns the global properties for the AQL query cache
  # PUT /_api/query-cache/properties Globally adjusts the AQL query result cache properties
  # GET /_api/query/current Returns the currently running AQL queries
  # GET /_api/query/properties Returns the properties for the AQL query tracking
  # PUT /_api/query/properties Changes the properties for the AQL query tracking
  # DELETE /_api/query/slow Clears the list of slow AQL queries
  # GET /_api/query/slow Returns the list of slow AQL queries
  # DELETE /_api/query/{query-id} Kills a running AQL query
end
