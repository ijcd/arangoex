defmodule Arango.Wal do
  @moduledoc "ArangoDB Wal methods (3.12 surface — RocksDB)"

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
end
