defmodule Arangoex.Administration do
  @moduledoc "ArangoDB Administration methods"

  alias Arangoex.Request
  alias Arangoex.Utils

  @doc """
  Return the required version of the database

  GET /_admin/database/target-version
  """
  @spec database_version() :: Arangoex.ok_error(map)
  def database_version() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/database/target-version"
    }
  end

  @doc """
  Return current request

  GET /_admin/echo
  """
  @spec echo(keyword, keyword) :: Arangoex.ok_error(map)
  def echo(query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    %Request{
      endpoint: :administration,
      http_method: :get,
      headers: headers,
      path: "/_admin/echo",
      query: query
    }
  end

  @doc """
  Execute program

  POST /_admin/execute
  """
  @spec execute(String.t, keyword) :: Arangoex.ok_error(map)
  def execute(code, opts \\ []) do
    query = Utils.opts_to_query(opts, [:returnAsJson])

    %Request{
      endpoint: :administration,
      http_method: :post,
      body: code,
      path: "/_admin/execute",
      query: query,
      encode_body: false
    }
  end

  @doc """
  Read global logs from the server

  GET /_admin/log
  """
  @spec log() :: Arangoex.ok_error(map)
  def log(opts \\ []) do
    query = Utils.opts_to_query(opts, [:upto, :level, :start, :size, :offset, :search, :sort])

    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/log",
      query: query,
    }
  end

  @doc """
  Return current request and continues

  GET /_admin/long_echo
  """
  @spec long_echo() :: Arangoex.ok_error(map)
  def long_echo(query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    %Request{
      endpoint: :administration,
      http_method: :get,
      headers: headers,
      path: "/_admin/long_echo",
      query: query,
    }
  end

  @doc """
  Reloads the routing information

  POST /_admin/routing/reload
  """
  @spec reload_routing() :: Arangoex.ok_error(map)
  def reload_routing() do
    %Request{
      endpoint: :administration,
      http_method: :post,
      path: "/_admin/routing/reload"
    }
  end

  @doc """
  Return id of a server in a cluster

  GET /_admin/server/id
  """
  @spec server_id() :: Arangoex.ok_error(map)
  def server_id() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/server/id"
    }
  end

  @doc """
  Return role of a server in a cluster

  GET /_admin/server/role
  """
  @spec server_role() :: Arangoex.ok_error(map)
  def server_role() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/server/role"
    }
  end

  @doc """
  Initiate shutdown sequence

  DELETE /_admin/shutdown
  """
  @spec shutdown() :: Arangoex.ok_error(map)
  def shutdown() do
    %Request{
      endpoint: :administration,
      http_method: :delete,
      path: "/_admin/shutdown"
    }
  end

  @doc """
  Sleep for a specified amount of seconds

  GET /_admin/sleep
  """
  @spec sleep(keyword) :: Arangoex.ok_error(map)
  def sleep(opts \\ []) do
    query = Utils.opts_to_query(opts, [:duration])

    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/sleep",
      query: query,
    }
  end

  @doc """
  Read the statistics

  GET /_admin/statistics
  """
  @spec statistics() :: Arangoex.ok_error(map)
  def statistics() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/statistics"
    }
  end

  @doc """
  Statistics description

  GET /_admin/statistics-description
  """
  @spec statistics_description() :: Arangoex.ok_error(map)
  def statistics_description() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/statistics-description"
    }
  end

  @doc """
  Runs tests on server

  POST /_admin/test
  """
  @spec test() :: Arangoex.ok_error(map)
  def test() do
    %Request{
      endpoint: :administration,
      http_method: :post,
      path: "/_admin/test"
    }
  end

  @doc """
  Return system time

  GET /_admin/time
  """
  @spec time() :: Arangoex.ok_error(map)
  def time() do
    %Request{
      endpoint: :administration,
      http_method: :get,
      path: "/_admin/time"
    }
  end

  @doc """
  Return list of all endpoints

  GET /_api/endpoint
  """
  @spec endpoints() :: Arangoex.ok_error(map)
  def endpoints() do
    %Request{
      endpoint: :administration,
      system_only: true,           # or just /_api? Same thing?
      http_method: :get,
      path: "endpoint"
    }
  end

  @doc """
  Return server version

  GET /_api/version
  """
  @spec version() :: Arangoex.ok_error(map)
  def version() do
    %Request{
      endpoint: :administration,
      system_only: true,           # or just /_api? Same thing?
      http_method: :get,
      path: "version"
    }
  end
end
