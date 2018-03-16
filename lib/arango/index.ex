defmodule Arango.Index do
  @moduledoc "ArangoDB Index methods"

  alias Arango.Request
  alias Arango.Utils

  @doc """
  Read index

  GET /_api/index/{index-handle}
  """
  @spec index(String.t) :: Arango.ok_error(map)
  def index(index_handle) do
    %Request{
      endpoint: :index,
      http_method: :get,
      path: "index/#{index_handle}",
    }
  end

  @doc """
  Read all indexes of a collection

  GET /_api/index
  """
  @spec indexes(String.t) :: Arango.ok_error(map)
  def indexes(collection_name) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    %Request{
      endpoint: :index,
      http_method: :get,
      path: "index",
      query: query,
    }
  end

  @doc """
  Create fulltext index

  POST /_api/index#fulltext
  """
  @spec create_fulltext(String.t, String.t, keyword) :: Arango.ok_error(map)
  def create_fulltext(collection_name, field_name, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:minLength])
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body = %{
      "type" => "fulltext",
      "fields" => [field_name],
      "minLength" => properties["minLength"] || 0
    }

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Create index

  POST /_api/index#general
  """
  @spec create_general(String.t, map) :: Arango.ok_error(map)
  def create_general(collection_name, body) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Create geo-spatial index

  POST /_api/index#geo
  """
  @spec create_geo(String.t, [String.t], keyword) :: Arango.ok_error(map)
  def create_geo(collection_name, field_names, opts \\ []) when is_list(field_names) do
    properties = Utils.opts_to_vars(opts, [:geoJson])
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body = %{
      "type" => "geo",
      "fields" => field_names,
      "geoJson" => properties["geoJson"] || false
    }

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Create hash index

  POST /_api/index#hash
  """
  @spec create_hash(String.t, [String.t], keyword) :: Arango.ok_error(map)
  def create_hash(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "hash", "fields" => field_names})

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Create a persistent index

  POST /_api/index#persistent
  """
  @spec create_persistent(String.t, [String.t], keyword) :: Arango.ok_error(map)
  def create_persistent(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "persistent", "fields" => field_names})

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Create skip list

  POST /_api/index#skiplist
  """
  @spec create_skiplist(String.t, [String.t], keyword) :: Arango.ok_error(map)
  def create_skiplist(collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "skiplist", "fields" => field_names})

    %Request{
      endpoint: :index,
      http_method: :post,
      path: "index/",
      query: query,
      body: body,
    }
  end

  @doc """
  Delete index

  DELETE /_api/index/{index-handle}
  """
  @spec delete(String.t) :: Arango.ok_error(map)
  def delete(index_handle) do
    %Request{
      endpoint: :index,
      http_method: :delete,
      path: "index/#{index_handle}",
    }
  end
end
