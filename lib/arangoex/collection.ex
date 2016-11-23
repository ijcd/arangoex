defmodule Arangoex.Collection do
  @moduledoc "ArangoDB Collection methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils  

  defstruct [
    id: nil,
    name: nil,
    journalSize: nil,
    replicationFactor: 1,
    keyOptions: nil,
    waitForSync: false,
    doCompact: true,
    isVolatile: false,
    shardKeys: ["_key"],
    numberOfShards: 1,
    isSystem: false,
    type: 2,
    indexBuckets: 16,
  ]
  use ExConstructor

  @type t :: %__MODULE__{
    id: nil | pos_integer(),
    name: String.t,
    journalSize: nil | pos_integer(),
    replicationFactor: nil | pos_integer(),
    keyOptions: %{
      optional(:allowUserKeys) => boolean,
      optional(:type) => String.t,
      optional(:increment) => pos_integer(),
      optional(:offset) => pos_integer(),
    },
    waitForSync: nil | boolean,
    doCompact: nil | boolean,
    isVolatile: nil | boolean,
    shardKeys: [String.t],
    numberOfShards: nil | pos_integer(),
    isSystem: nil | boolean,
    type: nil | 2 | 3,
    indexBuckets: nil | pos_integer(),
  }

  @doc """
  Reads all collections

  GET /_api/collection
  """
  @spec collections(Endpoint.t, String.t | nil) :: Arangoex.ok_error(t)
  def collections(endpoint, db \\ nil) do
    endpoint
    |> Endpoint.with_db(db || endpoint.database_name)
    |> Endpoint.get("collection")
    |> to_collection
  end

  @doc """
  Create collection

  POST /_api/collection
  """
  @spec create(Endpoint.t, t) :: Arangoex.ok_error(t)  
  def create(endpoint, coll) do
    endpoint
    |> Endpoint.post("collection", coll)
    |> to_collection
  end

  @doc """
  Drops collection

  DELETE /_api/collection/{collection-name}
  """
  @spec drop(Endpoint.t, t) :: Arangoex.ok_error(map)
  def drop(endpoint, coll) do
    endpoint
    |> Endpoint.delete("collection/#{coll.name}")
  end

  @doc """
  Return information about a collection

  GET /_api/collection/{collection-name}
  """
  @spec collection(Endpoint.t, t) :: Arangoex.ok_error(t)  
  def collection(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}")
    |> to_collection
  end

  @doc """
  Load collection

  PUT /_api/collection/{collection-name}/load
  """
  @spec load(Endpoint.t, t) :: Arangoex.ok_error(map)
  def load(endpoint, coll, count \\ true) do
    endpoint
    |> Endpoint.put("collection/#{coll.name}/load", %{count: count})
  end

  @doc """
  Unload collection

  PUT /_api/collection/{collection-name}/unload
  """
  @spec unload(Endpoint.t, t) :: Arangoex.ok_error(map)
  def unload(endpoint, coll) do
    endpoint
    |> Endpoint.put("collection/#{coll.name}/unload")
  end

  @doc """
  Return checksum for the collection


  GET /_api/collection/{collection-name}/checksum
  """
  @spec checksum(Endpoint.t, t) :: Arangoex.ok_error(map)
  def checksum(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}/checksum")
  end

  @doc """
  Return number of documents in a collection

  GET /_api/collection/{collection-name}/count
  """
  @spec count(Endpoint.t, t) :: Arangoex.ok_error(map)
  def count(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}/count")
  end

  @doc """
  Return statistics for a collection

  GET /_api/collection/{collection-name}/figures
  """
  @spec figures(Endpoint.t, t) :: Arangoex.ok_error(map)
  def figures(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}/figures")
  end

  @doc """
  Read properties of a collection

  GET /_api/collection/{collection-name}/properties
  """
  @spec properties(Endpoint.t, t) :: Arangoex.ok_error(map)
  def properties(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}/properties")
  end

  @doc """  
  Change properties of a collection

  PUT /_api/collection/{collection-name}/properties
  """
  @spec set_properties(Endpoint.t, t, keyword) :: Arangoex.ok_error(map)
  def set_properties(endpoint, coll, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:waitForSync, :journalSize])
    
    endpoint
    |> Endpoint.put("collection/#{coll.name}/properties", properties)
  end
  
  @doc """
  Rename collection

  PUT /_api/collection/{collection-name}/rename
  """
  @spec rename(Endpoint.t, t, String.t) :: Arangoex.ok_error(map)
  def rename(endpoint, coll, new_name) do
    endpoint
    |> Endpoint.put("collection/#{coll.name}/rename", %{name: new_name})
  end

  @doc """
  Return collection revision id

  GET /_api/collection/{collection-name}/revision
  """
  @spec revision(Endpoint.t, t) :: Arangoex.ok_error(map)
  def revision(endpoint, coll) do
    endpoint
    |> Endpoint.get("collection/#{coll.name}/revision")
  end

  @doc """
  Rotate journal of a collection

  PUT /_api/collection/{collection-name}/rotate
  """
  @spec rotate(Endpoint.t, t) :: Arangoex.ok_error(map)
  def rotate(endpoint, coll) do
    endpoint
    |> Endpoint.put("collection/#{coll.name}/rotate")
  end

  @doc """
  Truncate collection

  PUT /_api/collection/{collection-name}/truncate
  """
  @spec truncate(Endpoint.t, t) :: Arangoex.ok_error(map)
  def truncate(endpoint, coll) do
    endpoint
    |> Endpoint.put("collection/#{coll.name}/truncate")
  end

  @spec to_collection(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())  
  defp to_collection({:ok, %{"result" => result}}) when is_list(result), do: {:ok, Enum.map(result, &new(&1))}
  defp to_collection({:ok, result}), do: {:ok, new(result)}
  defp to_collection({:error, _} = e), do: e
end
