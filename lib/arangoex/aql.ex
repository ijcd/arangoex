defmodule Arangoex.Aql do
  @moduledoc "ArangoDB AQL methods"
  
  # @doc """
  # Return registered AQL user functions

  # GET /_api/aqlfunction
  # """
  # @spec aqlfunctions(Endpoint.t) :: Arangoex.ok_error(map)
  # def aqlfunction(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/aqlfunction")
  # end

  # @doc """
  # Create AQL user function

  # POST /_api/aqlfunction
  # """
  # @spec aqlfunction(Endpoint.t) :: Arangoex.ok_error(map)
  # def aqlfunction_create(endpoint) do
  #   endpoint
  #   |> Endpoint.post("/_api/aqlfunction")
  # end

  # @doc """
  # Remove existing AQL user function#

  # DELETE /_api/aqlfunction/{name}
  # """
  # @spec aqlfunction(Endpoint.t) :: Arangoex.ok_error(map)
  # def aqlfunction_delete(endpoint, name) do
  #   endpoint
  #   |> Endpoint.delete("/_api/aqlfunction#{name}")
  # end

  # @doc """
  # Explain an AQL query

  # POST /_api/explain
  # """
  # @spec explain(Endpoint.t) :: Arangoex.ok_error(map)
  # def explain(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/explain")
  # end

  # @doc """
  # Parse an AQL query

  # POST /_api/query
  # """
  # @spec query(Endpoint.t) :: Arangoex.ok_error(map)
  # def query(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/query")
  # end

  # @doc """
  # Clears any results in the AQL query cache

  # DELETE /_api/query-cache
  # """
  # @spec query_cache(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_cache(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/query-cache")
  # end

  # @doc """
  # Returns the global properties for the AQL query cache

  # GET /_api/query-cache/properties
  # """
  # @spec query_cache_properties(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_cache_properties(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/query-cache/properties")
  # end

  # @doc """
  # Globally adjusts the AQL query result cache properties

  # PUT /_api/query-cache/properties
  # """
  # @spec query_cache_properties(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_cache_properties(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_api/query-cache/properties")
  # end


  # @doc """
  # Returns the currently running AQL queries

  # GET /_api/query/current
  # """
  # @spec query_current(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_current(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Returns the properties for the AQL query tracking

  # GET /_api/query/properties
  # """
  # @spec query_properties(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_properties(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Changes the properties for the AQL query tracking

  # PUT /_api/query/properties
  # """
  # @spec query_properties_set(Endpoint.t) :: Arangoex.ok_error(map)
  # def query_properties_set(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Clears the list of slow AQL queries

  # DELETE /_api/query/slow
  # """
  # @spec slow_queries_reset(Endpoint.t) :: Arangoex.ok_error(map)
  # def slow_queries_reset(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Returns the list of slow AQL queries

  # GET /_api/query/slow
  # """
  # @spec slow_queries(Endpoint.t) :: Arangoex.ok_error(map)
  # def slow_queries(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Kills a running AQL query

  # DELETE /_api/query/{query-id}
  # """
  # @spec kill_query(Endpoint.t) :: Arangoex.ok_error(map)
  # def kill_query(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end
end
