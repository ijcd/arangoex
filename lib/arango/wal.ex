defmodule Arango.Wal do
  @moduledoc "ArangoDB WAL methods (3.12 surface — RocksDB)"

  use Arango.API, endpoint: :wal

  @doc """
  Flushes the write-ahead log.

  PUT /_admin/wal/flush
  """
  @spec flush(keyword) :: Arango.Request.t()
  def flush(opts \\ []) do
    flush_opts = Utils.opts_to_vars(opts, [:waitForSync, :waitForCollector])

    request(
      method: :put,
      system_only: true,
      path: "/_admin/wal/flush",
      body: flush_opts
    )
  end

  @doc """
  Return the current WAL tick.

  GET /_api/wal/lastTick
  """
  @spec last_tick() :: Arango.Request.t()
  def last_tick() do
    request(method: :get, system_only: true, path: "/_api/wal/lastTick")
  end

  @doc """
  Return the WAL tick range available (min and max).

  GET /_api/wal/range
  """
  @spec range() :: Arango.Request.t()
  def range() do
    request(method: :get, system_only: true, path: "/_api/wal/range")
  end

  @doc """
  Stream WAL operations from the requested tick onward.

  GET /_api/wal/tail

  Options: `:global`, `:from`, `:to`, `:lastScanned`, `:chunkSize`,
  `:syncerId`, `:serverId`, `:clientInfo`.

  The server returns NDJSON without a `Content-Type` header — the
  driver passes the body through as a raw string. Split on `"\\n"` and
  decode each line with `Jason.decode!/1` to consume.
  """
  @spec tail(keyword) :: Arango.Request.t()
  def tail(opts \\ []) do
    query =
      Utils.opts_to_query(opts, [
        :global,
        :from,
        :to,
        :lastScanned,
        :chunkSize,
        :syncerId,
        :serverId,
        :clientInfo
      ])

    request(
      method: :get,
      system_only: true,
      path: "/_api/wal/tail",
      query: query
    )
  end
end
