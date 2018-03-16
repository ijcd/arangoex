defmodule Arango.Cluster do
  # @moduledoc "ArangoDB Cluster methods"

  # alias Arango.Endpoint

  # @doc """
  # Delete cluster roundtrip

  # DELETE /_admin/cluster-test
  # """
  # @spec delete_roundtrip(Endpoint.t) :: Arango.ok_error(map)
  # def delete_roundtrip(endpoint) do
  #   endpoint
  #   |> Endpoint.delete("/_admin/cluster-test")
  # end

  # @doc """
  # Execute cluster roundtrip

  # GET /_admin/cluster-test
  # HEAD /_admin/cluster-test
  # POST /_admin/cluster-test
  # PUT /_admin/cluster-test
  # """
  # @spec execute_roundtrip(Endpoint.t, :get | :head | :post | :put) :: Arango.ok_error(map)
  # def execute_roundtrip(endpoint), do: Endpoint.get(endpoint, "/_admin/cluster-test")
  # def execute_roundtrip(endpoint, :head), do: Endpoint.head(endpoint, "/_admin/cluster-test")
  # def execute_roundtrip(endpoint, :post), do: Endpoint.post(endpoint, "/_admin/cluster-test")
  # def execute_roundtrip(endpoint, :put), do: Endpoint.put(endpoint, "/_admin/cluster-test")

  # @doc """
  # Update cluster roundtrip

  # PATCH /_admin/cluster-test
  # """
  # @spec update_roundtrip(Endpoint.t) :: Arango.ok_error(map)
  # def update_roundtrip(endpoint) do
  #   endpoint
  #   |> Endpoint.patch("/_admin/cluster-test")
  # end

  # @doc """
  # Check port

  # GET /_admin/clusterCheckPort
  # """
  # @spec check_port(Endpoint.t) :: Arango.ok_error(map)
  # def check_port(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_admin/clusterCheckPort")
  # end

  # @doc """
  # Queries statistics of DBserver

  # GET /_admin/clusterStatistics
  # """
  # @spec statistics(Endpoint.t) :: Arango.ok_error(map)
  # def statistics(endpoint) do
  #   endpoint
  #   |> Endpoint.get("/_admin/clusterStatistics")
  # end
end
