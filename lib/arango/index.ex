defmodule Arango.Index do
  @moduledoc "ArangoDB Index methods"

  use Arango.API, endpoint: :index

  @doc """
  Read index

  GET /_api/index/{index-handle}
  """
  @spec index(String.t()) :: Arango.ok_error(map)
  def index(index_handle) do
    request(method: :get, path: "index/#{index_handle}")
  end

  @doc """
  Read all indexes of a collection

  GET /_api/index
  """
  @spec indexes(String.t()) :: Arango.ok_error(map)
  def indexes(collection_name) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    request(method: :get, path: "index", query: query)
  end

  @doc """
  Create fulltext index

  POST /_api/index#fulltext
  """
  @spec create_fulltext(String.t(), String.t(), keyword) :: Arango.ok_error(map)
  def create_fulltext(collection_name, field_name, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:minLength])
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body = %{
      "type" => "fulltext",
      "fields" => [field_name],
      "minLength" => properties["minLength"] || 0
    }

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create index

  POST /_api/index#general
  """
  @spec create_general(String.t(), map) :: Arango.ok_error(map)
  def create_general(collection_name, body) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create geo-spatial index

  POST /_api/index#geo
  """
  @spec create_geo(String.t(), [String.t()], keyword) :: Arango.ok_error(map)
  def create_geo(collection_name, field_names, opts \\ []) when is_list(field_names) do
    properties = Utils.opts_to_vars(opts, [:geoJson])
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body = %{
      "type" => "geo",
      "fields" => field_names,
      "geoJson" => properties["geoJson"] || false
    }

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create hash index

  POST /_api/index#hash
  """
  @deprecated "Use Index.create_persistent/3. Hash indexes are unified into persistent in 3.12 and removed in v1/4.0."
  @spec create_hash(String.t(), [String.t()], keyword) :: Arango.ok_error(map)
  def create_hash(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "hash", "fields" => field_names})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create a persistent index

  POST /_api/index#persistent
  """
  @spec create_persistent(String.t(), [String.t()], keyword) :: Arango.ok_error(map)
  def create_persistent(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "persistent", "fields" => field_names})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create skip list

  POST /_api/index#skiplist
  """
  @deprecated "Use Index.create_persistent/3. Skiplist indexes are unified into persistent in 3.12 and removed in v1/4.0."
  @spec create_skiplist(String.t(), [String.t()], keyword) :: Arango.ok_error(map)
  def create_skiplist(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "skiplist", "fields" => field_names})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create inverted index (ArangoSearch)

  POST /_api/index#inverted

  `fields` is a list of either bare field names (`["foo", "bar"]`) or
  per-field option maps (`[%{"name" => "foo", "analyzer" => "text_en"}]`).
  """
  @spec create_inverted(String.t(), [String.t() | map], keyword) :: Arango.ok_error(map)
  def create_inverted(collection_name, fields, opts \\ []) when is_list(fields) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([
        :name,
        :analyzer,
        :features,
        :includeAllFields,
        :searchField,
        :trackListPositions,
        :parallelism,
        :consolidationIntervalMsec,
        :commitIntervalMsec,
        :cleanupIntervalStep,
        :primarySort,
        :storedValues,
        :inBackground,
        :cache,
        :primaryKeyCache,
        :optimizeTopK,
        :writebufferActive,
        :writebufferIdle,
        :writebufferSizeMax,
        :consolidationPolicy
      ])
      |> Map.merge(%{"type" => "inverted", "fields" => fields})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create TTL (time-to-live) index

  POST /_api/index#ttl

  `expire_after` is in seconds. Documents whose `field` is more than
  `expire_after` seconds older than now become eligible for removal.
  """
  @spec create_ttl(String.t(), String.t(), integer, keyword) :: Arango.ok_error(map)
  def create_ttl(collection_name, field, expire_after, opts \\ []) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([:name, :inBackground])
      |> Map.merge(%{"type" => "ttl", "fields" => [field], "expireAfter" => expire_after})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create multi-dimensional index (replaces zkd in 3.12)

  POST /_api/index#mdi

  `field_value_types` is currently only `"double"`.
  """
  @spec create_mdi(String.t(), [String.t()], String.t(), keyword) :: Arango.ok_error(map)
  def create_mdi(collection_name, fields, field_value_types, opts \\ []) when is_list(fields) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([
        :name,
        :unique,
        :sparse,
        :storedValues,
        :inBackground,
        :estimates,
        :prefixFields
      ])
      |> Map.merge(%{"type" => "mdi", "fields" => fields, "fieldValueTypes" => field_value_types})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Create vector index

  POST /_api/index#vector

  `params` is a required map; ArangoDB requires `metric` (`"l2"` or
  `"cosine"`), `dimension` (positive integer), and `nLists` (positive integer).
  Requires a build with vector index support and sufficient training data
  in the collection before creation.
  """
  @spec create_vector(String.t(), String.t(), map, keyword) :: Arango.ok_error(map)
  def create_vector(collection_name, field, params, opts \\ []) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    body =
      opts
      |> Utils.opts_to_vars([:name, :inBackground, :storedValues, :parallelism, :sparse])
      |> Map.merge(%{"type" => "vector", "fields" => [field], "params" => params})

    request(method: :post, path: "index/", query: query, body: body)
  end

  @doc """
  Delete index

  DELETE /_api/index/{index-handle}
  """
  @spec delete(String.t()) :: Arango.ok_error(map)
  def delete(index_handle) do
    request(method: :delete, path: "index/#{index_handle}")
  end
end
