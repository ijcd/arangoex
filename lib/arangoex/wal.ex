defmodule Arangoex.Wal do
  @moduledoc "ArangoDB Wal methods"

  alias Arangoex.Endpoint

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
    historicLogfiles: pos_integer,
    reserveLogfiles: pos_integer,
    syncInterval: pos_integer,
    throttleWait: pos_integer,
    throttleWhenPending: non_neg_integer,
  }
    
  @doc """
  Flushes the write-ahead log
  """
  @spec flush(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def flush(endpoint, opts \\ []) do
    flush_opts = Endpoint.opts_with_defaults(opts, [waitForSync: nil, waitForCollector: nil])
    
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.put("/_admin/wal/flush", flush_opts)
  end
  
  @doc """  
  Retrieves the configuration of the write-ahead log  
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
  """
  @spec set_properties(Endpoint.t, t | keyword) :: Arangoex.ok_error(t)
  def set_properties(endpoint, %__MODULE__{} = properties), do: set_properties(endpoint, properties |> Map.from_struct |> Enum.into([]))
  def set_properties(endpoint, properties) do
    defaults = %__MODULE__{} |> Map.from_struct |> Enum.into([])
    wal_properties = Endpoint.opts_with_defaults(properties, defaults)
    
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.put("/_admin/wal/properties", wal_properties)
    |> to_wal
  end  

  @doc """
  Returns information about the currently running transactions
  """
  @spec transactions(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def transactions(endpoint, opts \\ []) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("/_admin/wal/transactions")
  end

  @spec to_wal(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())  
  defp to_wal({:ok, result}), do: {:ok, new(result)}
end
