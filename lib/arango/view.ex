defmodule Arango.View do
  @moduledoc """
  ArangoDB Views — ArangoSearch (`type: "arangosearch"`) and search-alias
  (`type: "search-alias"`).

  ArangoSearch views are server-managed: link collections + analyzer
  pipelines, the server builds and maintains the inverted indexes.
  Search-alias views are a thin facade over pre-existing inverted
  indexes (built with `Arango.Index.create_inverted/3`); the user owns
  the indexes, the view is the queryable surface.

  Note: `replace_properties/2` (PUT) is ArangoSearch-only; search-alias
  views accept PATCH only.
  """

  use Arango.API, endpoint: :view

  @doc """
  List all views.

  GET /_api/view
  """
  @spec views() :: Arango.Request.t()
  def views() do
    request(method: :get, path: "view")
  end

  @doc """
  Return a view summary (id, name, type, globallyUniqueId).

  GET /_api/view/{name}
  """
  @spec view(String.t()) :: Arango.Request.t()
  def view(name) do
    request(method: :get, path: "view/#{name}")
  end

  @doc """
  Return the full properties block of a view.

  GET /_api/view/{name}/properties
  """
  @spec properties(String.t()) :: Arango.Request.t()
  def properties(name) do
    request(method: :get, path: "view/#{name}/properties")
  end

  @doc """
  Create an ArangoSearch view.

  POST /_api/view

  Whitelisted opts: `:links`, `:primarySort`, `:primarySortCompression`,
  `:primarySortCache`, `:primaryKeyCache`, `:storedValues`,
  `:consolidationIntervalMsec`, `:consolidationPolicy`,
  `:commitIntervalMsec`, `:cleanupIntervalStep`, `:optimizeTopK`,
  `:writebufferActive`, `:writebufferIdle`, `:writebufferSizeMax`.
  Nested structures (`links`, `consolidationPolicy`) are passed as
  raw maps.
  """
  @spec create_arangosearch(String.t(), keyword) :: Arango.Request.t()
  def create_arangosearch(name, opts \\ []) do
    body =
      opts
      |> Utils.opts_to_vars([
        :links,
        :primarySort,
        :primarySortCompression,
        :primarySortCache,
        :primaryKeyCache,
        :storedValues,
        :consolidationIntervalMsec,
        :consolidationPolicy,
        :commitIntervalMsec,
        :cleanupIntervalStep,
        :optimizeTopK,
        :writebufferActive,
        :writebufferIdle,
        :writebufferSizeMax
      ])
      |> Map.merge(%{"name" => name, "type" => "arangosearch"})

    request(method: :post, path: "view", body: body)
  end

  @doc """
  Create a search-alias view over pre-existing inverted indexes.

  POST /_api/view

  `indexes` is a list of `%{"collection" => name, "index" => index_name}`.
  Build the underlying inverted indexes first with
  `Arango.Index.create_inverted/3` and pass them an explicit `name:` opt
  so you can reference them here.

  Note: the server resolves search-alias indexes by **name only** — passing
  a full `collection/id` path returns `errorNum: 10 "Cannot find index"`.
  """
  @spec create_search_alias(String.t(), [map]) :: Arango.Request.t()
  def create_search_alias(name, indexes) when is_list(indexes) do
    body = %{"name" => name, "type" => "search-alias", "indexes" => indexes}
    request(method: :post, path: "view", body: body)
  end

  @doc """
  Drop a view.

  DELETE /_api/view/{name}
  """
  @spec drop(String.t()) :: Arango.Request.t()
  def drop(name) do
    request(method: :delete, path: "view/#{name}")
  end

  @doc """
  Patch a view's properties (works on both view types).

  PATCH /_api/view/{name}/properties
  """
  @spec update_properties(String.t(), map) :: Arango.Request.t()
  def update_properties(name, properties) do
    request(method: :patch, path: "view/#{name}/properties", body: properties)
  end

  @doc """
  Replace a view's properties (ArangoSearch only — search-alias accepts
  PATCH only).

  PUT /_api/view/{name}/properties
  """
  @spec replace_properties(String.t(), map) :: Arango.Request.t()
  def replace_properties(name, properties) do
    request(method: :put, path: "view/#{name}/properties", body: properties)
  end

  @doc """
  Rename a view.

  PUT /_api/view/{name}/rename

  Single-server only — cluster deployments return 501.
  """
  @spec rename(String.t(), String.t()) :: Arango.Request.t()
  def rename(name, new_name) do
    request(method: :put, path: "view/#{name}/rename", body: %{name: new_name})
  end
end
