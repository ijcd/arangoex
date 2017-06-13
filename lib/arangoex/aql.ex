# TODO: Deadlock handling / New error code 29 -- Client applications
# should be prepared to handle error 29 (deadlock detected) that
# ArangoDB may now throw when it detects a deadlock across multiple
# transactions. When a client application receives error 29, it should
# retry the operation that failed. The error can only occur for AQL
# queries or user transactions that involve more than a single
# collection.

defmodule Arangoex.Aql do
  @moduledoc "ArangoDB AQL methods"

  alias Arangoex.Request

  defmodule Function do
    @moduledoc false

    @enforce_keys [:code, :name]
    defstruct [
      name: nil,
      code: nil,
      isDeterministic: true
    ]

    @type t :: %__MODULE__{
      # the fully qualified name of the user functions.
      name: String.t,

      # a string representation of the function body.
      code: String.t,

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
      query: String.t,

      # optimizer_rules (string): an array of to-be-included or
      # to-be-excluded optimizer rules can be put into this attribute,
      # telling the optimizer to include or exclude specific rules. To
      # disable a rule, prefix its name with a -, to enable a rule,
      # prefix it with a +. There is also a pseudo-rule all, which
      # will match all optimizer rules.
      optimizer_rules: [String.t],

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

  # @doc """
  # Return registered AQL user functions
  #
  # GET /_api/aqlfunction
  # """
  @spec functions() :: Arangoex.ok_error(map)
  def functions() do
    %Request{
      endpoint: :aql,
      system_only: true,   # or just /_api? Same thing?
      http_method: :get,
      path: "aqlfunction"
    }
  end

  # @doc """
  # Create AQL user function
  #
  # POST /_api/aqlfunction
  # """
  @spec create_function(Function.t) :: Arangoex.ok_error(map)
  def create_function(function) do
    %Request{
      endpoint: :aql,
      system_only: true,   # or just /_api? Same thing?
      http_method: :post,
      path: "aqlfunction",
      body: function,
    }
  end

  @doc """
  Remove existing AQL user function#

  DELETE /_api/aqlfunction/{name}
  """
  @spec delete_function(String.t) :: Arangoex.ok_error(map)
  def delete_function(name) do
    %Request{
      endpoint: :aql,
      system_only: true,   # or just /_api? Same thing?
      http_method: :delete,
      path: "aqlfunction/#{name}",
    }
  end

  # @doc """
  # Explain an AQL query
  #
  # POST /_api/explain
  # """
  @spec explain_query(Keyword.t) :: Arangoex.ok_error(map)
  def explain_query(query, options \\ %{}) do
    # TODO: this is surely simplified with a reduce
    options = Enum.into(options, %{})

    max_number_of_plans = Map.get(options, :max_number_of_plans)
    all_plans = Map.get(options, :all_plans)
    optimizer_rules = Map.get(options, :optimizer_rules)

    opts =
      %{}
      |> Map.merge(if max_number_of_plans, do: %{"maxNumberOfPlans" => max_number_of_plans}, else: %{})
      |> Map.merge(if all_plans, do: %{"allPlans" => all_plans}, else: %{})
      |> Map.merge(if optimizer_rules, do: %{"optimizer" => %{"rules" => optimizer_rules}}, else: %{})

    explain_request =
      %{query: query}
      |> Map.merge(if Enum.any?(opts), do: %{"options" => opts}, else: %{})

    %Request{
      endpoint: :aql,
      http_method: :post,
      path: "explain",
      body: explain_request,
    }
  end

  # @doc """
  # Parse an AQL query
  #
  # POST /_api/query
  # """
  @spec validate_query(String.t) :: Arangoex.ok_error(map)
  def validate_query(query) do
    %Request{
      endpoint: :aql,
      http_method: :post,
      path: "query",
      body: %{query: query},
    }
  end

  # @doc """
  # Clears any results in the AQL query cache
  #
  # DELETE /_api/query-cache
  # """
  @spec clear_query_cache() :: Arangoex.ok_error(map)
  def clear_query_cache() do
    %Request{
      endpoint: :aql,
      http_method: :delete,
      path: "query-cache",
    }
  end

  # @doc """
  # Returns the global properties for the AQL query cache
  #
  # GET /_api/query-cache/properties
  # """
  @spec query_cache_properties() :: Arangoex.ok_error(map)
  def query_cache_properties() do
    %Request{
      endpoint: :aql,
      http_method: :get,
      path: "query-cache/properties",
    }
  end

  # @doc """
  # Globally adjusts the AQL query result cache properties
  #
  # PUT /_api/query-cache/properties
  # """
  @spec set_query_cache_properties(Keyword.t) :: Arangoex.ok_error(map)
  def set_query_cache_properties(options \\ %{}) do
    options = Enum.into(options, %{})

    max_results = Map.get(options, :max_results)
    mode = Map.get(options, :mode)

    opts =
      %{}
      |> Map.merge(if max_results, do: %{"maxResults" => max_results}, else: %{})
      |> Map.merge(if mode, do: %{"mode" => mode}, else: %{})

    %Request{
      endpoint: :aql,
      http_method: :put,
      path: "query-cache/properties",
      body: opts,
    }
  end

  # @doc """
  # Returns the currently running AQL queries
  #
  # GET /_api/query/current
  # """
  @spec current_queries() :: Arangoex.ok_error(map)
  def current_queries() do
    %Request{
      endpoint: :aql,
      http_method: :get,
      path: "query/current",
    }
  end

  # @doc """
  # Returns the properties for the AQL query tracking
  #
  # GET /_api/query/properties
  # """
  @spec query_properties() :: Arangoex.ok_error(map)
  def query_properties() do
    %Request{
      endpoint: :aql,
      http_method: :get,
      path: "query/properties",
    }
  end

  # @doc """
  # Changes the properties for the AQL query tracking
  #
  # PUT /_api/query/properties
  # """
  @spec set_query_properties(Keyword.t) :: Arangoex.ok_error(map)
  def set_query_properties(options \\ %{}) do
    options = Enum.into(options, %{})

    enabled = Map.get(options, :enabled)
    slow_query_threshold = Map.get(options, :slow_query_threshold)
    max_slow_queries = Map.get(options, :max_slow_queries)
    track_slow_queries = Map.get(options, :track_slow_queries)
    max_query_string_length = Map.get(options, :max_query_string_length)

    opts =
      %{}
      |> Map.merge(if enabled, do: %{"enabled" => enabled}, else: %{})
      |> Map.merge(if slow_query_threshold, do: %{"slowQuerythreshold" => slow_query_threshold}, else: %{})
      |> Map.merge(if max_slow_queries, do: %{"maxSlowqueries" => max_slow_queries}, else: %{})
      |> Map.merge(if track_slow_queries, do: %{"trackSlowqueries" => track_slow_queries}, else: %{})
      |> Map.merge(if max_query_string_length, do: %{"maxQuerystringlength" => max_query_string_length}, else: %{})

    %Request{
      endpoint: :aql,
      http_method: :put,
      path: "query/properties",
      body: opts,
    }
  end

  # @doc """
  # Clears the list of slow AQL queries
  #
  # DELETE /_api/query/slow
  # """
  @spec clear_slow_queries() :: Arangoex.ok_error(map)
  def clear_slow_queries() do
    %Request{
      endpoint: :aql,
      http_method: :delete,
      path: "query/slow",
    }
  end

  # @doc """
  # Returns the list of slow AQL queries
  #
  # GET /_api/query/slow
  # """
  @spec slow_queries() :: Arangoex.ok_error(map)
  def slow_queries() do
    %Request{
      endpoint: :aql,
      http_method: :get,
      path: "query/slow",
    }
  end

  # @doc """
  # Kills a running AQL query
  #
  # DELETE /_api/query/{query-id}
  # """
  @spec kill_query(String.t) :: Arangoex.ok_error(map)
  def kill_query(query_id) do
    %Request{
      endpoint: :aql,
      http_method: :delete,
      path: "query/#{query_id}",
    }
  end
end
