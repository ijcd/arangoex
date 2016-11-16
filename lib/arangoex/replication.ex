defmodule Arangoex.Replication do
  @moduledoc "ArangoDB Replication methods"

  # GET /_api/replication/applier-config Return configuration of replication applier
  # PUT /_api/replication/applier-config Adjust configuration of replication applier
  # PUT /_api/replication/applier-start Start replication applier
  # GET /_api/replication/applier-state State of the replication applier
  # PUT /_api/replication/applier-stop Stop replication applier
  # POST /_api/replication/batch Create new dump batch
  # DELETE /_api/replication/batch/{id} Deletes an existing dump batch
  # PUT /_api/replication/batch/{id} Prolong existing dump batch
  # GET /_api/replication/clusterInventory Return cluster inventory of collections and indexes
  # GET /_api/replication/dump Return data of a collection
  # GET /_api/replication/inventory Return inventory of collections and indexes
  # GET /_api/replication/logger-first-tick Returns the first available tick value
  # GET /_api/replication/logger-follow Returns log entries
  # GET /_api/replication/logger-state Return replication logger state
  # GET /_api/replication/logger-tick-ranges Return the tick ranges available in the WAL logfiles
  # PUT /_api/replication/make-slave Turn the server into a slave of another
  # GET /_api/replication/server-id Return server id
  # PUT /_api/replication/sync Synchronize data from a remote endpoint
end
