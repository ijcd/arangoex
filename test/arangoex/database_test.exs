defmodule DatabaseTest do
  use ExUnit.Case
  doctest Arangoex

  import Arangoex.TestHelper

  alias Arangoex.Database

  setup do
    # remember original dbs
    {:ok, original_dbs} = Database.databases(test_endpoint)

    on_exit fn ->
      # cleanup any new dbs that have appeared
      {:ok, after_dbs} = Database.databases(test_endpoint)
      for db_name <- (after_dbs -- original_dbs) do
        {:ok, _} = Database.drop(test_endpoint, db_name)
      end
    end
  end

  test "creates a database" do
    new_dbname = Faker.Lorem.word

    {:ok, original_dbs} = Database.databases(test_endpoint)
    {:ok, true} = Database.create(test_endpoint, %Database{name: new_dbname})
    {:ok, after_dbs} = Database.databases(test_endpoint)
    
    assert (after_dbs -- original_dbs) == [new_dbname]
  end

  test "creates a database with users" do
    new_dbname = Faker.Lorem.word

    {:ok, original_dbs} = Database.databases(test_endpoint)
    {:ok, true} = Database.create(test_endpoint,
      %Database{
        name: new_dbname,
        users: [
          %{username: "admin", passwd: "secret", active: true},
          %{username: "tester", passwd: "test001", active: false},
          %{username: "eddie", passwd: "eddie001", active: false, extra: %{foo: 1, bar: 2}},
        ]
      }
    )

    # assert created
    {:ok, after_dbs} = Database.databases(test_endpoint)
    assert (after_dbs -- original_dbs) == [new_dbname]

    # assert metadata
    {:ok, _db_info} = Database.database(test_endpoint, new_dbname)
    # TODO: assert that the users are there (after we build out /users
  end
  
  test "fails to create a database" do
    new_dbname = "#$%^&"
    {:error, %{"error" => true, "errorMessage" => "database name invalid"}} = Database.create(test_endpoint, %Database{name: new_dbname})
  end

  test "drops a database" do
    new_dbname = Faker.Lorem.word    

    # create one to drop
    {:ok, true} = Database.create(test_endpoint, %Database{name: new_dbname})
    {:ok, dbs} = Database.databases(test_endpoint)

    assert new_dbname in dbs

    # drop and make sure it's gone
    {:ok, true} = Database.drop(test_endpoint, new_dbname)
    {:ok, dbs} = Database.databases(test_endpoint)
      
    refute new_dbname in dbs
  end

  test "looks up database information" do
    {:ok, db} = Database.database(test_endpoint, "_system")
    %Arangoex.Database{id: "1", isSystem: true, name: "_system", path: "/var/lib/arangodb3/databases/database-1", users: nil} = db

    new_dbname = Faker.Lorem.word
    {:ok, true} = Database.create(test_endpoint, %Database{name: new_dbname})
    {:ok, db} = Database.database(test_endpoint, new_dbname)
    %Arangoex.Database{id: _, isSystem: false, name: ^new_dbname, path: _, users: nil} = db
  end

  test "lists existing databases" do
    {:ok, dbs} = Database.databases(test_endpoint)

    assert is_list(dbs)
    assert length(dbs) > 0
    assert "_system" in dbs
  end

  test "lists accessible databases" do
    new_dbname = Faker.Lorem.word

    {:ok, true} = Database.create(test_endpoint, %Database{name: new_dbname})
    {:ok, dbs} = Database.user_databases(test_endpoint)

    assert is_list(dbs)
    assert "_system" in dbs
    assert new_dbname in dbs
  end  
end
