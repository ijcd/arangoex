defmodule ViewTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.View
  alias Arango.Index

  test "views/0 returns an empty list on a fresh db", ctx do
    assert {:ok, %{"result" => []}} = View.views() |> on_db(ctx)
  end

  test "create_arangosearch/2 with empty opts creates a view", ctx do
    assert {:ok, %{"name" => "v1", "type" => "arangosearch", "id" => _}} =
             View.create_arangosearch("v1") |> on_db(ctx)
  end

  test "create_arangosearch/2 with links links a collection", ctx do
    {:ok, _} =
      View.create_arangosearch("v_links",
        links: %{ctx.coll.name => %{"includeAllFields" => true}}
      )
      |> on_db(ctx)

    {:ok, props} = View.properties("v_links") |> on_db(ctx)
    assert Map.has_key?(props["links"], ctx.coll.name)
  end

  test "create_search_alias/2 with indexes creates a search-alias view", ctx do
    # search-alias references inverted indexes by NAME, not by full id.
    {:ok, _} = Index.create_inverted(ctx.coll.name, ["foo"], name: "inv_for_alias") |> on_db(ctx)

    assert {:ok, %{"type" => "search-alias", "name" => "v_alias"}} =
             View.create_search_alias(
               "v_alias",
               [%{"collection" => ctx.coll.name, "index" => "inv_for_alias"}]
             )
             |> on_db(ctx)
  end

  test "view/1 returns the summary (no links/indexes block)", ctx do
    {:ok, _} = View.create_arangosearch("v_sum") |> on_db(ctx)

    assert {:ok, %{"name" => "v_sum", "type" => "arangosearch", "id" => _}} =
             View.view("v_sum") |> on_db(ctx)
  end

  test "properties/1 returns the full properties block", ctx do
    {:ok, _} = View.create_arangosearch("v_props") |> on_db(ctx)
    {:ok, props} = View.properties("v_props") |> on_db(ctx)
    assert is_integer(props["consolidationIntervalMsec"])
    assert Map.has_key?(props, "links")
  end

  test "update_properties/2 patches an arangosearch view", ctx do
    {:ok, _} = View.create_arangosearch("v_upd") |> on_db(ctx)
    {:ok, _} = View.update_properties("v_upd", %{"commitIntervalMsec" => 2000}) |> on_db(ctx)

    {:ok, props} = View.properties("v_upd") |> on_db(ctx)
    assert props["commitIntervalMsec"] == 2000
  end

  test "replace_properties/2 replaces an arangosearch view", ctx do
    {:ok, _} =
      View.create_arangosearch("v_rep",
        links: %{ctx.coll.name => %{"includeAllFields" => true}}
      )
      |> on_db(ctx)

    {:ok, _} = View.replace_properties("v_rep", %{"links" => %{}}) |> on_db(ctx)

    {:ok, props} = View.properties("v_rep") |> on_db(ctx)
    assert props["links"] == %{}
  end

  test "rename/2 renames on single-server (or surfaces 501 on cluster)", ctx do
    {:ok, _} = View.create_arangosearch("v_ren") |> on_db(ctx)

    case View.rename("v_ren", "v_renamed") |> on_db(ctx) do
      # Single-server: server returns the renamed view.
      {:ok, %{"name" => "v_renamed"}} -> :ok
      # Cluster: rename isn't implemented at this path.
      {:error, %{"code" => 501}} -> :ok
      other -> flunk("unexpected response: #{inspect(other)}")
    end
  end

  test "drop/1 removes a view", ctx do
    {:ok, _} = View.create_arangosearch("v_drop") |> on_db(ctx)
    assert {:ok, %{"result" => true}} = View.drop("v_drop") |> on_db(ctx)
    assert {:error, %{"code" => 404}} = View.view("v_drop") |> on_db(ctx)
  end
end
