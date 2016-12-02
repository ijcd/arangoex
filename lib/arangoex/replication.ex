defmodule Arangoex.Replication do
  @moduledoc "ArangoDB Replication methods"

  # @doc """
  # Return configuration of replication applier

  # GET /_api/replication/applier-config
  # """
  # @spec replication_applier_config(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_applier_config(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Adjust configuration of replication applier

  # PUT /_api/replication/applier-config
  # """
  # @spec replication_applier_config_upadte(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_applier_config_upadte(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Start replication applier

  # PUT /_api/replication/applier-start
  # """
  # @spec replication_applier_start(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_applier_start(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # State of the replication applier

  # GET /_api/replication/applier-state
  # """
  # @spec replication_applier_state(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_applier_state(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Stop replication applier

  # PUT /_api/replication/applier-stop
  # """
  # @spec replication_applier_stop(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_applier_stop(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Create new dump batch

  # POST /_api/replication/batch
  # """
  # @spec replication_batch_create(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_batch_create(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Deletes an existing dump batch

  # DELETE /_api/replication/batch/{id}
  # """
  # @spec replication_batch_delete(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_batch_delete(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Prolong existing dump batch

  # PUT /_api/replication/batch/{id}
  # """
  # @spec replication_batch_prolong(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_batch_prolong(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return cluster inventory of collections and indexes

  # GET /_api/replication/clusterInventory
  # """
  # @spec cluster_inventory(Endpoint.t) :: Arangoex.ok_error(map)
  # def cluster_inventory(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return data of a collection

  # GET /_api/replication/dump
  # """
  # @spec replication_dump(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_dump(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return inventory of collections and indexes

  # GET /_api/replication/inventory
  # """
  # @spec replication_inventory(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_inventory(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Returns the first available tick value

  # GET /_api/replication/logger-first-tick
  # """
  # @spec replication_first_tick(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_first_tick(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Returns log entries

  # GET /_api/replication/logger-follow
  # """
  # @spec replication_logger_follow(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_logger_follow(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return replication logger state

  # GET /_api/replication/logger-state
  # """
  # @spec replication_logger_state(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_logger_state(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return the tick ranges available in the WAL logfiles

  # GET /_api/replication/logger-tick-ranges
  # """
  # @spec replication_logger_tick_ranges(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_logger_tick_ranges(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Turn the server into a slave of another

  # PUT /_api/replication/make-slave
  # """
  # @spec replication_make_slave(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_make_slave(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Return server id

  # GET /_api/replication/server-id
  # """
  # @spec replication_server_id(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_server_id(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end

  # @doc """
  # Synchronize data from a remote endpoint

  # PUT /_api/replication/sync
  # """
  # @spec replication_sync(Endpoint.t) :: Arangoex.ok_error(map)
  # def replication_sync(endpoint) do
  #   endpoint
  #   |> Endpoint.get("")
  # end
end
