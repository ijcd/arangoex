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
    } = Task.create(task) |> arango()
  end

  test "lists a task or tasks" do
     {:ok, tasks} = Task.tasks() |> arango()
     assert [
        %{
          "database" => "_system",
          "name" => "user-defined task",
          "period" => 1,
          "type" => "periodic"
        },
        # %{
        #   "database" => "_system",
        #   "id" => "statistics-gc",
        #   "name" => "statistics-gc",
        #   "period" => 450,
        #   "type" => "periodic"
        # },
        # %{
        #   "database" => "_system",
        #   "id" => "statistics-collector",
        #   "name" => "statistics-collector",
        #   "period" => 10,
        #   "type" => "periodic"
        # },
        # %{
        #   "database" => "_system",
        #   "id" => "statistics-average-collector",
        #   "name" => "statistics-average-collector",
        #   "period" => 900,
        #   "type" => "periodic"
        # },
      ] = Enum.sort(tasks)
  end

  test "deletes a task" do
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorNum" => 1852,
        "errorMessage" => "task not found"
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

    task = Task.task(task_id) |> arango()
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
    assert Regex.match?(~r/historianAverage/, result["command"])
  end

  test "create a task by id" do
    task = %Task{
      name: "SampleTask",
      command: "(function (params) { require('@arangodb/statistics').historianAverage(); } )(params);",
      params: %{
        foo: "fooey",
        bar: "barey"
      },
      period: 2
    }
    assert {:ok, _} = Task.create_with_id("foobar", task) |> arango()

    task = Task.task("foobar") |> arango()
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
    assert Regex.match?(~r/historianAverage/, result["command"])
  end
 end
