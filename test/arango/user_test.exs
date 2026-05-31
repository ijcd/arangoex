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

    assert "root" in names
  end

  test "creates a user" do
    new_username = Faker.Lorem.word()

    {:ok, original_users} = User.users() |> arango()
    {:ok, user} = User.create(user: new_username) |> arango()
    {:ok, after_users} = User.users() |> arango()

    assert [user] == after_users -- original_users
    assert user.user == new_username
  end

  test "removes a user" do
    new_user = %User{user: Faker.Lorem.word()}

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
    new_user = %User{user: Faker.Lorem.word()}
    {:ok, _} = User.create(new_user) |> arango()

    assert {:ok, %User{} = fetched_user} = User.user(new_user) |> arango()
    assert fetched_user.user == new_user.user
  end

  test "updates a user" do
    user_name = Faker.Lorem.word()
    user_pass = ""
    user = %Arango.User{user: user_name, passwd: user_pass, active: false}
    {:ok, user} = User.create(user) |> arango()

    extra = %{"foo" => 1, "bar" => 2}
    {:ok, updated_user} = User.update(user, extra: extra, active: true) |> arango()
    assert %User{user: ^user_name, active: true, extra: ^extra} = updated_user
  end

  test "replaces a user" do
    user_name = Faker.Lorem.word()
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
    {:ok, dbs} = User.databases(johnny) |> arango()
    assert Map.get(dbs, db_name, "none") == "none"
  end

  # === Phase 4 additions ===

  test "permissions/1 is an alias for databases/1" do
    {:ok, dbs} = User.permissions(%User{user: "root"}) |> arango()
    assert is_map(dbs)
    assert Map.has_key?(dbs, "_system")
  end

  test "permissions/2 returns the effective database permission", ctx do
    user = "user_perm_#{System.unique_integer([:positive])}"
    {:ok, _} = User.create(user: user) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name) |> arango()

    assert {:ok, %{"result" => "rw"}} =
             User.permissions(user, ctx.db_name) |> arango()
  end

  test "grant/4 grants ro on a collection", ctx do
    user = "user_coll_ro_#{System.unique_integer([:positive])}"
    {:ok, _} = User.create(user: user) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name, ctx.coll.name, "ro") |> arango()

    assert {:ok, %{"result" => "ro"}} =
             User.permission(user, ctx.db_name, ctx.coll.name) |> arango()
  end

  test "revoke/3 removes the collection-level grant (db-level remains)", ctx do
    user = "user_coll_rev_#{System.unique_integer([:positive])}"
    {:ok, _} = User.create(user: user) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name) |> arango()
    # Pin collection to none, distinct from the db-level "rw"
    {:ok, _} = User.grant(user, ctx.db_name, ctx.coll.name, "none") |> arango()

    assert {:ok, %{"result" => "none"}} =
             User.permission(user, ctx.db_name, ctx.coll.name) |> arango()

    # Remove the collection-level grant → falls back to db-level default
    {:ok, _} = User.revoke(user, ctx.db_name, ctx.coll.name) |> arango()

    {:ok, %{"result" => level}} =
      User.permission(user, ctx.db_name, ctx.coll.name) |> arango()

    # After revoke, the collection-level entry is gone; effective grant
    # is the db-level "rw" (3.12 returns either the inherited value or
    # "undefined" depending on server config — accept both).
    assert level in ["rw", "undefined"]
  end

  test "permission/3 returns the effective collection grant", ctx do
    user = "user_coll_eff_#{System.unique_integer([:positive])}"
    {:ok, _} = User.create(user: user) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name) |> arango()
    {:ok, _} = User.grant(user, ctx.db_name, ctx.coll.name, "rw") |> arango()

    assert {:ok, %{"result" => "rw"}} =
             User.permission(user, ctx.db_name, ctx.coll.name) |> arango()
  end
end
