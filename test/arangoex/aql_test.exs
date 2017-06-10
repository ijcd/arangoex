defmodule AqlTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Aql
  alias Arangoex.Collection  

  test "Return registered AQL user functions", ctx do
    # no functions yet
    assert {
      :ok, []
    } == Aql.functions(ctx.endpoint)
  end

  test "Create AQL user function", ctx do
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
    } == Aql.create_function(ctx.endpoint, aql_function)

    # replaced returns 200
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
      }
    } == Aql.create_function(ctx.endpoint, aql_function)
    
    # function should be there
    assert {
      :ok, [
        %{
          "name" => "myfunctions::temperature::celsiustofahrenheit",
          "code" => "function (celsius) { return celsius * 1.8 + 32; }",
        }
      ]
    } == Aql.functions(ctx.endpoint)
  end

  test "Remove existing AQL user function", ctx do
    aql_function = %Aql.Function{
      name: "myfunctions::temperature::celsiustofahrenheit",
      code: "function (celsius) { return celsius * 1.8 + 32; }",
    }
    
    {:ok, _} = Aql.create_function(ctx.endpoint, aql_function)
    {:ok, functions} = Aql.functions(ctx.endpoint)
    assert Enum.count(functions) == 1

    # deletes
    assert {
      :ok, %{
          "code" => 200,
          "error" => false,          
      }
    } == Aql.delete_function(ctx.endpoint, "myfunctions::temperature::celsiustofahrenheit")

    # already deleted
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorMessage" => "user function '%s()' not found",
        "errorNum" => 1582
      }
    } == Aql.delete_function(ctx.endpoint, "myfunctions::temperature::celsiustofahrenheit")
  end

  test "Explain an AQL query (valid query)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    # Valid query
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => true,
        "plan" => plan,
        "warnings" => []
      }
    } = Aql.explain_query(ctx.endpoint, "FOR p IN products RETURN p")
    assert Enum.count(plan["rules"]) == 0
  end
    
  test "Explain an AQL query (a plan with some optimizer rules applied)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => true,
        "plan" => plan,
        "warnings" => []
      }
    } = Aql.explain_query(ctx.endpoint, "FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name")
    assert Enum.count(plan["rules"]) > 0
  end

  test "Explain an AQL query (using some options)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "plans" => plans,
        "warnings" => []
      }
    } = Aql.explain_query(ctx.endpoint, "FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name", max_number_of_plans: 2, all_plans: true, optimizer_rules: ["-all", "+use-index-for-sort", "+use-index-range"])
    assert Enum.count(plans) > 0
    assert Enum.count(plans) <= 2
end    

  test "Explain an AQL query (returning all plans)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "plans" => plans,
        "warnings" => []
      }
    } = Aql.explain_query(ctx.endpoint, "FOR p IN products LET a = p.id FILTER a == 4 LET name = p.name SORT p.id LIMIT 1 RETURN name", all_plans: true)
    assert Enum.count(plans) > 0
  end

  test "Explain an AQL query (a query that produces a warning)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "cacheable" => false,
        "plan" => _,
        "warnings" => warnings
      }
    } = Aql.explain_query(ctx.endpoint, "FOR i IN 1..10 RETURN 1 / 0")
    assert Enum.count(warnings) > 0    
  end

  test "Explain an AQL query (invalid query, missing bind parameter)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "no value specified for declared bind parameter 'id' (while parsing)",
        "errorNum" => 1551
      }
    } = Aql.explain_query(ctx.endpoint, "FOR p IN products FILTER p.id == @id LIMIT 2 RETURN p.n")
  end

  test "Parse an AQL query (a valid query)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,        
        "parsed" => true,
        "collections" => ["products"],
        "bindVars" => ["name"],
        "ast" => ast
      }
    } = Aql.validate_query(ctx.endpoint, "FOR p IN products FILTER p.name == @name LIMIT 2 RETURN p.n")
    assert Enum.count(ast) > 0
  end

  test "Parse an AQL query (an invalid query)", ctx do
    {:ok, _} = Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :error, %{ 
        "code" => 400, 
        "error" => true, 
        "errorMessage" => "syntax error, unexpected assignment near '= @name LIMIT 2 RETURN p.n' at position 1:33", 
        "errorNum" => 1501 
      }
    } = Aql.validate_query(ctx.endpoint, "FOR p IN products FILTER p.name = @name LIMIT 2 RETURN p.n")
  end

  test "Clears any results in the AQL query cache", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false
      }
    } == Aql.clear_query_cache(ctx.endpoint)
  end

  test "Returns the global properties for the AQL query cache", ctx do
    assert {
      :ok, %{
        "maxResults" => _,
        "mode" => _
      }
    } = Aql.query_cache_properties(ctx.endpoint)
  end

  test "Globally adjusts the AQL query result cache properties", ctx do
    assert {
      :ok, %{
        "maxResults" => 256,
        "mode" => "on"
      }
    } == Aql.set_query_cache_properties(ctx.endpoint, max_results: 256, mode: "on")
  end

  test "Returns the currently running AQL queries (no queries)", ctx do
    # with no queries running
    assert {
      :ok, []
    } == Aql.current_queries(ctx.endpoint)
  end

  @tag :skip
  test "Returns the currently running AQL queries (some queries)", ctx do
    # run some queries and check
    assert {
      :ok, []
    } == Aql.current_queries(ctx.endpoint)
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
    } == Aql.query_properties(ctx.endpoint)
  end

  @tag :skip
  test "Changes the properties for the AQL query tracking", ctx do
    assert {
      :ok, %{
        "enabled" => true,        
        "trackSlowQueries" => true,
        "maxSlowQueries" => 64,
        "slowQueryThreshold" => 10,
        "maxQueryStringLength" => 8192,
      }
    } == Aql.set_query_properties(ctx.endpoint, enabled: true, track_slow_queries: false, max_slow_queries: 128, slow_query_threshold: 30, max_query_string_length: 8192)
  end

  test "Clears the list of slow AQL queries", ctx do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false
      }
    } == Aql.clear_slow_queries(ctx.endpoint)
  end

  test "Returns the list of slow AQL queries", ctx do
    assert {
      :ok, []
    } == Aql.slow_queries(ctx.endpoint)
  end

  @tag :skip
  test "Kills a running AQL query (valid query)", ctx do
    assert {
      :ok, %{
      }
    } == Aql.kill_query(ctx.endpoint, "somequery")
  end

  test "Kills a running AQL query (invalid query)", ctx do
    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorMessage" => "cannot kill query 'somequery'",
        "errorNum" => 1591
      }
    } == Aql.kill_query(ctx.endpoint, "somequery")
  end
end
