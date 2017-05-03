ExUnit.start()

defmodule Arangoex.TestHelper do
  def test_endpoint do
    %Arangoex.Endpoint{
      host: System.get_env("ARANGO_HOST"),
      use_auth: :basic,
      username: System.get_env("ARANGO_USER"),
      password: System.get_env("ARANGO_PASSWORD"),
    }
  end
end

defmodule Arangoex.TestCase do
  use ExUnit.CaseTemplate
  import Arangoex.TestHelper

  alias Arangoex.Endpoint
  alias Arangoex.Administration
  alias Arangoex.Collection
  alias Arangoex.Database
  alias Arangoex.User

  using do
    quote do
      import Arangoex.TestHelper
    end
  end
  
  setup do
    # remember original dbs, users, tasks
    {:ok, original_dbs} = Database.databases(test_endpoint())
    {:ok, original_users} = User.users(test_endpoint())
    {:ok, original_tasks} = Administration.tasks(test_endpoint())

    new_db = %Arangoex.Database{name: Faker.Lorem.word}
    new_coll = %Arangoex.Collection{name: Faker.Lorem.word}

    {:ok, _} = Database.create(test_endpoint(), new_db)
    {:ok, coll} = test_endpoint()
      |> Endpoint.with_db(new_db.name)
      |> Collection.create(new_coll)

    on_exit fn ->
      # cleanup any new dbs that have appeared
      {:ok, after_dbs} = Database.databases(test_endpoint())
      for db_name <- (after_dbs -- original_dbs) do
        {:ok, _} = Database.drop(test_endpoint(), db_name)
      end

      # cleanup any new users that have appeared
      {:ok, after_users} = User.users(test_endpoint())
      for user <- (after_users -- original_users) do
        {:ok, _} = User.remove(test_endpoint(), user)
      end

      # cleanup any new tasks that have appeared
      {:ok, after_tasks} = Administration.tasks(test_endpoint())
      original_task_ids = original_tasks |> Enum.map(& &1["id"])
      after_task_ids = after_tasks |> Enum.map(& &1["id"])
      for task_id <- (after_task_ids -- original_task_ids) do
        {:ok, _} = Administration.task_delete(test_endpoint(), task_id)
      end
    end

    %{
      endpoint: Map.put(test_endpoint(), :database_name, new_db.name),
      coll: coll,
      db: new_db,
    }
  end
end
