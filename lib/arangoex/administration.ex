defmodule Arangoex.Administration do
  @moduledoc "ArangoDB Administration methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils

  @doc """
  Return the required version of the database

  GET /_admin/database/target-version
  """
  @spec database_version(Endpoint.t) :: Arangoex.ok_error(map)
  def database_version(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/database/target-version")
  end

  @doc """
  Return current request

  GET /_admin/echo
  """
  @spec echo(Endpoint.t) :: Arangoex.ok_error(map)
  def echo(endpoint, query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/echo#{query}", headers)
  end

  @doc """
  Execute program

  POST /_admin/execute
  """
  @spec execute(Endpoint.t, String.t, keyword) :: Arangoex.ok_error(map)
  def execute(endpoint, code, opts \\ []) do
    query = Utils.opts_to_query(opts, [:returnAsJson])

    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.post_raw("/_admin/execute#{query}", code)
  end

  @doc """
  Read global logs from the server

  GET /_admin/log
  """
  @spec log(Endpoint.t) :: Arangoex.ok_error(map)
  def log(endpoint, opts \\ []) do
    query = Utils.opts_to_query(opts, [:upto, :level, :start, :size, :offset, :search, :sort])

    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/log#{query}")
  end

  @doc """
  Return current request and continues

  GET /_admin/long_echo
  """
  @spec long_echo(Endpoint.t) :: Arangoex.ok_error(map)
  def long_echo(endpoint, query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/long_echo#{query}", headers)
  end

  @doc """
  Reloads the routing information

  POST /_admin/routing/reload
  """
  @spec reload_routing(Endpoint.t) :: Arangoex.ok_error(map)
  def reload_routing(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.post("/_admin/routing/reload")
  end

  @doc """
  Return id of a server in a cluster

  GET /_admin/server/id
  """
  @spec server_id(Endpoint.t) :: Arangoex.ok_error(map)
  def server_id(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/server/id")
  end

  @doc """
  Return role of a server in a cluster

  GET /_admin/server/role
  """
  @spec server_role(Endpoint.t) :: Arangoex.ok_error(map)
  def server_role(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/server/role")
  end

  @doc """
  Initiate shutdown sequence

  DELETE /_admin/shutdown
  """
  @spec shutdown(Endpoint.t) :: Arangoex.ok_error(map)
  def shutdown(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.delete("/_admin/shutdown")
  end

  @doc """
  Sleep for a specified amount of seconds

  GET /_admin/sleep
  """
  @spec sleep(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def sleep(endpoint, opts \\ []) do
    query = Utils.opts_to_query(opts, [:duration])

    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/sleep#{query}")
  end

  @doc """
  Read the statistics

  GET /_admin/statistics
  """
  @spec statistics(Endpoint.t) :: Arangoex.ok_error(map)
  def statistics(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/statistics")
  end

  @doc """
  Statistics description

  GET /_admin/statistics-description
  """
  @spec statistics_description(Endpoint.t) :: Arangoex.ok_error(map)
  def statistics_description(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/statistics-description")
  end

  @doc """
  Runs tests on server

  POST /_admin/test
  """
  @spec test(Endpoint.t) :: Arangoex.ok_error(map)
  def test(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.post("/_admin/test")
  end

  @doc """
  Return system time

  GET /_admin/time
  """
  @spec time(Endpoint.t) :: Arangoex.ok_error(map)
  def time(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/time")
  end

  @doc """
  Return list of all endpoints

  GET /_api/endpoint
  """
  @spec endpoints(Endpoint.t) :: Arangoex.ok_error(map)
  def endpoints(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("endpoint")
  end

  @doc """
  Return server version

  GET /_api/version
  """
  @spec version(Endpoint.t) :: Arangoex.ok_error(map)
  def version(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("version")
  end
end
