defmodule AqlTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Aql
  alias Arangoex.Collection

  test "Return registered AQL user functions" do
    # no functions yet
    assert {
      :ok, []
    } == Aql.functions() |> arango
  end

  test "Create AQL user function" do
    aql_function = %Aql.Function{
      name: "myfunctions::temperature::celsiustofahrenheit",
      code: "function (celsius) { return celsius * 1.8 + 32; }",
    }

    # created returns 201
    assert {
      :ok, %{
        "code" => 201,
        "error" => false,
      }
    } == Aql.create_function(aql_function) |> arango

    # replaced returns 200
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
      }
    } == Aql.create_function(aql_function) |> arango

    # function should be there
    assert {
      :ok, [
        %{
          "name" => "myfunctions::temperature::celsiustofahrenheit",
          "code" => "function (celsius) { return celsius * 1.8 + 32; }",
        }
      ]
    } == Aql.functions() |> arango
  end

  test "Remove existing AQL user function" do
    aql_function = %Aql.Function{
      name: "myfunctions::temperature::celsiustofahrenheit",
      code: "function (celsius) { return celsius * 1.8 + 32; }",
    }

    {:ok, _} = Aql.create_function(aql_function) |> arango
    {:ok, functions} = Aql.functions() |> arango
    assert Enum.count(functions) == 1

    # deletes
    assert {
      :ok, %{
          "code" => 200,
          "error" => false,
      }
    } == Aql.delete_function("myfunctions::temperature::celsiustofahrenheit") |> arango

    # already deleted
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "user function '%s()' not found",
        "errorNum" => 1582
      }
    } == Aql.delete_function("myfunctions::temperature::celsiustofahrenheit") |> arango
  end

  test "Explain an AQL query (valid query)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    # Valid query
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => true,
        "plan" => plan,
        "warnings" => []
      }
    } = Aql.explain_query("FOR p IN products RETURN p") |> on_db(ctx)
    assert Enum.count(plan["rules"]) == 0
  end

  test "Explain an AQL query (a plan with some optimizer rules applied)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => true,
        "plan" => plan,
        "warnings" => []
      }
    } = Aql.explain_query("FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name") |> on_db(ctx)
    assert Enum.count(plan["rules"]) > 0
  end

  test "Explain an AQL query (using some options)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "plans" => plans,
        "warnings" => []
      }
    } = Aql.explain_query("FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name", max_number_of_plans: 2, all_plans: true, optimizer_rules: ["-all", "+use-index-for-sort", "+use-index-range"]) |> on_db(ctx)
    assert Enum.count(plans) > 0
    assert Enum.count(plans) <= 2
end

  test "Explain an AQL query (returning all plans)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "plans" => plans,
        "warnings" => []
      }
    } = Aql.explain_query("FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name", all_plans: true) |> on_db(ctx)
    assert Enum.count(plans) > 0
  end

  test "Explain an AQL query (a query that produces a warning)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => false,
        "plan" => _,
        "warnings" => warnings
      }
    } = Aql.explain_query("FOR i IN 1..10 RETURN 1 / 0") |> on_db(ctx)
    assert Enum.count(warnings) > 0
  end

  test "Explain an AQL query (invalid query, missing bind parameter)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "no value specified for declared bind parameter 'id' (while parsing)",
        "errorNum" => 1551
      }
    } = Aql.explain_query("FOR p IN products FILTER p.id == @id LIMIT 2 RETURN p.n") |> on_db(ctx)
  end

  test "Parse an AQL query (a valid query)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "parsed" => true,
        "collections" => ["products"],
        "bindVars" => ["name"],
        "ast" => ast
      }
    } = Aql.validate_query("FOR p IN products FILTER p.name == @name LIMIT 2 RETURN p.n") |> on_db(ctx)
    assert Enum.count(ast) > 0
  end

  test "Parse an AQL query (an invalid query)", ctx do
    {:ok, _} = Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "syntax error, unexpected assignment near '= @name LIMIT 2 RETURN p.n' at position 1:33",
        "errorNum" => 1501
      }
    } = Aql.validate_query("FOR p IN products FILTER p.name = @name LIMIT 2 RETURN p.n") |> on_db(ctx)
  end

  test "Clears any results in the AQL query cache", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false
      }
    } == Aql.clear_query_cache() |> on_db(ctx)
  end

  test "Returns the global properties for the AQL query cache", ctx do
    assert {
      :ok, %{
        "maxResults" => _,
        "mode" => _
      }
    } = Aql.query_cache_properties() |> on_db(ctx)
  end

  test "Globally adjusts the AQL query result cache properties", ctx do
    assert {
      :ok, %{
        "maxResults" => 256,
        "mode" => "on"
      }
    } == Aql.set_query_cache_properties(max_results: 256, mode: "on") |> on_db(ctx)
  end

  test "Returns the currently running AQL queries (no queries)", ctx do
    # with no queries running
    assert {
      :ok, []
    } == Aql.current_queries() |> on_db(ctx)
  end

  @tag :skip
  test "Returns the currently running AQL queries (some queries)", ctx do
    # run some queries and check
    assert {
      :ok, []
    } == Aql.current_queries() |> on_db(ctx)
  end

  test "Returns the properties for the AQL query tracking", ctx do
    # with no queries running
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "enabled" => true,
        "trackSlowQueries" => true,
        "maxSlowQueries" => 64,
        "slowQueryThreshold" => 10,
        "maxQueryStringLength" => 4096,
      }
    } == Aql.query_properties() |> on_db(ctx)
  end

  @tag :skip
  test "Changes the properties for the AQL query tracking", ctx do
    assert {
      :ok, %{
        "enabled" => false,
        "trackSlowQueries" => false,
        "maxSlowQueries" => 128,
        "slowQueryThreshold" => 20,
        "maxQueryStringLength" => 2048,
      }
    } == Aql.set_query_properties(enabled: false, track_slow_queries: false, max_slow_queries: 128, slow_query_threshold: 20, max_query_string_length: 2048) |> on_db(ctx)
  end

  test "Clears the list of slow AQL queries", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false
      }
    } == Aql.clear_slow_queries() |> on_db(ctx)
  end

  test "Returns the list of slow AQL queries", ctx do
    assert {
      :ok, []
    } == Aql.slow_queries() |> on_db(ctx)
  end

  @tag :skip
  test "Kills a running AQL query (valid query)", ctx do
    assert {
      :ok, %{
      }
    } == Aql.kill_query("somequery") |> on_db(ctx)
  end

  test "Kills a running AQL query (invalid query)", ctx do
    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "cannot kill query 'somequery'",
        "errorNum" => 1591
      }
    } == Aql.kill_query("somequery") |> on_db(ctx)
  end
end
