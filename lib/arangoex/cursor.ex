defmodule Arangoex.Cursor do
  @moduledoc "ArangoDB Cursor methods"

  alias Arangoex.Request

  defmodule Cursor do
    @moduledoc false

    @enforce_keys [:query]
    defstruct [
      :query,
      :bind_vars,
      :count,
      :batch_size,
      :cache,
      :memory_limit,
      :ttl,
      :bind_vars,
      :profile,
      :optimizer_rules,
      :satellite_sync_wait,
      :full_count,
      :max_plans,
    ]

    @type t :: %__MODULE__{
      # query: contains the query string to be executed
      query: String.t,

      # bind_vars: a map or keyword list containing the bounded variables
      # with their respective values.
      bind_vars: Keyword.t | Map.t,

      # count: indicates whether the number of documents in the result
      # set should be returned in the "count" attribute of the
      # result. Calculating the "count" attribute might have a
      # performance impact for some queries in the future so this
      # option is turned off by default, and "count" is only returned
      # when requested.
      count: boolean,

      # batchSize: maximum number of result documents to be
      # transferred from the server to the client in one roundtrip. If
      # this attribute is not set, a server-controlled default value
      # will be used. A batchSize value of 0 is disallowed.
      batch_size: pos_integer,

      # cache: flag to determine whether the AQL query cache shall be
      # used. If set to false, then any query cache lookup will be
      # skipped for the query. If set to true, it will lead to the
      # query cache being checked for the query if the query cache
      # mode is either on or demand.
      cache: boolean,

      # memoryLimit: the maximum number of memory (measured in bytes)
      # that the query is allowed to use. If set, then the query will
      # fail with error "resource limit exceeded" in case it allocates
      # too much memory. A value of 0 indicates that there is no
      # memory limit.
      memory_limit: non_neg_integer,

      # ttl: The time-to-live for the cursor (in seconds). The cursor
      # will be removed on the server automatically after the
      # specified amount of time. This is useful to ensure garbage
      # collection of cursors that are not fully fetched by
      # clients. If not set, a server-defined value will be used.


      # profile: If set to true, then the additional query profiling
      # information will be returned in the sub-attribute profile of
      # the extra return attribute if the query result is not served
      # from the query cache.

      # optimizer.rules (string): A list of to-be-included or
      # to-be-excluded optimizer rules can be put into this attribute,
      # telling the optimizer to include or exclude specific rules. To
      # disable a rule, prefix its name with a -, to enable a rule,
      # prefix it with a +. There is also a pseudo-rule all, which
      # will match all optimizer rules.
      optimizer_rules: [String.t],

      # satelliteSyncWait: This enterprise parameter allows to
      # configure how long a DBServer will have time to bring the
      # satellite collections involved in the query into sync. The
      # default value is 60.0 (seconds). When the max time has been
      # reached the query will be stopped.

      # fullCount: if set to true and the query contains a LIMIT
      # clause, then the result will have an extra attribute with the
      # sub-attributes stats and fullCount, { ... , "extra": {
      # "stats": { "fullCount": 123 } } }. The fullCount attribute
      # will contain the number of documents in the result before the
      # last LIMIT in the query was applied. It can be used to count
      # the number of documents that match certain filter criteria,
      # but only return a subset of them, in one go. It is thus
      # similar to MySQL's SQL_CALC_FOUND_ROWS hint. Note that setting
      # the option will disable a few LIMIT optimizations and may lead
      # to more documents being processed, and thus make queries run
      # longer. Note that the fullCount attribute will only be present
      # in the result if the query has a LIMIT clause and the LIMIT
      # clause is actually used in the query.
      full_count: boolean,

      # maxPlans: Limits the maximum number of plans that are created
      # by the AQL query optimizer.
      max_plans: pos_integer,
    }
  end

  # @doc """
  # Create cursor
  #
  # POST /_api/cursor
  # """
  @spec cursor_create(Cursor.t) :: Arangoex.ok_error(map)
  def cursor_create(cursor) do
    query = Map.get(cursor, :query)
    bind_vars = Map.get(cursor, :bind_vars)
    count = Map.get(cursor, :count)
    batch_size = Map.get(cursor, :batch_size)
    full_count = Map.get(cursor, :full_count)
    max_plans = Map.get(cursor, :max_plans)
    optimizer_rules = Map.get(cursor, :optimizer_rules)

    top_level =
      %{}
      |> Map.merge(if query, do: %{"query" => query}, else: %{})
      |> Map.merge(if bind_vars, do: %{"bindVars" => Enum.into(bind_vars, %{})}, else: %{})
      |> Map.merge(if count, do: %{"count" => count}, else: %{})
      |> Map.merge(if batch_size, do: %{"batchSize" => batch_size}, else: %{})

    options =
      %{}
      |> Map.merge(if full_count, do: %{"fullCount" => full_count}, else: %{})
      |> Map.merge(if max_plans, do: %{"maxPlans" => max_plans}, else: %{})
      |> Map.merge(if optimizer_rules, do: %{"optimizer" => %{"rules" => optimizer_rules}}, else: %{})

    cursor_request =
      top_level
      |> Map.merge(if Enum.any?(options), do: %{"options" => options}, else: %{})

    %Request{
      endpoint: :cursor,
      http_method: :post,
      path: "cursor",
      body: cursor_request
    }
  end

  # @doc """
  # Delete cursor

  # DELETE /_api/cursor/{cursor-identifier}
  # """
  @spec cursor_delete(Cursor.t) :: Arangoex.ok_error(map)
  def cursor_delete(cursor_id) do
    %Request{
      endpoint: :cursor,
      http_method: :delete,
      path: "cursor/#{cursor_id}"
    }
  end

  # @doc """
  # Read next batch from cursor

  # PUT /_api/cursor/{cursor-identifier}
  # """
  @spec cursor_next(Cursor.t) :: Arangoex.ok_error(map)
  def cursor_next(cursor_id) do
    %Request{
      endpoint: :cursor,
      http_method: :put,
      path: "cursor/#{cursor_id}"
    }
  end
end
