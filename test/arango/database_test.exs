defmodule DatabaseTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Database
  alias Arango.User  

  test "creates a database" do
    new_dbname = "testcreate_#{System.unique_integer([:positive])}"

    {:ok, original_dbs} = Database.databases() |> arango()
    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, after_dbs} = Database.databases() |> arango()

    assert new_dbname in (after_dbs -- original_dbs)
  end

  test "creates a database with users" do
    new_dbname = Faker.Lorem.word

    {:ok, original_dbs} = Database.databases() |> arango()
    {:ok, true} = arango Database.create(name: new_dbname, users: [
          %{username: "admin", passwd: "secret", active: true},
          %{username: "tester", passwd: "test001", active: false},
          %{username: "eddie", passwd: "eddie001", active: false, extra: %{foo: 1, bar: 2}},
        ])

    # assert created
    {:ok, after_dbs} = arango Database.databases()
    assert (after_dbs -- original_dbs) == [new_dbname]

    # assert metadata
    {:ok, _db_info} = Database.database() |> arango(database_name: new_dbname)

    # assert users
    {:ok, %User{user: "admin"}} = User.user("admin") |> arango()
    {:ok, %User{user: "tester"}} = User.user("tester") |> arango()
    {:ok, %User{user: "eddie"}} = User.user("eddie") |> arango()
  end

  test "fails to create a database" do
    new_dbname = ""
    {:error, %{"error" => true, "errorNum" => error_num}} = Database.create(name: new_dbname) |> arango()
    assert error_num in [1208, 1229]
  end

  test "drops a database" do
    new_dbname = Faker.Lorem.word    

    # create one to drop
    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, dbs} = Database.databases() |> arango()

    assert new_dbname in dbs

    # drop and make sure it's gone
    {:ok, true} = Database.drop(new_dbname) |> arango()
    {:ok, dbs} = Database.databases() |> arango()
      
    refute new_dbname in dbs
  end

  test "looks up database information" do
    # lookup _system
    {:ok, db} = Database.database() |> arango(database_name: "_system")
    assert %Arango.Database{isSystem: true, name: "_system"} = db

    # lookup a newly minted db
    new_dbname = "testlookup_#{System.unique_integer([:positive])}"
    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, db} = Database.database() |> arango(database_name: new_dbname)
    assert %Arango.Database{isSystem: false, name: ^new_dbname} = db
  end

  test "lists existing databases" do
    {:ok, dbs} = Database.databases() |> arango()

    assert is_list(dbs)
    assert length(dbs) > 0
    assert "_system" in dbs
  end

  test "lists accessible databases" do
    new_dbname = Faker.Lorem.word

    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, dbs} = Database.user_databases() |> arango()

    assert is_list(dbs)
    assert "_system" in dbs
    assert new_dbname in dbs
  end  
end
