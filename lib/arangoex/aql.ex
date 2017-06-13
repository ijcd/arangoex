defmodule Arangoex.Aql do
  @moduledoc "ArangoDB AQL methods"

  alias Arangoex.Endpoint

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
  @spec functions(Endpoint.t) :: Arangoex.ok_error(map)
  def functions(endpoint) do
    endpoint
    |> Endpoint.get("/aqlfunction")
  end

  # @doc """
  # Create AQL user function
  #
  # POST /_api/aqlfunction
  # """
  @spec create_function(Endpoint.t, Function.t) :: Arangoex.ok_error(map)
  def create_function(endpoint, function) do
    endpoint
    |> Endpoint.post("/aqlfunction", function)
  end

  @doc """
  Remove existing AQL user function#

  DELETE /_api/aqlfunction/{name}
  """
  @spec delete_function(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def delete_function(endpoint, name) do
    endpoint
    |> Endpoint.delete("/aqlfunction/#{name}")
  end

  # @doc """
  # Explain an AQL query
  #
  # POST /_api/explain
  # """
  @spec explain_query(Endpoint.t, Keyword.t) :: Arangoex.ok_error(map)
  def explain_query(endpoint, query, options \\ %{}) do
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

    endpoint
    |> Endpoint.post("/explain", explain_request)
  end

  # @doc """
  # Parse an AQL query
  #
  # POST /_api/query
  # """
  @spec validate_query(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def validate_query(endpoint, query) do
    endpoint
    |> Endpoint.post("/query", %{query: query})
  end

  # @doc """
  # Clears any results in the AQL query cache
  #
  # DELETE /_api/query-cache
  # """
  @spec clear_query_cache(Endpoint.t) :: Arangoex.ok_error(map)
  def clear_query_cache(endpoint) do
    endpoint
    |> Endpoint.delete("query-cache")
  end

  # @doc """
  # Returns the global properties for the AQL query cache
  #
  # GET /_api/query-cache/properties
  # """
  @spec query_cache_properties(Endpoint.t) :: Arangoex.ok_error(map)
  def query_cache_properties(endpoint) do
    endpoint
    |> Endpoint.get("query-cache/properties")
  end

  # @doc """
  # Globally adjusts the AQL query result cache properties
  #
  # PUT /_api/query-cache/properties
  # """
  @spec set_query_cache_properties(Endpoint.t, Keyword.t) :: Arangoex.ok_error(map)
  def set_query_cache_properties(endpoint, options \\ %{}) do
    # TODO: this is surely simplified with a reduce
    options = Enum.into(options, %{})

    max_results = Map.get(options, :max_results)
    mode = Map.get(options, :mode)

    opts =
      %{}
      |> Map.merge(if max_results, do: %{"maxResults" => max_results}, else: %{})
      |> Map.merge(if mode, do: %{"mode" => mode}, else: %{})

    endpoint
    |> Endpoint.put("query-cache/properties", opts)
  end


  # @doc """
  # Returns the currently running AQL queries
  #
  # GET /_api/query/current
  # """
  @spec current_queries(Endpoint.t) :: Arangoex.ok_error(map)
  def current_queries(endpoint) do
    endpoint
    |> Endpoint.get("query/current")
  end

  # @doc """
  # Returns the properties for the AQL query tracking
  #
  # GET /_api/query/properties
  # """
  @spec query_properties(Endpoint.t) :: Arangoex.ok_error(map)
  def query_properties(endpoint) do
    endpoint
    |> Endpoint.get("query/properties")
  end

  # @doc """
  # Changes the properties for the AQL query tracking
  #
  # PUT /_api/query/properties
  # """
  @spec set_query_properties(Endpoint.t, Keyword.t) :: Arangoex.ok_error(map)
  def set_query_properties(endpoint, options \\ %{}) do
    # TODO: this is surely simplified with a reduce
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

    endpoint
    |> Endpoint.put("query/properties", opts)
  end

  # @doc """
  # Clears the list of slow AQL queries
  #
  # DELETE /_api/query/slow
  # """
  @spec clear_slow_queries(Endpoint.t) :: Arangoex.ok_error(map)
  def clear_slow_queries(endpoint) do
    endpoint
    |> Endpoint.delete("query/slow")
  end

  # @doc """
  # Returns the list of slow AQL queries
  #
  # GET /_api/query/slow
  # """
  @spec slow_queries(Endpoint.t) :: Arangoex.ok_error(map)
  def slow_queries(endpoint) do
    endpoint
    |> Endpoint.get("query/slow")
  end

  # @doc """
  # Kills a running AQL query
  #
  # DELETE /_api/query/{query-id}
  # """
  @spec kill_query(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def kill_query(endpoint, query_id) do
    endpoint
    |> Endpoint.delete("query/#{query_id}")
  end
end
