defmodule Arango.Simple do
  @moduledoc "ArangoDB Simple methods"

  alias Arango.Request
  alias Arango.Utils
  alias Arango.Collection

  @doc """
  Return all documents

  PUT /_api/simple/all
  """
  @spec all(Collection.t, keyword) :: Arango.ok_error(map)
  def all(collection, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit])
    body = Map.merge(%{collection: collection.name}, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/all",
      body: body,
    }
  end

  @doc """
  Return a random document

  PUT /_api/simple/any
  """
  @spec any(Collection.t) :: Arango.ok_error(map)
  def any(collection) do
    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/any",
      body: %{collection: collection.name},
    }
  end

  @doc """
  Simple query by-example

  PUT /_api/simple/by-example
  """
  @spec query_by_example(Collection.t, map, keyword) :: Arango.ok_error(map)
  def query_by_example(collection, example, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit])
    body = Map.merge(%{collection: collection.name, example: example}, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/by-example",
      body: body,
    }
  end

  @doc """
  Find documents matching an example

  PUT /_api/simple/first-example
  """
  @spec find_by_example(Collection.t, map) :: Arango.ok_error(map)
  def find_by_example(collection, example) do
    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/first-example",
      body: %{collection: collection.name, example: example},
    }
  end

  @doc """
  Fulltext index query

  PUT /_api/simple/fulltext
  """
  @spec query_fulltext(Collection.t, String.t, String.t, keyword) :: Arango.ok_error(map)
  def query_fulltext(collection, attribute_name, query, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :index])
    body = Map.merge(%{
      "collection" => collection.name,
      "attribute" => attribute_name,     # not strictly necessary if you have :index
      "query" => query
    }, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/fulltext",
      body: body,
    }
  end

  @doc """
  Find documents by their keys

  PUT /_api/simple/lookup-by-keys
  """
  @spec lookup_by_keys(Collection.t, [String.t]) :: Arango.ok_error(map)
  def lookup_by_keys(collection, keys) do
    body = %{
      "collection" => collection.name,
      "keys" => keys
    }

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/lookup-by-keys",
      body: body,
    }
  end

  @doc """
  Simple range query

  PUT /_api/simple/range
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec range(Collection.t, String.t, float, float, keyword) :: Arango.ok_error(map)
  def range(collection, attribute_name, left, right, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :closed])
    body = Map.merge(%{
      "collection" => collection.name,
      "attribute" => attribute_name,
      "left" => left,
      "right" => right,
    }, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/range",
      body: body,
    }
  end

  @doc """
  Remove documents by example

  PUT /_api/simple/remove-by-example
  """
  @spec remove_by_example(Collection.t, map) :: Arango.ok_error(map)
  def remove_by_example(collection, example, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "options" => Map.merge(%{}, vars)
    }

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/remove-by-example",
      body: body,
    }
  end

  @doc """
  Remove documents by their keys

  PUT /_api/simple/remove-by-keys
  """
  @spec remove_by_keys(Collection.t, [String.t], keyword) :: Arango.ok_error(map)
  def remove_by_keys(collection, keys, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:returnOld, :silent, :waitForSync])
    body = %{
      "collection" => collection.name,
      "keys" => keys,
      "options" => Map.merge(%{}, vars)
    }

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/remove-by-keys",
      body: body,
    }
  end

  @doc """
  Replace documents by example

  PUT /_api/simple/replace-by-example
  """
  @spec replace_by_example(Collection.t, map, map, keyword) :: Arango.ok_error(map)
  def replace_by_example(collection, example, new_value, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "newValue" => new_value,
      "options" => Map.merge(%{}, vars)
    }

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/replace-by-example",
      body: body,
    }
  end

  @doc """
  Update documents by example

  PUT /_api/simple/update-by-example
  """
  @spec update_by_example(Collection.t, map, map, keyword) :: Arango.ok_error(map)
  def update_by_example(collection, example, new_value, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:keepNull, :mergeObjects, :limit, :waitForSync])
    body = %{
      "collection" => collection.name,
      "example" => example,
      "newValue" => new_value,
      "options" => Map.merge(%{}, vars)
    }

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/update-by-example",
      body: body,
    }
  end


  @doc """
  Returns documents near a coordinate

  PUT /_api/simple/near
  """
  @spec near(Collection.t, float, float, keyword) :: Arango.ok_error(map)
  def near(collection, latitude, longitude, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :distance, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude" => latitude,
      "longitude" => longitude,
    }, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/near",
      body: body,
    }
  end

  @doc """
  Find documents within a radius around a coordinate

  PUT /_api/simple/within
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec within(Collection.t, float, float, float, keyword) :: Arango.ok_error(map)
  def within(collection, latitude, longitude, radius, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :distance, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude" => latitude,
      "longitude" => longitude,
      "radius" => radius,
    }, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/within",
      body: body,
    }
  end

  @doc """
  Within rectangle query

  PUT /_api/simple/within-rectangle
  """
  @lint {Credo.Check.Refactor.FunctionArity, false}
  @spec within_rectangle(Collection.t, float, float, float, float, keyword) :: Arango.ok_error(map)
  def within_rectangle(collection, latitude1, longitude1, latitude2, longitude2, opts \\ []) do
    vars = Utils.opts_to_vars(opts, [:skip, :limit, :geo])
    body = Map.merge(%{
      "collection" => collection.name,
      "latitude1" => latitude1,
      "longitude1" => longitude1,
      "latitude2" => latitude2,
      "longitude2" => longitude2,
    }, vars)

    %Request{
      endpoint: :simple,
      http_method: :put,
      path: "simple/within-rectangle",
      body: body,
    }
  end
end
