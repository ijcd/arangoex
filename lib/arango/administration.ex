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

  @doc """
  Return the storage engine info (e.g. `name: "rocksdb"`).

  GET /_api/engine
  """
  @spec engine() :: Arango.ok_error(map)
  def engine() do
    request(method: :get, system_only: true, path: "engine")
  end

  @doc """
  Return engine-internal counters.

  GET /_api/engine/stats
  """
  @spec engine_stats() :: Arango.ok_error(map)
  def engine_stats() do
    request(method: :get, system_only: true, path: "engine/stats")
  end

  @doc """
  Return Prometheus-formatted server metrics.

  GET /_admin/metrics/v2

  Replaces `statistics/0` and `statistics_description/0` in v1/4.0. The
  response is `text/plain`, so the body comes through the request layer
  as a raw string — no `ok_decoder` needed.
  """
  @spec metrics() :: Arango.ok_error(String.t)
  def metrics() do
    request(method: :get, path: "/_admin/metrics/v2")
  end

  @doc """
  Return server boot / process status.

  GET /_admin/status
  """
  @spec status() :: Arango.ok_error(map)
  def status() do
    request(method: :get, path: "/_admin/status")
  end

  @doc """
  Return current server mode (`"default"` or `"readonly"`).

  GET /_admin/server/mode
  """
  @spec mode() :: Arango.ok_error(map)
  def mode() do
    request(method: :get, path: "/_admin/server/mode")
  end

  @doc """
  Set the server mode.

  PUT /_admin/server/mode

  `mode_value` is `"default"` or `"readonly"`.
  """
  @spec set_mode(String.t) :: Arango.ok_error(map)
  def set_mode(mode_value) do
    request(method: :put, path: "/_admin/server/mode", body: %{mode: mode_value})
  end

  @doc """
  Return whether the server is ready to serve requests.

  GET /_admin/server/availability
  """
  @spec availability() :: Arango.ok_error(map)
  def availability() do
    request(method: :get, path: "/_admin/server/availability")
  end

  @doc """
  Return a diagnostics bundle.

  GET /_admin/support-info
  """
  @spec support_info() :: Arango.ok_error(map)
  def support_info() do
    request(method: :get, path: "/_admin/support-info")
  end

  @doc """
  Return per-topic log levels.

  GET /_admin/log/level
  """
  @spec log_level() :: Arango.ok_error(map)
  def log_level() do
    request(method: :get, path: "/_admin/log/level")
  end

  @doc """
  Set per-topic log levels.

  PUT /_admin/log/level

  `levels` is a map of topic → level, e.g. `%{"agency" => "DEBUG"}`.
  """
  @spec set_log_level(map) :: Arango.ok_error(map)
  def set_log_level(levels) do
    request(method: :put, path: "/_admin/log/level", body: levels)
  end

  @doc """
  Return structured log entries.

  GET /_admin/log/entries

  Same filtering options as `log/1` but returns a `messages` array of
  per-entry maps instead of the legacy parallel-arrays shape.
  """
  @spec log_entries(keyword) :: Arango.ok_error(map)
  def log_entries(opts \\ []) do
    query = Utils.opts_to_query(opts, [:upto, :level, :start, :size, :offset, :search, :sort])
    request(method: :get, path: "/_admin/log/entries", query: query)
  end

  @doc """
  Compact the database.

  PUT /_admin/compact

  Options: `:changeLevel` (boolean), `:compactBottomMostLevel` (boolean).
  """
  @spec compact(keyword) :: Arango.ok_error(map)
  def compact(opts \\ []) do
    body =
      Utils.compact(%{
        "changeLevel" => Keyword.get(opts, :changeLevel),
        "compactBottomMostLevel" => Keyword.get(opts, :compactBottomMostLevel)
      })

    request(method: :put, path: "/_admin/compact", body: body)
  end
end
