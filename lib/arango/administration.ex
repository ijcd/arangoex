defmodule Arango.Administration do
  @moduledoc "ArangoDB Administration methods"

  use Arango.API, endpoint: :administration

  @doc """
  Return the required version of the database

  GET /_admin/database/target-version
  """
  @spec database_version() :: Arango.ok_error(map)
  def database_version() do
    request(method: :get, path: "/_admin/database/target-version")
  end

  @doc """
  Return current request

  GET /_admin/echo
  """
  @spec echo(keyword, keyword) :: Arango.ok_error(map)
  def echo(query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    request(
      method: :get,
      headers: headers,
      path: "/_admin/echo",
      query: query
    )
  end

  @doc """
  Read global logs from the server

  GET /_admin/log
  """
  @spec log() :: Arango.ok_error(map)
  def log(opts \\ []) do
    query = Utils.opts_to_query(opts, [:upto, :level, :start, :size, :offset, :search, :sort])

    request(
      method: :get,
      path: "/_admin/log",
      query: query
    )
  end

  @doc """
  Return current request and continues

  GET /_admin/long_echo
  """
  @spec long_echo() :: Arango.ok_error(map)
  def long_echo(query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    request(
      method: :get,
      headers: headers,
      path: "/_admin/long_echo",
      query: query
    )
  end

  @doc """
  Reloads the routing information

  POST /_admin/routing/reload
  """
  @deprecated "Removed in API v1/4.0; routing handled internally."
  @spec reload_routing() :: Arango.ok_error(map)
  def reload_routing() do
    request(method: :post, path: "/_admin/routing/reload")
  end

  @doc """
  Return id of a server in a cluster

  GET /_admin/server/id
  """
  @spec server_id() :: Arango.ok_error(map)
  def server_id() do
    request(method: :get, path: "/_admin/server/id")
  end

  @doc """
  Return role of a server in a cluster

  GET /_admin/server/role
  """
  @spec server_role() :: Arango.ok_error(map)
  def server_role() do
    request(method: :get, path: "/_admin/server/role")
  end

  @doc """
  Initiate shutdown sequence

  DELETE /_admin/shutdown
  """
  @spec shutdown() :: Arango.ok_error(map)
  def shutdown() do
    request(method: :delete, path: "/_admin/shutdown")
  end

  @doc """
  Sleep for a specified amount of seconds

  GET /_admin/sleep
  """
  @spec sleep(keyword) :: Arango.ok_error(map)
  def sleep(opts \\ []) do
    query = Utils.opts_to_query(opts, [:duration])

    request(
      method: :get,
      path: "/_admin/sleep",
      query: query
    )
  end

  @doc """
  Read the statistics

  GET /_admin/statistics
  """
  @deprecated "Removed in API v1/4.0. Use Administration.metrics/0 (Prometheus format) when added in Phase 4."
  @spec statistics() :: Arango.ok_error(map)
  def statistics() do
    request(method: :get, path: "/_admin/statistics")
  end

  @doc """
  Statistics description

  GET /_admin/statistics-description
  """
  @deprecated "Removed in API v1/4.0. Use Administration.metrics/0 (Prometheus format) when added in Phase 4."
  @spec statistics_description() :: Arango.ok_error(map)
  def statistics_description() do
    request(method: :get, path: "/_admin/statistics-description")
  end

  @doc """
  Runs tests on server

  POST /_admin/test
  """
  @spec test() :: Arango.ok_error(map)
  def test() do
    request(method: :post, path: "/_admin/test")
  end

  @doc """
  Return system time

  GET /_admin/time
  """
  @spec time() :: Arango.ok_error(map)
  def time() do
    request(method: :get, path: "/_admin/time")
  end

  @doc """
  Return list of all endpoints

  GET /_api/endpoint
  """
  @spec endpoints() :: Arango.ok_error(map)
  def endpoints() do
    request(
      method: :get,
      system_only: true,
      path: "endpoint"
    )
  end

  @doc """
  Return server version

  GET /_api/version
  """
  @spec version() :: Arango.ok_error(map)
  def version() do
    request(
      method: :get,
      system_only: true,
      path: "version"
    )
  end
end
