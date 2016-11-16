defmodule Arangoex.Administration do
  @moduledoc "ArangoDB Administration methods"
  
  # GET /_admin/database/target-version Return the required version of the database
  # GET /_admin/echo Return current request
  # POST /_admin/execute Execute program
  # GET /_admin/log Read global logs from the server
  # GET /_admin/long_echo Return current request and continues
  # POST /_admin/routing/reload Reloads the routing information
  # GET /_admin/server/id Return id of a server in a cluster
  # GET /_admin/server/role Return role of a server in a cluster
  # DELETE /_admin/shutdown Initiate shutdown sequence
  # GET /_admin/sleep Sleep for a specified amount of seconds
  # GET /_admin/statistics Read the statistics
  # GET /_admin/statistics-description Statistics description
  # POST /_admin/test Runs tests on server
  # GET /_admin/time Return system time
  # GET /_api/endpoint Return list of all endpoints
  # POST /_api/tasks creates a task
  # GET /_api/tasks/ Fetch all tasks or one task
  # DELETE /_api/tasks/{id} deletes the task with id
  # GET /_api/tasks/{id} Fetch one task with id
  # PUT /_api/tasks/{id} creates a task with id
  # GET /_api/version Return server version
end
