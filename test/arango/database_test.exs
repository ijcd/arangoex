defmodule DatabaseTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Database
  alias Arango.User  

  test "creates a database" do
    new_dbname = Faker.Lorem.word

    {:ok, original_dbs} = Database.databases() |> arango() 
    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, after_dbs} = Database.databases() |> arango()
    
    assert (after_dbs -- original_dbs) == [new_dbname]
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
    {:ok, _db_info} = Database.database(name: new_dbname) |> arango()

    # assert users
    {:ok, %User{user: "admin"}} = User.user("admin") |> arango()
    {:ok, %User{user: "tester"}} = User.user("tester") |> arango()
    {:ok, %User{user: "eddie"}} = User.user("eddie") |> arango()
  end

  test "fails to create a database" do
    new_dbname = "#$%^&"
    {:error, %{"error" => true, "errorMessage" => "database name invalid"}} = Database.create(name: new_dbname) |> arango()
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
    {:ok, db} = Database.database(name: "_system") |> arango()
    %Arango.Database{id: "1", isSystem: true, name: "_system", path: "/var/lib/arangodb3/databases/database-1", users: nil} = db

    # lookup a newly minted db
    new_dbname = Faker.Lorem.word
    {:ok, true} = Database.create(name: new_dbname) |> arango()
    {:ok, db} = Database.database(name: new_dbname) |> arango()
    %Arango.Database{id: _, isSystem: false, name: ^new_dbname, path: _, users: nil} = db
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
