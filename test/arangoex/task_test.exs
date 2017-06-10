defmodule TaskTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Task

  test "creates a task", ctx do
    task = %Task{
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => "(function (params) { (function(params) { require('@arangodb').print(params); })(params) } )(params);",
        "created" => _,
        "database" => "_system",
        "id" => _,
        "offset" => _,        
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = Task.create(ctx.endpoint, task)
  end

  test "lists a task or tasks", ctx do
     {:ok, tasks} = Task.tasks(ctx.endpoint)
     assert [
        %{
          "database" => "_system",
          "name" => "user-defined task",
          "period" => 1,
          "type" => "periodic"
        },
        %{
          "database" => "_system",
          "id" => "statistics-gc",
          "name" => "statistics-gc",
          "period" => 450,
          "type" => "periodic"
        },
        %{
          "database" => "_system",
          "id" => "statistics-collector",
          "name" => "statistics-collector",
          "period" => 10,
          "type" => "periodic"
        },
        %{
          "database" => "_system",
          "id" => "statistics-average-collector",
          "name" => "statistics-average-collector",
          "period" => 900,
          "type" => "periodic"
        },
      ] = Enum.sort(tasks)
  end

  test "deletes a task", ctx do
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorNum" => 1852,
        "errorMessage" => "task not found"
      }
    } = Task.delete(ctx.endpoint, "1234")
    
    task = %Task{ 
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    {:ok, %{"id" => task_id}} = Task.create(ctx.endpoint, task)

    assert {
      :ok, %{"code" => 200, "error" => false}
    } = Task.delete(ctx.endpoint, task_id)
  end

  test "fetch a task by id", ctx do
    task = %Task{ 
      name: "SampleTask", 
      command: "(function(myparams) { require('@arangodb').print(myparams); })(myparams)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    {:ok, %{"id" => task_id}} = Task.create(ctx.endpoint, task)

    task = Task.task(ctx.endpoint, task_id)
    {:ok, result} = task
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => _,
        "created" => _,
        "database" => "_system",
        "id" => ^task_id,
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = task
    assert Regex.match?(~r/myparams/, result["command"])
  end

  test "create a task by id", ctx do
    task = %Task{ 
      name: "SampleTask", 
      command: "(function(myparams) { require('@arangodb').print(myparams); })(myparams)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    assert {:ok, _} = Task.create_with_id(ctx.endpoint, "foobar", task)

    task = Task.task(ctx.endpoint, "foobar")
    {:ok, result} = task
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => _,
        "created" => _,
        "database" => "_system",
        "id" => "foobar",
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = task
    assert Regex.match?(~r/myparams/, result["command"])
  end
 end
