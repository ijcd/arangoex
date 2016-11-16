defmodule UserTest do
  use Arangoex.TestCase
  doctest Arangoex

  import Arangoex.TestHelper

  alias Arangoex.User

  test "lists users" do
    {:ok, users} = User.users(test_endpoint)
    
    names =
      users
      |> Enum.map(fn c -> c.user end)
      |> Enum.sort

    assert names == ["root"]
  end

  test "creates a user" do
    new_username = Faker.Lorem.word

    {:ok, original_users} = User.users(test_endpoint)
    {:ok, user} = User.create(test_endpoint, %User{user: new_username})
    {:ok, after_users} = User.users(test_endpoint)

    assert [user] == after_users -- original_users
    assert user.user== new_username
  end

  test "removes a user" do
    new_user = %User{user: Faker.Lorem.word}

    # create one to remove
    {:ok, _} = User.create(test_endpoint, new_user)
    {:ok, users} = User.users(test_endpoint)

    assert new_user.user in Enum.map(users, & &1.user)

    # remove and make sure it's gone
    {:ok, _} = User.remove(test_endpoint, new_user)
    {:ok, users} = User.users(test_endpoint)
      
    refute new_user.user in Enum.map(users, & &1.user)
  end

  test "looks up user information" do
    new_user = %User{user: Faker.Lorem.word}
    {:ok, _} = User.create(test_endpoint, new_user)

    assert {:ok, %User{} = fetched_user} = User.user(test_endpoint, new_user)
    assert fetched_user.user == new_user.user
  end
  
  test "updates a user" do
    user_name = Faker.Lorem.word
    user_pass = ""
    user = %Arangoex.User{user: user_name, passwd: user_pass, active: false}
    {:ok, user} = User.create(test_endpoint, user)

    extra = %{"foo" => 1, "bar" => 2}    
    {:ok, updated_user} = User.update(test_endpoint, user, extra: extra, active: true)
    assert %User{user: ^user_name, active: true, extra: ^extra} = updated_user
  end

  test "replaces a user" do
    user_name = Faker.Lorem.word
    user_pass = ""
    user = %Arangoex.User{user: user_name, passwd: user_pass, active: false}
    {:ok, user} = User.create(test_endpoint, user)

    extra = %{"foo" => 1, "bar" => 2}    
    {:ok, replaced_user} = User.replace(test_endpoint, user, extra: extra, active: true)
    assert %User{user: ^user_name, active: true, extra: ^extra} = replaced_user
  end

  test "lists accessible databases", ctx do
    {:ok, dbs} = User.databases(test_endpoint, %User{user: "root"})
    assert "_system" in Map.keys(dbs)
    assert ctx.db.name in Map.keys(dbs)

    {:ok, _} = User.create(test_endpoint, %Arangoex.User{user: "johnny"})
    {:ok, dbs} = User.databases(test_endpoint, %User{user: "johnny"})
    assert dbs == %{}
  end

  test "grant and revoke database access", ctx do
    johnny = %User{user: "johnny"}
    db_name = ctx.db.name
    
    {:ok, _} = User.create(test_endpoint, johnny)
    {:ok, dbs} = User.databases(test_endpoint, johnny)
    refute db_name in Map.keys(dbs)
    
    {:ok, _} = User.grant(test_endpoint, johnny, ctx.db)
    assert {:ok, %{^db_name => "rw"}} = User.databases(test_endpoint, johnny)

    {:ok, _} = User.revoke(test_endpoint, johnny, ctx.db)
    assert {:ok, %{^db_name => "none"}} = User.databases(test_endpoint, johnny)
  end
end
