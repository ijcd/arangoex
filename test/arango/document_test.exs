defmodule DocumentTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Collection
  alias Arango.Document
  alias Arango.Document.Docref

  setup do
    %{
      data1: %{"name" =>"Jim", "age" => 22, "fruit" => %{"apple" => 3, "pear" => 4}},
      data2: %{"name" =>"John", "age" => 33, "cars" => %{"honda" => 5, "ford" => 6}},
      data3: %{"name" =>"Jack", "age" => 44, "sports" => %{"hockey" => 7, "soccer" => 8}},
    }
  end

  describe "creating a document" do

    test "normally", ctx do
      assert {:ok, %Docref{_id: _, _key: _, _rev: _}} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
    end

    test "waiting for sync", ctx do
      assert {:ok, %Docref{_id: _, _key: _, _rev: _}} = Document.create(ctx.coll, ctx.data1, waitForSync: true) |> on_db(ctx)
      assert {:ok, {%Docref{_id: _, _key: _, _rev: _}, _new}} = Document.create(ctx.coll, ctx.data2, returnNew: true) |> on_db(ctx)
      assert {:ok, {%Docref{_id: _, _key: _, _rev: _}, _new}} = Document.create(ctx.coll, ctx.data3, waitForSync: true, returnNew: true) |> on_db(ctx)
      assert_raise RuntimeError, "unknown key: badarg", fn ->
        Document.create(ctx.coll, ctx.data3, badarg: false)|> on_db(ctx)
      end
    end

    test "with returnNew format", ctx do
      assert {:ok, {%Docref{_id: id, _key: key, _rev: rev}, new_doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)
      assert %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev, "name" => "Jim", "age" => 22, "fruit" => %{"apple" => 3, "pear" => 4}} = new_doc
    end

    test "creates several documents", ctx do
      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)
    end

    test "fails to create a document with duplicate key", ctx do
      assert {:ok, %Docref{_id: _, _key: key, _rev: _}} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      assert {:error,
              %{
                "error" => true,
                "code" => 409,
                "errorMessage" => "cannot create document, unique constraint violated"
              }
      } = Document.create(ctx.coll, Map.merge(ctx.data2, %{_key: key})) |> on_db(ctx)
    end

    test "fails to create a document on an unknown collection", ctx do
      assert {:error,
              %{
                "error" => true,
                "code" => 404,
                "errorMessage" => "collection 'asdf' not found"
              }
      } = Document.create(%Collection{name: "asdf"}, ctx.data1) |> on_db(ctx)
    end
  end

  describe "fetching a document header" do
    test "fetches the header of a document", ctx do
      {:ok, doc} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      assert {:ok, removed} = Document.header(doc) |> on_db(ctx)
      assert removed["etag"] == doc._rev
    end

    test "fetches the header of a document using If-Matching, If-None-Matching", ctx do
      {:ok, doc} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)

      assert {:error, _} = Document.header(doc, ifNoneMatch: doc._rev) |> on_db(ctx)
      assert {:ok, _}    = Document.header(doc, ifNoneMatch: "999") |> on_db(ctx)

      assert {:ok, _}    = Document.header(doc, ifMatch: doc._rev) |> on_db(ctx)
      assert {:error, _} = Document.header(doc, ifMatch: "999") |> on_db(ctx)
    end
  end

  describe "fetching a document" do
    test "fetches a document", ctx do
      {:ok, doc} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      assert {:ok, fetched} = Document.document(doc) |> on_db(ctx)
      id = doc._id
      key = doc._key
      rev = doc._rev
      assert %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev, "age" => 22, "fruit" => %{"apple" => 3, "pear" => 4}, "name" => "Jim"} = fetched
    end

    test "fetches a document using If-Matching, If-None-Matching", ctx do
      {:ok, doc} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)

      assert {:error, _} = Document.document(doc, ifNoneMatch: doc._rev) |> on_db(ctx)
      assert {:ok, _}    = Document.document(doc, ifNoneMatch: "999") |> on_db(ctx)

      assert {:ok, _}    = Document.document(doc, ifMatch: doc._rev) |> on_db(ctx)
      assert {:error, _} = Document.document(doc, ifMatch: "999") |> on_db(ctx)
    end
  end

  describe "fetching many documents" do
    test "fetches all documents", ctx do
      {:ok, data1} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      {:ok, data2} = Document.create(ctx.coll, ctx.data2) |> on_db(ctx)
      {:ok, data3} = Document.create(ctx.coll, ctx.data3) |> on_db(ctx)

      assert {:ok, %{"result" => result}} = Document.documents(ctx.coll) |> on_db(ctx)
      path1 = "/_db/#{ctx.db_name}/_api/document/#{data1._id}"
      path2 = "/_db/#{ctx.db_name}/_api/document/#{data2._id}"
      path3 = "/_db/#{ctx.db_name}/_api/document/#{data3._id}"
      assert path1 in result
      assert path2 in result
      assert path3 in result

      assert {:ok, %{"result" => result}} = Document.documents(ctx.coll, type: :path) |> on_db(ctx)
      path1 = "/_db/#{ctx.db_name}/_api/document/#{data1._id}"
      path2 = "/_db/#{ctx.db_name}/_api/document/#{data2._id}"
      path3 = "/_db/#{ctx.db_name}/_api/document/#{data3._id}"
      assert path1 in result
      assert path2 in result
      assert path3 in result

      assert {:ok, %{"result" => result}} = Document.documents(ctx.coll, type: :id) |> on_db(ctx)
      id1 = data1._id
      id2 = data2._id
      id3 = data3._id
      assert id1 in result
      assert id2 in result
      assert id3 in result

      assert {:ok, %{"result" => result}} = Document.documents(ctx.coll, type: :key) |> on_db(ctx)
      key1 = data1._key
      key2 = data2._key
      key3 = data3._key
      assert key1 in result
      assert key2 in result
      assert key3 in result

      assert_raise RuntimeError, "unknown type: blarg", fn ->
        Document.documents(ctx.coll, type: "blarg") |> on_db(ctx)
      end

      assert_raise RuntimeError, "unknown type: foo", fn ->
        Document.documents(ctx.coll, type: :foo) |> on_db(ctx)
      end
    end
  end

  describe "updating a document" do
    test "updates a document successfully", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      assert {:ok, %Docref{}} = Document.update(docref, new_doc) |> on_db(ctx)
    end

    test "fails to update an unknown document", ctx do
      assert {:error, %{"code" => 404, "errorMessage" => "document not found"}} =
        Document.update(%Docref{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}, %{"foo" => 1}) |> on_db(ctx)
    end

    test "updates a document, returning the new document", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}

      assert {:ok, {%Docref{_id: id, _key: key, _rev: rev}, new}} = Document.update(docref, new_doc, returnNew: true) |> on_db(ctx)
      assert %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}} = new
    end

    test "updates a document, returning the old document", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 43, "fruit" => %{plum: 2, grape: 12}}

      {:ok, %Docref{_id: id, _key: key, _rev: rev} = old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {_new_ref, old_returned}} = Document.update(old_ref, new_data, returnOld: true) |> on_db(ctx)

      assert %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev,
               "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}
      } = old_returned
    end

    test "updates a document, returning the new document (keepNull = default)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}

      {:ok, old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {%Docref{_id: id, _key: key, _rev: rev}, new_returned}} = Document.update(old_ref, new_data, returnNew: true) |> on_db(ctx)

      assert %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev,
               "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}
      } = new_returned
    end

    test "updates a document, returning the new document (keepNull = false)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}

      {:ok, old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {%Docref{_id: id, _key: key, _rev: rev}, new_returned}} = Document.update(old_ref, new_data, returnNew: true, keepNull: false) |> on_db(ctx)

      %{"_id" => ^id, "_key" => ^key, "_rev" => ^rev, "age" => 32, "fruit" => fruit} = new_returned
      assert Map.has_key?(fruit, "pear") == false
      assert fruit == %{"apple" => 3, "peach" => 1}
    end

    test "updates a document, returning the old document and new document (mergeObejcts = true (default))", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 43, "fruit" => %{plum: 2, grape: 12}}

      {:ok, %Docref{_id: old_id, _key: old_key, _rev: old_rev} = old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {%Docref{_id: new_id, _key: new_key, _rev: new_rev} = _new_ref, old_returned, new_returned}} =
        Document.update(old_ref, new_data, returnOld: true, returnNew: true) |> on_db(ctx)

      assert %{
        "_id" => ^old_id, "_key" => ^old_key, "_rev" => ^old_rev,
        "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}
      } = old_returned

      assert %{
        "_id" => ^new_id, "_key" => ^new_key, "_rev" => ^new_rev,
        "age" => 43, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20, "plum" => 2, "grape" => 12}
      } = new_returned
    end

    test "updates a document, returning the old document and new document (mergeObjects = false)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 43, "fruit" => %{plum: 2, grape: 12}}

      {:ok, %Docref{_id: old_id, _key: old_key, _rev: old_rev} = old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {%Docref{_id: new_id, _key: new_key, _rev: new_rev} = _new_ref, old_returned, new_returned}} =
        Document.update(old_ref, new_data, returnOld: true, returnNew: true, mergeObjects: false) |> on_db(ctx)

      assert %{
        "_id" => ^old_id, "_key" => ^old_key, "_rev" => ^old_rev,
        "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}
      } = old_returned

      assert %{
        "_id" => ^new_id, "_key" => ^new_key, "_rev" => ^new_rev,
        "age" => 43, "fruit" => %{"plum" => 2, "grape" => 12}
      } = new_returned
    end

    test "updates a document successful, with waitForSync", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1, waitForSync: true) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      assert {:ok, %Docref{}} = Document.update(docref, new_doc) |> on_db(ctx)
    end

    test "updates a document, considering revision (ignoreRevs = false)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55})
      assert {:ok, _} = Document.update(docref, doc2, returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "fails to update a document, considering revision (ignoreRevs = false)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 77, "_rev" => "foobar"})
      assert {:error, %{"errorNum" => 1200, "errorMessage" => "precondition failed"}} = Document.update(docref, doc2, returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "updates a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55})
      assert {:ok, {_, returned}} = Document.update(docref, doc2, returnNew: true, ifMatch: doc2["_rev"]) |> on_db(ctx)
      assert Map.drop(returned, ["_id", "_key", "_rev"]) == Map.drop(doc2, ["_id", "_key", "_rev"])
    end

    test "fails to update a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55, "_rev" => "foobar"})
      assert {:error, %{"errorMessage" => "precondition failed"}} = Document.update(docref, doc2, returnNew: true, ifMatch: "12345") |> on_db(ctx)
    end
  end

  describe "updating several documents in a collection" do
    test "updates several documents successfully", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Enum.reduce([ctx.data1, %{age2: ctx.data1["age"] + 1}, dref1], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{age2: ctx.data2["age"] + 1}, dref2], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{age2: ctx.data3["age"] + 1}, dref3], &Map.merge/2)

      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3]) |> on_db(ctx)
    end

    test "fails to update_multi an unknown documents", ctx do
      [{:ok, _},
       {:ok, _},
       {:ok, _},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      badref = %{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}
      new_data1 = Enum.reduce([ctx.data1, %{age2: ctx.data1["age"] + 1}, badref], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{age2: ctx.data2["age"] + 1}, badref], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{age2: ctx.data3["age"] + 1}, badref], &Map.merge/2)

      assert [
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3]) |> on_db(ctx)
    end

    test "updates several documents, returning the new documents", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref3, [:_id, :_key, :_rev]))

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3}
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnNew: true) |> on_db(ctx)

      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 32, "name" => "Jim", "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      } = ret1
      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 32, "name" => "John", "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}, "cars" => %{"ford" => 6, "honda" => 5}}
      } = ret2
      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 32, "name" => "Jack", "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}, "sports" => %{"hockey" => 7, "soccer" => 8}}
      } = ret3
    end

    test "updates several documents, returning the old documents", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref3, [:_id, :_key, :_rev]))

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3}
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnOld: true) |> on_db(ctx)

      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 22, "name" => "Jim", "fruit" => %{"apple" => 3, "pear" => 4}}
      } = ret1
      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 33, "name" => "John", "cars" => %{"honda" => 5, "ford" => 6}}
      } = ret2
      assert {
        %Docref{_id: _, _key: _, _oldRev: _, _rev: _},
        %{"_id" => _, "_key" => _, "_rev" => _,
          "age" => 44, "name" => "Jack", "sports" => %{"hockey" => 7, "soccer" => 8}}
      } = ret3
    end

    test "updates several documents, returning the new documents (keepNull = default)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}

      [{:ok, %Docref{_id: id1, _key: key1, _rev: rev1} = dref1},
       {:ok, %Docref{_id: id2, _key: key2, _rev: rev2} = dref2},
       {:ok, %Docref{_id: id3, _key: key3, _rev: rev3} = dref3},
      ] = Document.create(ctx.coll, [old_data, old_data, old_data]) |> on_db(ctx)

      new_data1 = Map.merge(new_data, dref1)
      new_data2 = Map.merge(new_data, dref2)
      new_data3 = Map.merge(new_data, dref3)

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3}
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnNew: true) |> on_db(ctx)

      assert {
        %Docref{_id: ^id1, _key: ^key1, _oldRev: ^rev1},
        %{"_id" => ^id1, "_key" => ^key1, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}
      } = ret1
      assert {
        %Docref{_id: ^id2, _key: ^key2, _oldRev: ^rev2},
        %{"_id" => ^id2, "_key" => ^key2, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}
      } = ret2
      assert {
        %Docref{_id: ^id3, _key: ^key3, _oldRev: ^rev3},
        %{"_id" => ^id3, "_key" => ^key3, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}
      } = ret3
    end

    test "updates several documents, returning the new documents (keepNull = false)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => nil}}

      [{:ok, %Docref{_id: id1, _key: key1, _rev: rev1} = dref1},
       {:ok, %Docref{_id: id2, _key: key2, _rev: rev2} = dref2},
       {:ok, %Docref{_id: id3, _key: key3, _rev: rev3} = dref3},
      ] = Document.create(ctx.coll, [old_data, old_data, old_data]) |> on_db(ctx)

      new_data1 = Map.merge(new_data, dref1)
      new_data2 = Map.merge(new_data, dref2)
      new_data3 = Map.merge(new_data, dref3)

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3}
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnNew: true, keepNull: false) |> on_db(ctx)

      assert {
        %Docref{_id: ^id1, _key: ^key1, _oldRev: ^rev1},
        %{"_id" => ^id1, "_key" => ^key1, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1}}
      } = ret1
      assert {
        %Docref{_id: ^id2, _key: ^key2, _oldRev: ^rev2},
        %{"_id" => ^id2, "_key" => ^key2, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1}}
      } = ret2
      assert {
        %Docref{_id: ^id3, _key: ^key3, _oldRev: ^rev3},
        %{"_id" => ^id3, "_key" => ^key3, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1}}
      } = ret3
    end

    test "updates several documents, returning the old and new documents (mergeObejcts = true (default))", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}

      [{:ok, %Docref{_id: old_id1, _key: old_key1, _rev: old_rev1} = old_dref1},
       {:ok, %Docref{_id: old_id2, _key: old_key2, _rev: old_rev2} = old_dref2},
       {:ok, %Docref{_id: old_id3, _key: old_key3, _rev: old_rev3} = old_dref3},
      ] = Document.create(ctx.coll, [old_data, old_data, old_data]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 43, "fruit" => %{plum: 21, grape: 12}}, Map.take(old_dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 43, "fruit" => %{plum: 22, grape: 12}}, Map.take(old_dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 43, "fruit" => %{plum: 23, grape: 12}}, Map.take(old_dref3, [:_id, :_key, :_rev]))

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3},
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnOld: true, returnNew: true) |> on_db(ctx)

      {%Docref{_id: new_id1, _key: new_key1, _rev: new_rev1}, _old, _new} = ret1
      {%Docref{_id: new_id2, _key: new_key2, _rev: new_rev2}, _old, _new} = ret2
      {%Docref{_id: new_id3, _key: new_key3, _rev: new_rev3}, _old, _new} = ret3

      assert {
        %Docref{_id: ^new_id1, _key: ^new_key1, _rev: ^new_rev1},
        %{"_id" => ^old_id1, "_key" => ^old_key1, "_rev" => ^old_rev1,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id1, "_key" => ^new_key1, "_rev" => ^new_rev1,
          "age" => 43, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20, "plum" => 21, "grape" => 12}},
      } = ret1
      assert {
        %Docref{_id: ^new_id2, _key: ^new_key2, _rev: ^new_rev2},
        %{"_id" => ^old_id2, "_key" => ^old_key2, "_rev" => ^old_rev2,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id2, "_key" => ^new_key2, "_rev" => ^new_rev2,
          "age" => 43, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20, "plum" => 22, "grape" => 12}},
      } = ret2
      assert {
        %Docref{_id: ^new_id3, _key: ^new_key3, _rev: ^new_rev3},
        %{"_id" => ^old_id3, "_key" => ^old_key3, "_rev" => ^old_rev3,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id3, "_key" => ^new_key3, "_rev" => ^new_rev3,
          "age" => 43, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20, "plum" => 23, "grape" => 12}},
      } = ret3
    end

    test "updates a document, returning the old document and new document (mergeObjects = false)", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}

      [{:ok, %Docref{_id: old_id1, _key: old_key1, _rev: old_rev1} = old_dref1},
       {:ok, %Docref{_id: old_id2, _key: old_key2, _rev: old_rev2} = old_dref2},
       {:ok, %Docref{_id: old_id3, _key: old_key3, _rev: old_rev3} = old_dref3},
      ] = Document.create(ctx.coll, [old_data, old_data, old_data]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 43, "fruit" => %{plum: 21, grape: 12}}, Map.take(old_dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 43, "fruit" => %{plum: 22, grape: 12}}, Map.take(old_dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 43, "fruit" => %{plum: 23, grape: 12}}, Map.take(old_dref3, [:_id, :_key, :_rev]))

      [{:ok, ret1},
       {:ok, ret2},
       {:ok, ret3},
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], returnOld: true, returnNew: true, mergeObjects: false) |> on_db(ctx)

      {%Docref{_id: new_id1, _key: new_key1, _rev: new_rev1}, _old, _new} = ret1
      {%Docref{_id: new_id2, _key: new_key2, _rev: new_rev2}, _old, _new} = ret2
      {%Docref{_id: new_id3, _key: new_key3, _rev: new_rev3}, _old, _new} = ret3

      assert {
        %Docref{_id: ^new_id1, _key: ^new_key1, _rev: ^new_rev1},
        %{"_id" => ^old_id1, "_key" => ^old_key1, "_rev" => ^old_rev1,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id1, "_key" => ^new_key1, "_rev" => ^new_rev1,
          "age" => 43, "fruit" => %{"plum" => 21, "grape" => 12}}
      } = ret1
      assert {
        %Docref{_id: ^new_id2, _key: ^new_key2, _rev: ^new_rev2},
        %{"_id" => ^old_id2, "_key" => ^old_key2, "_rev" => ^old_rev2,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id2, "_key" => ^new_key2, "_rev" => ^new_rev2,
          "age" => 43, "fruit" => %{"plum" => 22, "grape" => 12}}
      } = ret2
      assert {
        %Docref{_id: ^new_id3, _key: ^new_key3, _rev: ^new_rev3},
        %{"_id" => ^old_id3, "_key" => ^old_key3, "_rev" => ^old_rev3,
          "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}},
        %{"_id" => ^new_id3, "_key" => ^new_key3, "_rev" => ^new_rev3,
          "age" => 43, "fruit" => %{"plum" => 23, "grape" => 12}}
      } = ret3
    end

    test "updates several documents successfully, with waitForSync", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Enum.reduce([ctx.data1, %{age2: ctx.data1["age"] + 1}, dref1], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{age2: ctx.data2["age"] + 1}, dref2], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{age2: ctx.data3["age"] + 1}, dref3], &Map.merge/2)

      assert [
        {:ok, %Docref{} = _},
        {:ok, %Docref{} = _},
        {:ok, %Docref{} = _}
      ] = Document.update(ctx.coll, [new_data1, new_data2, new_data3], waitForSync: true) |> on_db(ctx)
    end

    test "updates several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3], returnNew: true) |> on_db(ctx)

      new_doc1 = Map.merge(doc1, %{"age" => 51})
      new_doc2 = Map.merge(doc2, %{"age" => 52})
      new_doc3 = Map.merge(doc3, %{"age" => 53})
      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.update(ctx.coll, [new_doc1, new_doc2, new_doc3], returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "fails to update several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3], returnNew: true) |> on_db(ctx)

      new_doc1 = Map.merge(doc1, %{"age" => 51, "_rev" => "foobar"})
      new_doc2 = Map.merge(doc2, %{"age" => 52, "_rev" => "foobar"})
      new_doc3 = Map.merge(doc3, %{"age" => 53, "_rev" => "foobar"})
      assert [
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
      ] = Document.update(ctx.coll, [new_doc1, new_doc2, new_doc3], returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end
  end

  describe "replacing a document" do
    test "replaces a document successfully", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      assert {:ok, _} = Document.replace(docref, new_doc) |> on_db(ctx)
    end

    test "fails to replace an unknown document", ctx do
      assert {:error, %{"code" => 404, "errorMessage" => "document not found"}} =
        Document.replace(%Docref{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}, %{"foo" => 1}) |> on_db(ctx)
    end

    test "replaces a document, returning the new document", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 99}}

      assert {:ok, {%Docref{_id: id, _key: key, _rev: rev}, new}} = Document.replace(docref, new_doc, returnNew: true) |> on_db(ctx)
      assert %{"_id" => id, "_key" => key, "_rev" => rev, "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 99}} == new
    end

    test "replaces a document, returning the old document", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      new_data = %{"age" => 43, "fruit" => %{plum: 2, grape: 12}}

      {:ok, %Docref{_id: id, _key: key, _rev: rev} = old_ref} = Document.create(ctx.coll, old_data) |> on_db(ctx)
      {:ok, {_new_ref, old_returned}} = Document.replace(old_ref, new_data, returnOld: true) |> on_db(ctx)

      assert %{"_id" => id, "_key" => key, "_rev" => rev,
               "age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}
      } == old_returned
    end

    test "replaces a document successful, with waitForSync", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1, waitForSync: true) |> on_db(ctx)
      new_doc = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}
      assert {:ok, _} = Document.replace(docref, new_doc) |> on_db(ctx)
    end

    test "replaces a document, considering revision (ignoreRevs = false)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55})
      assert {:ok, _} = Document.replace(docref, doc2, returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "fails to replace a document, considering revision (ignoreRevs = false)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 77, "_rev" => "foobar"})
      assert {:error, %{"errorNum" => 1200, "errorMessage" => "precondition failed"}} = Document.replace(docref, doc2, returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "replaces a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55})
      assert {:ok, {_, returned}} = Document.replace(docref, doc2, returnNew: true, ifMatch: doc2["_rev"]) |> on_db(ctx)
      assert Map.drop(returned, ["_id", "_key", "_rev"]) == Map.drop(doc2, ["_id", "_key", "_rev"])
    end

    test "fails to replace a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      doc2 = Map.merge(doc, %{"age" => 55, "_rev" => "foobar"})
      assert {:error, %{"errorMessage" => "precondition failed"}} = Document.replace(docref, doc2, returnNew: true, ifMatch: "123456") |> on_db(ctx)
    end
  end

  describe "replaces several documents in a collection" do
    test "replaces several documents successfully", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Enum.reduce([ctx.data1, %{"age2" => ctx.data1["age"] + 1}, dref1], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{"age2" => ctx.data2["age"] + 1}, dref2], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{"age2" => ctx.data3["age"] + 1}, dref3], &Map.merge/2)

      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3]) |> on_db(ctx)
    end

    test "fails to replace_multi an unknown documents", ctx do
      [{:ok, _},
       {:ok, _},
       {:ok, _},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      badref = %{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}
      new_data1 = Enum.reduce([ctx.data1, %{"age2" => ctx.data1["age"] + 1}, badref], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{"age2" => ctx.data2["age"] + 1}, badref], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{"age2" => ctx.data3["age"] + 1}, badref], &Map.merge/2)

      assert [
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3]) |> on_db(ctx)
    end

    test "replaces several documents, returning the new documents", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 31, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 2, "pear" => 20}}, Map.take(dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 33, "fruit" => %{"apple" => 3, "peach" => 3, "pear" => 20}}, Map.take(dref3, [:_id, :_key, :_rev]))

      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3], returnNew: true) |> on_db(ctx)

      assert Map.drop(doc1, ["_id", "_key", "_rev"]) == Map.drop(new_data1, [:_id, :_key, :_rev])
      assert Map.drop(doc2, ["_id", "_key", "_rev"]) == Map.drop(new_data2, [:_id, :_key, :_rev])
      assert Map.drop(doc3, ["_id", "_key", "_rev"]) == Map.drop(new_data3, [:_id, :_key, :_rev])
    end

    test "replaces several documents, returning the old documents", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 31, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}, Map.take(dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 2, "pear" => 20}}, Map.take(dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 33, "fruit" => %{"apple" => 3, "peach" => 3, "pear" => 20}}, Map.take(dref3, [:_id, :_key, :_rev]))

      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3], returnOld: true) |> on_db(ctx)

      assert Map.drop(doc1, ["_id", "_key", "_rev"]) == Map.drop(ctx.data1, [:_id, :_key, :_rev])
      assert Map.drop(doc2, ["_id", "_key", "_rev"]) == Map.drop(ctx.data2, [:_id, :_key, :_rev])
      assert Map.drop(doc3, ["_id", "_key", "_rev"]) == Map.drop(ctx.data3, [:_id, :_key, :_rev])
    end

    test "replaces several documents, returning the old and new documents", ctx do
      old_data = %{"age" => 32, "fruit" => %{"apple" => 3, "peach" => 1, "pear" => 20}}

      [{:ok, old_dref1},
       {:ok, old_dref2},
       {:ok, old_dref3},
      ] = Document.create(ctx.coll, [old_data, old_data, old_data]) |> on_db(ctx)

      new_data1 = Map.merge(%{"age" => 41, "fruit" => %{"plum" => 21, "grape" => 12}}, Map.take(old_dref1, [:_id, :_key, :_rev]))
      new_data2 = Map.merge(%{"age" => 42, "fruit" => %{"plum" => 22, "grape" => 12}}, Map.take(old_dref2, [:_id, :_key, :_rev]))
      new_data3 = Map.merge(%{"age" => 43, "fruit" => %{"plum" => 23, "grape" => 12}}, Map.take(old_dref3, [:_id, :_key, :_rev]))

      [{:ok, {%Docref{}, old_doc1, new_doc1}},
       {:ok, {%Docref{}, old_doc2, new_doc2}},
       {:ok, {%Docref{}, old_doc3, new_doc3}},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3], returnOld: true, returnNew: true) |> on_db(ctx)

      assert Map.drop(old_doc1, ["_id", "_key", "_rev"]) == old_data
      assert Map.drop(old_doc2, ["_id", "_key", "_rev"]) == old_data
      assert Map.drop(old_doc3, ["_id", "_key", "_rev"]) == old_data
      assert Map.drop(new_doc1, ["_id", "_key", "_rev"]) == Map.drop(new_doc1, ["_id", "_key", "_rev"])
      assert Map.drop(new_doc2, ["_id", "_key", "_rev"]) == Map.drop(new_doc2, ["_id", "_key", "_rev"])
      assert Map.drop(new_doc3, ["_id", "_key", "_rev"]) == Map.drop(new_doc3, ["_id", "_key", "_rev"])
    end

    test "replaces several documents successfully, with waitForSync", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      new_data1 = Enum.reduce([ctx.data1, %{"age2" => ctx.data1["age"] + 1}, dref1], &Map.merge/2)
      new_data2 = Enum.reduce([ctx.data2, %{"age2" => ctx.data2["age"] + 1}, dref2], &Map.merge/2)
      new_data3 = Enum.reduce([ctx.data3, %{"age2" => ctx.data3["age"] + 1}, dref3], &Map.merge/2)

      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.replace(ctx.coll, [new_data1, new_data2, new_data3], waitForSync: true) |> on_db(ctx)
    end

    test "replaces several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3], returnNew: true) |> on_db(ctx)

      new_doc1 = Map.merge(doc1, %{"age" => 51})
      new_doc2 = Map.merge(doc2, %{"age" => 52})
      new_doc3 = Map.merge(doc3, %{"age" => 53})
      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.replace(ctx.coll, [new_doc1, new_doc2, new_doc3], returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end

    test "fails to replace several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, {_, doc1}},
       {:ok, {_, doc2}},
       {:ok, {_, doc3}},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3], returnNew: true) |> on_db(ctx)

      new_doc1 = Map.merge(doc1, %{"age" => 51, "_rev" => "foobar"})
      new_doc2 = Map.merge(doc2, %{"age" => 52, "_rev" => "foobar"})
      new_doc3 = Map.merge(doc3, %{"age" => 53, "_rev" => "foobar"})
      assert [
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
      ] = Document.replace(ctx.coll, [new_doc1, new_doc2, new_doc3], returnNew: true, ignoreRevs: false) |> on_db(ctx)
    end
  end

  describe "removing a document" do
    test "removes a document successfully", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)

      assert {:ok, _} = Document.delete(docref) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(docref) |> on_db(ctx)
    end

    test "fails to remove an unknown document", ctx do
      assert {:error, %{"code" => 404, "errorMessage" => "document not found"}} =
        Document.delete(%Docref{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}) |> on_db(ctx)
    end

    test "removes a document, returning the old document", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)

      assert {:ok, {_, deleted}} = Document.delete(docref, returnOld: true) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(docref) |> on_db(ctx)
      assert Map.drop(deleted, ["_id", "_key", "_rev"]) == ctx.data1
    end

    test "removes a document successfully, with waitForSync", ctx do
      {:ok, docref} = Document.create(ctx.coll, ctx.data1) |> on_db(ctx)

      assert {:ok, _} = Document.delete(docref, waitForSync: true) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(docref) |> on_db(ctx)
    end

    test "removes a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, doc}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      assert {:ok, _} = Document.delete(docref, ifMatch: doc["_rev"]) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(docref) |> on_db(ctx)
    end

    test "fails to remove a document conditionally (using If-Match header)", ctx do
      {:ok, {docref, _}} = Document.create(ctx.coll, ctx.data1, returnNew: true) |> on_db(ctx)

      assert {:error, %{"errorMessage" => "precondition failed"}} = Document.delete(docref, returnOld: true, ifMatch: "123456") |> on_db(ctx)
      assert {:ok, _} = Document.document(docref) |> on_db(ctx)
    end
  end

  describe "removing several documents in a collection" do
    test "removes several documents successfully", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      [{:ok, _},
       {:ok, _},
       {:ok, _},
      ] = Document.delete_multi(ctx.coll, [dref1, dref2, dref3]) |> on_db(ctx)

      assert {:error, %{"code" => 404}} = Document.document(dref1) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref2) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref3) |> on_db(ctx)
    end

    test "fails to remove_multi an unknown documents", ctx do
      badref1 = %{_id: "#{ctx.coll.name}/123456", _key: "123456", _rev: "123456"}
      badref2 = %{_id: "#{ctx.coll.name}/123457", _key: "123457", _rev: "123457"}
      badref3 = %{_id: "#{ctx.coll.name}/123458", _key: "123458", _rev: "123458"}

      assert [
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
        {:error, %{"errorMessage" => "document not found"}},
      ] = Document.delete_multi(ctx.coll, [badref1, badref2, badref3]) |> on_db(ctx)
    end

    test "removes several documents, returning the old documents", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      [{:ok, _},
       {:ok, _},
       {:ok, _},
      ] = Document.delete_multi(ctx.coll, [dref1, dref2, dref3], returnOld: true) |> on_db(ctx)

      assert {:error, %{"code" => 404}} = Document.document(dref1) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref2) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref3) |> on_db(ctx)
    end

    test "removes several documents successfully, with waitForSync", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      [{:ok, _},
       {:ok, _},
       {:ok, _},
      ] = Document.delete_multi(ctx.coll, [dref1, dref2, dref3], waitForSync: true) |> on_db(ctx)

      assert {:error, %{"code" => 404}} = Document.document(dref1) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref2) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref3) |> on_db(ctx)
    end

    test "removes several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      assert [
        {:ok, _},
        {:ok, _},
        {:ok, _},
      ] = Document.delete_multi(ctx.coll, [dref1, dref2, dref3], ignoreRevs: false) |> on_db(ctx)

      assert {:error, %{"code" => 404}} = Document.document(dref1) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref2) |> on_db(ctx)
      assert {:error, %{"code" => 404}} = Document.document(dref3) |> on_db(ctx)
    end

    test "fails to remove several documents, considering revision (ignoreRevs = false)", ctx do
      [{:ok, dref1},
       {:ok, dref2},
       {:ok, dref3},
      ] = Document.create(ctx.coll, [ctx.data1, ctx.data2, ctx.data3]) |> on_db(ctx)

      bad_rev1 = Map.merge(dref1, %{"_rev" => "foobar1"})
      bad_rev2 = Map.merge(dref2, %{"_rev" => "foobar2"})
      bad_rev3 = Map.merge(dref3, %{"_rev" => "foobar3"})

      assert [
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
        {:error, %{"errorNum" => 1200, "errorMessage" => "conflict"}}, #"precondition failed"}},
      ] = Document.delete_multi(ctx.coll, [bad_rev1, bad_rev2, bad_rev3], ignoreRevs: false) |> on_db(ctx)

      assert {:ok, _} = Document.document(dref1) |> on_db(ctx)
      assert {:ok, _} = Document.document(dref2) |> on_db(ctx)
      assert {:ok, _} = Document.document(dref3) |> on_db(ctx)
    end
  end
end
