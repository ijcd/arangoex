defmodule Arangoex.Simple do
  @moduledoc "ArangoDB Simple methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils
  alias Arangoex.Collection

  @doc """
  Return all documents

  PUT /_api/simple/all
  """
  @spec all(Endpoint.t, Collection.t, keyword) :: Arangoex.ok_error(map)
  def all(endpoint, collection, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit])
    body = Map.merge(%{collection: collection.name}, vars)

    endpoint
    |> Endpoint.put("simple/all", body)
  end

  @doc """
  Return a random document

  PUT /_api/simple/any
  """
  @spec any(Endpoint.t, Collection.t) :: Arangoex.ok_error(map)
  def any(endpoint, collection) do
    endpoint
    |> Endpoint.put("simple/any", %{collection: collection.name})
  end

  @doc """
  Simple query by-example

  PUT /_api/simple/by-example
  """
  @spec query_by_example(Endpoint.t, Collection.t, map, keyword) :: Arangoex.ok_error(map)
  def query_by_example(endpoint, collection, example, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit])
    body = Map.merge(%{collection: collection.name, example: example}, vars)

    endpoint
    |> Endpoint.put("simple/by-example", body)
  end

  @doc """
  Find documents matching an example

  PUT /_api/simple/first-example
  """
  @spec find_by_example(Endpoint.t, Collection.t, map) :: Arangoex.ok_error(map)
  def find_by_example(endpoint, collection, example) do
    endpoint
    |> Endpoint.put("simple/first-example", %{collection: collection.name, example: example})
  end

  @doc """
  Fulltext index query

  PUT /_api/simple/fulltext
  """
  @spec query_fulltext(Endpoint.t, Collection.t, String.t, String.t, keyword) :: Arangoex.ok_error(map)
  def query_fulltext(endpoint, collection, attribute_name, query, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :index])
    body = Map.merge(%{
      "collection" => collection.name,
      "attribute" => attribute_name,     # not strictly necessary if you have :index
      "query" => query
    }, vars)

    endpoint
    |> Endpoint.put("simple/fulltext", body)
  end

  @doc """
  Find documents by their keys

  PUT /_api/simple/lookup-by-keys
  """
  @spec lookup_by_keys(Endpoint.t, Collection.t, [String.t]) :: Arangoex.ok_error(map)
  def lookup_by_keys(endpoint, collection, keys) do
    body = %{
      "collection" => collection.name,
      "keys" => keys
    }

    endpoint
    |> Endpoint.put("simple/lookup-by-keys", body)
  end

  @doc """
  Simple range query

  PUT /_api/simple/range
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec range(Endpoint.t, Collection.t, String.t, float, float, keyword) :: Arangoex.ok_error(map)
  def range(endpoint, collection, attribute_name, left, right, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :closed])
    body = Map.merge(%{
      "collection" => collection.name,
      "attribute" => attribute_name,
      "left" => left,
      "right" => right,
    }, vars)

    endpoint
    |> Endpoint.put("simple/range", body)
  end

  @doc """
  Remove documents by example

  PUT /_api/simple/remove-by-example
  """
  @spec remove_by_example(Endpoint.t, Collection.t, map) :: Arangoex.ok_error(map)
  def remove_by_example(endpoint, collection, example, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "options" => Map.merge(%{}, vars)
    }

    endpoint
    |> Endpoint.put("simple/remove-by-example", body)
  end

  @doc """
  Remove documents by their keys

  PUT /_api/simple/remove-by-keys
  """
  @spec remove_by_keys(Endpoint.t, Collection.t, [String.t], keyword) :: Arangoex.ok_error(map)
  def remove_by_keys(endpoint, collection, keys, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:returnOld, :silent, :waitForSync])
    body = %{
      "collection" => collection.name,
      "keys" => keys,
      "options" => Map.merge(%{}, vars)
    }

    endpoint
    |> Endpoint.put("simple/remove-by-keys", body)
  end

  @doc """
  Replace documents by example

  PUT /_api/simple/replace-by-example
  """
  @spec replace_by_example(Endpoint.t, Collection.t, map, map, keyword) :: Arangoex.ok_error(map)
  def replace_by_example(endpoint, collection, example, new_value, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "newValue" => new_value,
      "options" => Map.merge(%{}, vars)
    }

    endpoint
    |> Endpoint.put("simple/replace-by-example", body)
  end

  @doc """
  Update documents by example

  PUT /_api/simple/update-by-example
  """
  @spec update_by_example(Endpoint.t, Collection.t, map, map, keyword) :: Arangoex.ok_error(map)
  def update_by_example(endpoint, collection, example, new_value, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:keepNull, :mergeObjects, :limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "newValue" => new_value,
      "options" => Map.merge(%{}, vars)
    }

    endpoint
    |> Endpoint.put("simple/update-by-example", body)
  end


  @doc """
  Returns documents near a coordinate

  PUT /_api/simple/near
  """
  @spec near(Endpoint.t, Collection.t, float, float, keyword) :: Arangoex.ok_error(map)
  def near(endpoint, collection, latitude, longitude, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :distance, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude" => latitude,
      "longitude" => longitude,
    }, vars)

   endpoint
    |> Endpoint.put("simple/near", body)
  end

  @doc """
  Find documents within a radius around a coordinate

  PUT /_api/simple/within
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec within(Endpoint.t, Collection.t, float, float, float, keyword) :: Arangoex.ok_error(map)
  def within(endpoint, collection, latitude, longitude, radius, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :distance, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude" => latitude,
      "longitude" => longitude,
      "radius" => radius,
    }, vars)

    endpoint
    |> Endpoint.put("simple/within", body)
  end

  @doc """
  Within rectangle query

  PUT /_api/simple/within-rectangle
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec within_rectangle(Endpoint.t, Collection.t, float, float, float, float, keyword) :: Arangoex.ok_error(map)
  def within_rectangle(endpoint, collection, latitude1, longitude1, latitude2, longitude2, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude1" => latitude1,
      "longitude1" => longitude1,
      "latitude2" => latitude2,
      "longitude2" => longitude2,
    }, vars)

    endpoint
    |> Endpoint.put("simple/within-rectangle", body)
  end
end
