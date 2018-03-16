ExUnit.start()

defmodule Arango.TestHelper do
  # TODO: make this a struct so it is typed
  def test_config do
    %{
      host: System.get_env("ARANGO_HOST"),
      username: System.get_env("ARANGO_USER"),
      password: System.get_env("ARANGO_PASSWORD"),
      use_auth: :basic,
    }
  end

  def debug_config do
    test_config() |> Map.merge(%{debug_requests: true})
  end

  # send request to arango using default config and database from config
  def on_db(op, context) do
    arango(op, database_name: context.db_name)
  end

  # send request to arango using debug config and database from config
  def don_db(op, context) do
    darango(op, database_name: context.db_name)
  end

  # send request to arango using default config
  def arango(op, config_overrides \\ []) do
    merged_config = Map.merge(test_config(), Enum.into(config_overrides, %{}))
    Arango.request(op, merged_config)
  end

  # send request to arango using debug config
  def darango(op, config_overrides \\ []) do
    merged_config = Map.merge(debug_config(), Enum.into(config_overrides, %{}))
    Arango.request(op, merged_config)
  end
end

defmodule Arango.TestCase do
  use ExUnit.CaseTemplate
  import Arango.TestHelper

  alias Arango.User
  alias Arango.Database
  alias Arango.Collection
  alias Arango.Aql
  alias Arango.Task
  alias Arango.Wal

  using do
    quote do
      import Arango.TestHelper
    end
  end

  setup do
    {:ok, _properties} = Wal.set_properties(throttleWhenPending: 0) |> arango()

    # remember original dbs, users, tasks
    {:ok, original_dbs} = Database.databases() |> arango()
    {:ok, original_users} = User.users() |> arango()
    {:ok, original_funcs} = Aql.functions() |> arango()
    {:ok, original_tasks} = Task.tasks() |> arango()

    new_db_name = Faker.Lorem.word
    new_coll_name = Faker.Lorem.word

    {:ok, _} = Database.create(name: new_db_name) |> arango()
    {:ok, coll} = Collection.create(new_coll_name) |> arango(database_name: new_db_name)

    on_exit fn ->
      # cleanup any new dbs that have appeared
      {:ok, after_dbs} = Database.databases() |> arango()
      for db_name <- (after_dbs -- original_dbs) do
        {:ok, _} = Database.drop(db_name) |> arango()
      end

      # cleanup any new users that have appeared
      {:ok, after_users} = User.users() |> arango()
      for user <- (after_users -- original_users) do
        {:ok, _} = User.remove(user) |> arango()
      end

      # cleanup any new functions that have appeared
      {:ok, after_funcs} = Aql.functions() |> arango()
      for function <- (after_funcs -- original_funcs) do
        {:ok, _} = Aql.delete_function(function["name"]) |> arango()
      end

      # cleanup any new tasks that have appeared
      {:ok, after_tasks} = Task.tasks() |> arango()
      original_task_ids = original_tasks |> Enum.map(& &1["id"])
      after_task_ids = after_tasks |> Enum.map(& &1["id"])
      for task_id <- (after_task_ids -- original_task_ids) do
        {:ok, _} = Task.delete(task_id) |> arango()
      end
    end

    %{
      coll: coll,
      db_name: new_db_name,
    }
  end
end
