defmodule Arango.Collection do
  @moduledoc "ArangoDB Collection methods"

  alias Arango.Request
  alias Arango.Utils

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
  @spec collections() :: Arango.ok_error(t)
  def collections() do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection",
      ok_decoder: __MODULE__.CollectionDecoder,
    }
  end

  @doc """
  Create collection

  POST /_api/collection
  """
  @spec create(t | String.t) :: Arango.ok_error(t)
  def create(name) when is_binary(name), do: create(%__MODULE__{name: name})
  def create(collection) do
    %Request{
      endpoint: :collection,
      http_method: :post,
      path: "collection",
      body: collection,
      ok_decoder: __MODULE__.CollectionDecoder,
    }
  end

  @doc """
  Drops collection

  DELETE /_api/collection/{collection-name}
  """
  @spec drop(t) :: Arango.ok_error(map)
  def drop(collection) do
    %Request{
      endpoint: :collection,
      http_method: :delete,
      path: "collection/#{collection.name}",
    }
  end

  @doc """
  Return information about a collection

  GET /_api/collection/{collection-name}
  """
  @spec collection(t) :: Arango.ok_error(t)
  def collection(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}",
      ok_decoder: __MODULE__.CollectionDecoder,
    }
  end

  @doc """
  Load collection

  PUT /_api/collection/{collection-name}/load
  """
  @spec load(t) :: Arango.ok_error(map)
  def load(collection, count \\ true) do
    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/load",
      body: %{count: count},
    }
  end

  @doc """
  Unload collection

  PUT /_api/collection/{collection-name}/unload
  """
  @spec unload(t) :: Arango.ok_error(map)
  def unload(collection) do
    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/unload",
    }
  end

  @doc """
  Return checksum for the collection

  GET /_api/collection/{collection-name}/checksum
  """
  @spec checksum(t) :: Arango.ok_error(map)
  def checksum(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}/checksum",
    }
  end

  @doc """
  Return number of documents in a collection

  GET /_api/collection/{collection-name}/count
  """
  @spec count(t) :: Arango.ok_error(map)
  def count(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}/count",
    }
  end

  @doc """
  Return statistics for a collection

  GET /_api/collection/{collection-name}/figures
  """
  @spec figures(t) :: Arango.ok_error(map)
  def figures(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}/figures",
    }
  end

  @doc """
  Read properties of a collection

  GET /_api/collection/{collection-name}/properties
  """
  @spec properties(t) :: Arango.ok_error(map)
  def properties(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}/properties",
    }
  end

  @doc """
  Change properties of a collection

  PUT /_api/collection/{collection-name}/properties
  """
  @spec set_properties(t, keyword) :: Arango.ok_error(map)
  def set_properties(collection, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:waitForSync, :journalSize])

    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/properties",
      body: properties,
    }
  end

  @doc """
  Rename collection

  PUT /_api/collection/{collection-name}/rename
  """
  @spec rename(t, String.t) :: Arango.ok_error(map)
  def rename(collection, new_name) do
    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/rename",
      body: %{name: new_name},
    }
  end

  @doc """
  Return collection revision id

  GET /_api/collection/{collection-name}/revision
  """
  @spec revision(t) :: Arango.ok_error(map)
  def revision(collection) do
    %Request{
      endpoint: :collection,
      http_method: :get,
      path: "collection/#{collection.name}/revision",
    }
  end

  @doc """
  Rotate journal of a collection

  PUT /_api/collection/{collection-name}/rotate
  """
  @spec rotate(t) :: Arango.ok_error(map)
  def rotate(collection) do
    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/rotate",
    }
  end

  @doc """
  Truncate collection

  PUT /_api/collection/{collection-name}/truncate
  """
  @spec truncate(t) :: Arango.ok_error(map)
  def truncate(collection) do
    %Request{
      endpoint: :collection,
      http_method: :put,
      path: "collection/#{collection.name}/truncate",
    }
  end

  defmodule CollectionDecoder do
    alias Arango.Collection

    @spec decode_ok(Map.t) :: Arango.ok_error(Collection.t)
    def decode_ok(%{"result" => result}) when is_list(result), do: {:ok, Enum.map(result, &Collection.new(&1))}
    def decode_ok(result), do: {:ok, Collection.new(result)}
  end
end
