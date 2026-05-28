defmodule TaskTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Task

  test "creates a task" do
    task = %Task{
      name: "SampleTask",
      command: "(function(params) { require('@arangodb').print(params); })(params)",
      params: %{
        foo: "fooey",
        bar: "barey"
      },
      period: 2
    }

    # ArangoDB 3.12 task creation response no longer includes "code"/"error" keys
    assert {
      :ok, %{
        "command" => _command,
        "created" => _,
        "database" => "_system",
        "id" => _,
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = Task.create(task) |> arango()
  end

  test "lists a task or tasks" do
     {:ok, tasks} = Task.tasks() |> arango()
     assert is_list(tasks)
     # Tasks list contains at least system tasks; just verify it's a list of maps with expected keys
     for task <- tasks do
       assert Map.has_key?(task, "database")
       assert Map.has_key?(task, "type")
     end
  end

  test "deletes a task" do
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorNum" => 1852,
      }
    } = Task.delete("1234") |> arango()

    task = %Task{
      name: "SampleTask",
      command: "(function (params) { require('@arangodb/statistics').historianAverage(); } )(params);",
      params: %{
        foo: "fooey",
        bar: "barey"
      },
      period: 2
    }
    {:ok, %{"id" => task_id}} = Task.create(task) |> arango()

    assert {
      :ok, %{"code" => 200, "error" => false}
    } = Task.delete(task_id) |> arango()
  end

  test "fetch a task by id" do
    task = %Task{
      name: "SampleTask",
      command: "(function (params) { require('@arangodb/statistics').historianAverage(); } )(params);",
      params: %{
        foo: "fooey",
        bar: "barey"
      },
      period: 2
    }
    {:ok, %{"id" => task_id}} = Task.create(task) |> arango()

    # ArangoDB 3.12 task get response no longer includes "code"/"error" keys
    task = Task.task(task_id) |> arango()
    {:ok, result} = task
    assert {
      :ok, %{
        "command" => _,
        "created" => _,
        "database" => "_system",
        "id" => ^task_id,
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = task
    assert Regex.match?(~r/historianAverage/, result["command"])
  end

  test "create a task by id" do
    # Clean up any stale task with this id from previous test runs
    Task.delete("foobar_task_test") |> arango()

    task = %Task{
      name: "SampleTask",
      command: "(function (params) { require('@arangodb/statistics').historianAverage(); } )(params);",
      params: %{
        foo: "fooey",
        bar: "barey"
      },
      period: 2
    }
    assert {:ok, _} = Task.create_with_id("foobar_task_test", task) |> arango()

    task = Task.task("foobar_task_test") |> arango()
    {:ok, result} = task
    assert {
      :ok, %{
        "command" => _,
        "created" => _,
        "database" => "_system",
        "id" => "foobar_task_test",
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = task
    assert Regex.match?(~r/historianAverage/, result["command"])
  end
 end
