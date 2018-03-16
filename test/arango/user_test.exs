defmodule UserTest do
  use Arango.TestCase
  doctest Arango

  import Arango.TestHelper

  alias Arango.User

  test "lists users" do
    {:ok, users} = User.users() |> arango()
    
    names =
      users
      |> Enum.map(fn c -> c.user end)
      |> Enum.sort

    assert names == ["root"]
  end

  test "creates a user" do
    new_username = Faker.Lorem.word

    {:ok, original_users} = User.users() |> arango()
    {:ok, user} = User.create(user: new_username) |> arango()
    {:ok, after_users} = User.users() |> arango()

    assert [user] == after_users -- original_users
    assert user.user== new_username
  end

  test "removes a user" do
    new_user = %User{user: Faker.Lorem.word}

    # create one to remove
    {:ok, _} = User.create(new_user) |> arango()
    {:ok, users} = User.users() |> arango()

    assert new_user.user in Enum.map(users, & &1.user)

    # remove and make sure it's gone
    {:ok, _} = User.remove(new_user) |> arango()
    {:ok, users} = User.users() |> arango()
      
    refute new_user.user in Enum.map(users, & &1.user)
  end

  test "looks up user information" do
    new_user = %User{user: Faker.Lorem.word}
    {:ok, _} = User.create(new_user) |> arango()

    assert {:ok, %User{} = fetched_user} = User.user(new_user) |> arango()
    assert fetched_user.user == new_user.user
  end
  
  test "updates a user" do
    user_name = Faker.Lorem.word
    user_pass = ""
    user = %Arango.User{user: user_name, passwd: user_pass, active: false}
    {:ok, user} = User.create(user) |> arango()

    extra = %{"foo" => 1, "bar" => 2}    
    {:ok, updated_user} = User.update(user, extra: extra, active: true) |> arango()
    assert %User{user: ^user_name, active: true, extra: ^extra} = updated_user
  end

  test "replaces a user" do
    user_name = Faker.Lorem.word
    user_pass = ""
    user = %Arango.User{user: user_name, passwd: user_pass, active: false}
    {:ok, user} = User.create(user) |> arango()

    extra = %{"foo" => 1, "bar" => 2}    
    {:ok, replaced_user} = User.replace(user, extra: extra, active: true) |> arango()
    assert %User{user: ^user_name, active: true, extra: ^extra} = replaced_user
  end

  test "lists accessible databases", ctx do
    {:ok, dbs} = User.databases(%User{user: "root"}) |> arango()
    assert "_system" in Map.keys(dbs)
    assert ctx.db_name in Map.keys(dbs)

    {:ok, _} = User.create(%Arango.User{user: "johnny"}) |> arango()
    {:ok, dbs} = User.databases(%User{user: "johnny"}) |> arango()
    assert dbs == %{}
  end

  test "grant and revoke database access", ctx do
    johnny = %User{user: "johnny"}
    db_name = ctx.db_name
    
    {:ok, _} = User.create(johnny) |> arango()
    {:ok, dbs} = User.databases(johnny) |> arango()
    refute db_name in Map.keys(dbs)
    
    {:ok, _} = User.grant(johnny, db_name) |> arango()
    assert {:ok, %{^db_name => "rw"}} = User.databases(johnny) |> arango()

    {:ok, _} = User.revoke(johnny, db_name) |> arango()
    assert {:ok, %{^db_name => "none"}} = User.databases(johnny) |> arango()
  end
end
