defmodule TransactionTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Collection
  alias Arangoex.Transaction

  test "Executing a transaction on a single collection", ctx do
    Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :ok, %{
        "result" => 1,
        "error" => false,
        "code" => 200
      }
    } = Transaction.transaction(ctx.endpoint, %Transaction.Transaction{write_collections: ["products"], action: "function () { var db = require('@arangodb').db; db.products.save({});  return db.products.count(); }"})
  end

  test "Executing a transaction using multiple collections", ctx do
    Collection.create(ctx.endpoint, %Collection{name: "products"})
    Collection.create(ctx.endpoint, %Collection{name: "materials"})

    assert {
      :ok, %{
        "result" => "worked!",
        "error" => false,
        "code" => 200
      }
    } = Transaction.transaction(ctx.endpoint, %Transaction.Transaction{write_collections: ["products", "materials"], action: "function () {var db = require('@arangodb').db;db.products.save({});db.materials.save({});return 'worked!';}"})
  end

  test "Aborting a transaction due to an internal error", ctx do
    Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :error, %{
        "exception" => "ArangoError 1210: unique constraint violated",
        "stacktrace" => _,
        "message" => "unique constraint violated",
        "error" => true,
        "code" => 400,
        "errorNum" => 1210,
        "errorMessage" => "unique constraint violated"
      }
    } = Transaction.transaction(ctx.endpoint, %Transaction.Transaction{write_collections: ["products"], action: "function () {var db = require('@arangodb').db;db.products.save({ _key: 'abc'});db.products.save({ _key: 'abc'});}"})
  end

  test "Aborting a transaction by explicitly throwing an exception", ctx do
    Collection.create(ctx.endpoint, %Collection{name: "products"})

    assert {
      :error, %{
        "exception" => "doh!",
        "error" => true,
        "code" => 500,
        "errorNum" => 500,
        "errorMessage" => "internal server error"
      }
    } = Transaction.transaction(ctx.endpoint, %Transaction.Transaction{read_collections: ["products"], action: "function () { throw 'doh!'; }"})
  end

  test "referring to a non-existing collection", ctx do
    assert {
      :error, %{
        "exception" => "ArangoError 1203: collection not found",
        "stacktrace" => _,
        "message" => "collection not found",
        "error" => true,
        "code" => 404,
        "errorNum" => 1203,
        "errorMessage" => "collection not found"
      }
    } = Transaction.transaction(ctx.endpoint, %Transaction.Transaction{read_collections: ["products"], action: "function () { throw 'doh!'; }"})
  end
end
