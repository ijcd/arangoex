defmodule TransactionTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Collection
  alias Arango.Transaction

  test "Executing a transaction on a single collection", ctx do
    Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    assert {
      :ok, %{
        "result" => 1,
        "error" => false,
        "code" => 200
      }
    } = Transaction.transaction(%Transaction.Transaction{write_collections: ["products"], action: "function () { var db = require('@arangodb').db; db.products.save({});  return db.products.count(); }"}) |> on_db(ctx)
  end

  test "Executing a transaction using multiple collections", ctx do
    Collection.create(%Collection{name: "products"}) |> on_db(ctx)
    Collection.create(%Collection{name: "materials"}) |> on_db(ctx)

    assert {
      :ok, %{
        "result" => "worked!",
        "error" => false,
        "code" => 200
      }
    } = Transaction.transaction(%Transaction.Transaction{write_collections: ["products", "materials"], action: "function () {var db = require('@arangodb').db;db.products.save({});db.materials.save({});return 'worked!';}"}) |> on_db(ctx)
  end

  test "Aborting a transaction due to an internal error", ctx do
    Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    # ArangoDB 3.12 returns 409 (conflict) instead of 400, and error message includes details
    assert {
      :error, %{
        "error" => true,
        "errorNum" => 1210,
      }
    } = Transaction.transaction(%Transaction.Transaction{write_collections: ["products"], action: "function () {var db = require('@arangodb').db;db.products.save({ _key: 'abc'});db.products.save({ _key: 'abc'});}"}) |> on_db(ctx)
  end

  test "Aborting a transaction by explicitly throwing an exception", ctx do
    Collection.create(%Collection{name: "products"}) |> on_db(ctx)

    # ArangoDB 3.12 changed error response shape for thrown exceptions
    assert {
      :error, %{
        "error" => true,
        "code" => 500,
      }
    } = Transaction.transaction(%Transaction.Transaction{read_collections: ["products"], action: "function () { throw 'doh!'; }"}) |> on_db(ctx)
  end

  test "referring to a non-existing collection", ctx do
    # ArangoDB 3.12 changed error response shape (no "exception"/"stacktrace"/"message" keys)
    assert {
      :error, %{
        "error" => true,
        "errorNum" => 1203,
      }
    } = Transaction.transaction(%Transaction.Transaction{read_collections: ["products"], action: "function () { throw 'doh!'; }"}) |> on_db(ctx)
  end
end
