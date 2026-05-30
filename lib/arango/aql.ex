# TODO: Deadlock handling / New error code 29 -- Client applications
# should be prepared to handle error 29 (deadlock detected) that
# ArangoDB may now throw when it detects a deadlock across multiple
# transactions. When a client application receives error 29, it should
# retry the operation that failed. The error can only occur for AQL
# queries or user transactions that involve more than a single
# collection.

defmodule Arango.Aql do
  @moduledoc "ArangoDB AQL methods"

  use Arango.API, endpoint: :aql

  @aql_function_deprecation "AQL user functions are removed in API v1/4.0. Inline the logic into your AQL queries."

  defmodule Function do
    @moduledoc false

    @enforce_keys [:code, :name]
    defstruct name: nil,
              code: nil,
              isDeterministic: true

    @type t :: %__MODULE__{
            # the fully qualified name of the user functions.
            name: String.t(),

            # a string representation of the function body.
            code: String.t(),

            # an optional boolean value to indicate that the function
            # results are fully deterministic (function return value solely
            # depends on the input value and return value is the same for
            # repeated calls with same input). The isDeterministic attribute
            # is currently not used but may be used later for optimisations.
            isDeterministic: boolean
          }
  end

  defmodule ExplainRequest do
    @moduledoc false

    @enforce_keys [:query]
    defstruct [
      :query,
      :optimizer_rules,
      :max_number_of_plans,
      :all_plans,
      :bind_vars
    ]

    @type t :: %__MODULE__{
            # the query which you want explained; If the query
            # references any bind variables, these must also be passed in the
            # attribute bindVars. Additional options for the query can be passed
            # in the options attribute.
            query: String.t(),

            # optimizer_rules (string): an array of to-be-included or
            # to-be-excluded optimizer rules can be put into this attribute,
            # telling the optimizer to include or exclude specific rules. To
            # disable a rule, prefix its name with a -, to enable a rule,
            # prefix it with a +. There is also a pseudo-rule all, which
            # will match all optimizer rules.
            optimizer_rules: [String.t()],

            # maximum number of plans that the optimizer is allowed to
            # generate. Setting this attribute to a low value allows to put
            # a cap on the amount of work the optimizer does.
            max_number_of_plans: pos_integer,

            # if set to true, all possible execution plans will be
            # returned. The default is false, meaning only the optimal plan will
            # be returned.
            all_plans: boolean,

            # key/value pairs representing the bind parameters.
            bind_vars: map
          }
  end

  @doc """
  Return registered AQL user functions

  GET /_api/aqlfunction
  """
  @deprecated @aql_function_deprecation
  @spec functions() :: Arango.ok_error(map)
  def functions() do
    request(
      system_only: true,
      method: :get,
      path: "aqlfunction"
    )
  end

  @doc """
  Create AQL user function

  POST /_api/aqlfunction
  """
  @deprecated @aql_function_deprecation
  @spec create_function(Function.t()) :: Arango.ok_error(map)
  def create_function(function) do
    request(
      system_only: true,
      method: :post,
      path: "aqlfunction",
      body: function
    )
  end

  @doc """
  Remove existing AQL user function#

  DELETE /_api/aqlfunction/{name}
  """
  @deprecated @aql_function_deprecation
  @spec delete_function(String.t()) :: Arango.ok_error(map)
  def delete_function(name) do
    request(
      system_only: true,
      method: :delete,
      path: "aqlfunction/#{name}"
    )
  end

  @doc """
  Explain an AQL query

  POST /_api/explain
  """
  @spec explain_query(Keyword.t()) :: Arango.ok_error(map)
  def explain_query(query, options \\ %{}) do
    options = Enum.into(options, %{})
    optimizer_rules = Map.get(options, :optimizer_rules)

    opts =
      Utils.compact(%{
        "maxNumberOfPlans" => Map.get(options, :max_number_of_plans),
        "allPlans" => Map.get(options, :all_plans),
        "optimizer" => optimizer_rules && %{"rules" => optimizer_rules}
      })

    explain_request =
      if map_size(opts) > 0, do: %{:query => query, "options" => opts}, else: %{query: query}

    request(method: :post, path: "explain", body: explain_request)
  end

  @doc """
  Parse an AQL query

  POST /_api/query
  """
  @spec validate_query(String.t()) :: Arango.ok_error(map)
  def validate_query(query) do
    request(
      method: :post,
      path: "query",
      body: %{query: query}
    )
  end

  @doc """
  Clears any results in the AQL query cache

  DELETE /_api/query-cache
  """
  @spec clear_query_cache() :: Arango.ok_error(map)
  def clear_query_cache() do
    request(
      method: :delete,
      path: "query-cache"
    )
  end

  @doc """
  Returns the global properties for the AQL query cache

  GET /_api/query-cache/properties
  """
  @spec query_cache_properties() :: Arango.ok_error(map)
  def query_cache_properties() do
    request(
      method: :get,
      path: "query-cache/properties"
    )
  end

  @doc """
  Globally adjusts the AQL query result cache properties

  PUT /_api/query-cache/properties
  """
  @spec set_query_cache_properties(Keyword.t()) :: Arango.ok_error(map)
  def set_query_cache_properties(options \\ %{}) do
    options = Enum.into(options, %{})

    opts =
      Utils.compact(%{
        "maxResults" => Map.get(options, :max_results),
        "mode" => Map.get(options, :mode)
      })

    request(method: :put, path: "query-cache/properties", body: opts)
  end

  @doc """
  Returns the currently running AQL queries

  GET /_api/query/current
  """
  @spec current_queries() :: Arango.ok_error(map)
  def current_queries() do
    request(
      method: :get,
      path: "query/current"
    )
  end

  @doc """
  Returns the properties for the AQL query tracking

  GET /_api/query/properties
  """
  @spec query_properties() :: Arango.ok_error(map)
  def query_properties() do
    request(
      method: :get,
      path: "query/properties"
    )
  end

  @doc """
  Changes the properties for the AQL query tracking

  PUT /_api/query/properties
  """
  @spec set_query_properties(Keyword.t()) :: Arango.ok_error(map)
  def set_query_properties(options \\ %{}) do
    options = Enum.into(options, %{})

    opts =
      Utils.compact(%{
        "enabled" => Map.get(options, :enabled),
        "slowQueryThreshold" => Map.get(options, :slow_query_threshold),
        "maxSlowQueries" => Map.get(options, :max_slow_queries),
        "trackSlowQueries" => Map.get(options, :track_slow_queries),
        "maxQueryStringLength" => Map.get(options, :max_query_string_length)
      })

    request(method: :put, path: "query/properties", body: opts)
  end

  @doc """
  Clears the list of slow AQL queries

  DELETE /_api/query/slow
  """
  @spec clear_slow_queries() :: Arango.ok_error(map)
  def clear_slow_queries() do
    request(
      method: :delete,
      path: "query/slow"
    )
  end

  @doc """
  Returns the list of slow AQL queries

  GET /_api/query/slow
  """
  @spec slow_queries() :: Arango.ok_error(map)
  def slow_queries() do
    request(
      method: :get,
      path: "query/slow"
    )
  end

  @doc """
  Kills a running AQL query

  DELETE /_api/query/{query-id}
  """
  @spec kill_query(String.t()) :: Arango.ok_error(map)
  def kill_query(query_id) do
    request(
      method: :delete,
      path: "query/#{query_id}"
    )
  end
end
