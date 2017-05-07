defmodule Arangoex.Wal do
  @moduledoc "ArangoDB Wal methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils  

  defstruct [
    :allowOversizeEntries,
    :logfileSize,
    :historicLogfiles,
    :reserveLogfiles,
    :syncInterval,
    :throttleWait,
    :throttleWhenPending,
  ]
  use ExConstructor

  @type t :: %__MODULE__{
    allowOversizeEntries: boolean,
    logfileSize: pos_integer,
    historicLogfiles: non_neg_integer,
    reserveLogfiles: non_neg_integer,
    syncInterval: pos_integer,
    throttleWait: pos_integer,
    throttleWhenPending: non_neg_integer,
  }

  @doc """
  Flushes the write-ahead log

  PUT /_admin/wal/flush
  """
  @spec flush(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def flush(endpoint, opts \\ []) do
    flush_opts = Utils.opts_to_vars(opts, [:waitForSync, :waitForCollector])
    
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.put("/_admin/wal/flush", flush_opts)
  end
  
  @doc """  
  Retrieves the configuration of the write-ahead log  

  GET /_admin/wal/properties
  """
  @spec properties(Endpoint.t) :: Arangoex.ok_error(t)
  def properties(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/wal/properties")
    |> to_wal
  end  

  @doc """
  Configures the write-ahead log

  PUT /_admin/wal/properties
  """
  @spec set_properties(Endpoint.t, t | keyword) :: Arangoex.ok_error(t)
  def set_properties(endpoint, %__MODULE__{} = properties), do: set_properties(endpoint, properties |> Map.from_struct |> Enum.into([]))
  def set_properties(endpoint, properties) do
    defaults = %__MODULE__{} |> Map.from_struct |> Map.keys
    wal_properties = Utils.opts_to_vars(properties, defaults)
    
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.put("/_admin/wal/properties", wal_properties)
    |> to_wal
  end  

  @doc """
  Returns information about the currently running transactions

  GET /_admin/wal/transactions
  """
  @spec transactions(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def transactions(endpoint, opts \\ []) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/wal/transactions")
  end

  @spec to_wal(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())  
  defp to_wal({:ok, result}), do: {:ok, new(result)}
  defp to_wal({:error, _} = e), do: e
end
