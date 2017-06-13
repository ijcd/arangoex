defmodule Arangoex.Index do
  @moduledoc "ArangoDB Index methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils

  @doc """
  Read index

  GET /_api/index/{index-handle}
  """
  @spec index(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def index(endpoint, index_handle) do
    endpoint
    |> Endpoint.get("index/#{index_handle}")
  end

  @doc """
  Read all indexes of a collection

  GET /_api/index
  """
  @spec indexes(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def indexes(endpoint, collection_name) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    endpoint
    |> Endpoint.get("index#{query}")
  end

  @doc """
  Create fulltext index

  POST /_api/index#fulltext
  """
  @spec create_fulltext(Endpoint.t, String.t, String.t, keyword) :: Arangoex.ok_error(map)
  def create_fulltext(endpoint, collection_name, field_name, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:minLength])
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body = %{
      "type" => "fulltext",
      "fields" => [field_name],
      "minLength" => properties["minLength"] || 0
    }

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Create index

  POST /_api/index#general
  """
  @spec create_general(Endpoint.t, String.t, map) :: Arangoex.ok_error(map)
  def create_general(endpoint, collection_name, body) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Create geo-spatial index

  POST /_api/index#geo
  """
  @spec create_geo(Endpoint.t, String.t, [String.t], keyword) :: Arangoex.ok_error(map)
  def create_geo(endpoint, collection_name, field_names, opts \\ []) when is_list(field_names) do
    properties = Utils.opts_to_vars(opts, [:geoJson])
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body = %{
      "type" => "geo",
      "fields" => field_names,
      "geoJson" => properties["geoJson"] || false
    }

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Create hash index

  POST /_api/index#hash
  """
  @spec create_hash(Endpoint.t, String.t, [String.t], keyword) :: Arangoex.ok_error(map)
  def create_hash(endpoint, collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "hash", "fields" => field_names})

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Create a persistent index

  POST /_api/index#persistent
  """
  @spec create_persistent(Endpoint.t, String.t, [String.t], keyword) :: Arangoex.ok_error(map)
  def create_persistent(endpoint, collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "persistent", "fields" => field_names})

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Create skip list

  POST /_api/index#skiplist
  """
  @spec create_skiplist(Endpoint.t, String.t, [String.t], keyword) :: Arangoex.ok_error(map)
  def create_skiplist(endpoint, collection_name, field_names, opts \\ []) when is_list(field_names) do
    query = Utils.opts_to_query([collection: collection_name], [:collection])
    body =
      opts
      |> Utils.opts_to_vars([:unique, :sparse])
      |> Map.merge(%{"type" => "skiplist", "fields" => field_names})

    endpoint
    |> Endpoint.post("index#{query}", body)
  end

  @doc """
  Delete index

  DELETE /_api/index/{index-handle}
  """
  @spec delete(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def delete(endpoint, index_handle) do
    endpoint
    |> Endpoint.delete("index/#{index_handle}")
  end
end
