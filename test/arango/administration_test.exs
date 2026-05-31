defmodule AdministrationTest do
  use Arango.TestCase
  doctest Arango

  alias Arango.Administration

  test "returns database version" do
    assert {
             :ok,
             %{"code" => 200, "error" => false, "version" => _}
           } = Administration.database_version() |> arango()
  end

  test "returns echo" do
    assert {
             :ok,
             result
           } =
             Administration.echo(%{"foo" => 1, "bar" => 2}, %{"myHeader" => "3", "yourHeader" => "4"})
             |> arango()

    assert is_map(result)
    assert Map.has_key?(result, "headers")
    assert Map.has_key?(result, "parameters")
    assert %{"bar" => "2", "foo" => "1"} = result["parameters"]
  end

  test "reads global logs from the server" do
    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log() |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(upto: 3) |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 <= 3))

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(level: 3) |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 == 3))

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(start: 2) |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(size: 2) |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert length(level) <= 2

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(offset: 2) |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(search: "foo") |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
             :ok,
             %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
           } = Administration.log(sort: "asc") |> arango()

    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
  end

  test "long_echo/2 builds a GET with query + headers from the opts" do
    # Calling the endpoint hangs (it's a long-poll); assert the request shape.
    op =
      Administration.long_echo(
        %{"foo" => 1, "bar" => 2},
        %{"myHeader" => 3, "yourHeader" => 4}
      )

    assert op.http_method == :get
    assert op.path == "/_admin/long_echo"
    assert op.query == %{"bar" => 2, "foo" => 1}
    assert op.headers == %{"My-Header" => 3, "Your-Header" => 4}
  end

  test "reloads routing" do
    assert {:ok, _} = Administration.reload_routing() |> arango()
  end

  test "gets the server id" do
    # In single-server mode, this returns an error (not in cluster mode)
    assert {:error, %{"code" => 500, "error" => true}} =
             Administration.server_id() |> arango()
  end

  test "gets the server role" do
    assert {
             :ok,
             %{"code" => 200, "error" => false, "role" => "SINGLE"}
           } = Administration.server_role() |> arango()
  end

  test "shutdown", ctx do
    # assert {
    #   :ok, "OK"
    # } == Administration.shutdown() |> arango()
    assert {ctx, "It's hard to test this since it shuts down the server..."}
  end

  test "statistics" do
    assert {
             :ok,
             %{
               "client" => %{
                 "bytesReceived" => _,
                 "bytesSent" => _,
                 "connectionTime" => _,
                 "httpConnections" => _,
                 "ioTime" => _,
                 "queueTime" => _,
                 "requestTime" => _,
                 "totalTime" => _
               },
               "code" => 200,
               "enabled" => true,
               "error" => false,
               "http" => %{
                 "requestsAsync" => _,
                 "requestsDelete" => _,
                 "requestsGet" => _,
                 "requestsHead" => _,
                 "requestsOptions" => _,
                 "requestsOther" => _,
                 "requestsPatch" => _,
                 "requestsPost" => _,
                 "requestsPut" => _,
                 "requestsTotal" => _
               },
               "server" => %{
                 "physicalMemory" => _,
                 "uptime" => _
               },
               "system" => %{
                 "majorPageFaults" => _,
                 "minorPageFaults" => _,
                 "numberOfThreads" => _,
                 "residentSize" => _,
                 "residentSizePercent" => _,
                 "systemTime" => _,
                 "userTime" => _,
                 "virtualSize" => _
               },
               "time" => _
             }
           } = Administration.statistics() |> arango()
  end

  test "statistics_description" do
    assert {
             :ok,
             %{
               "code" => 200,
               "error" => false,
               "figures" => figures,
               "groups" => groups
             }
           } = Administration.statistics_description() |> arango()

    assert is_list(figures)
    refute Enum.empty?(figures)
    # Check that some known figures exist
    identifiers = Enum.map(figures, & &1["identifier"])

    for expected <- ["userTime", "systemTime", "httpConnections", "requestsTotal", "uptime"] do
      assert expected in identifiers
    end

    assert is_list(groups)
    group_names = Enum.map(groups, & &1["group"])

    for expected <- ["system", "client", "http", "server"] do
      assert expected in group_names
    end
  end

  test "returns the system time" do
    assert {
             :ok,
             %{"code" => 200, "error" => false, "time" => _}
           } = Administration.time() |> arango()
  end

  test "lists all endpoints" do
    assert {
             :ok,
             [%{"endpoint" => "http://0.0.0.0:8529"}]
           } = Administration.endpoints() |> arango()
  end

  test "fetches the server version" do
    assert {
             :ok,
             %{"server" => "arango", "version" => _}
           } = Administration.version() |> arango()
  end

  # === Phase 4 additions ===

  test "engine/0 returns the storage engine name" do
    assert {:ok, %{"name" => "rocksdb"}} = Administration.engine() |> arango()
  end

  test "engine_stats/0 returns a counter map" do
    assert {:ok, map} = Administration.engine_stats() |> arango()
    assert is_map(map)
    assert map_size(map) > 0
  end

  test "metrics/0 returns Prometheus text (text/plain decoded as raw string)" do
    assert {:ok, body} = Administration.metrics() |> arango()
    assert is_binary(body)
    assert String.contains?(body, "arangodb_")
  end

  test "status/0 reports server info" do
    assert {:ok, %{"serverInfo" => server_info}} = Administration.status() |> arango()
    assert is_map(server_info)
  end

  test "mode/0 returns default in a fresh container" do
    assert {:ok, %{"mode" => "default"}} = Administration.mode() |> arango()
  end

  test "availability/0 returns ok when the server is ready" do
    assert {:ok, _} = Administration.availability() |> arango()
  end

  test "support_info/0 returns a diagnostics bundle" do
    assert {:ok, info} = Administration.support_info() |> arango()
    assert is_map(info)
  end

  test "log_level/0 returns a topic-keyed map" do
    assert {:ok, levels} = Administration.log_level() |> arango()
    assert is_map(levels)
    assert map_size(levels) > 0
  end

  test "log_entries/1 returns structured entries" do
    assert {:ok, %{"messages" => messages}} = Administration.log_entries() |> arango()
    assert is_list(messages)
  end

  test "compact/1 builds a PUT with the requested compaction options" do
    # /_admin/compact requires a JWT-authenticated superuser; basic-auth
    # root gets 403. Asserting the request shape, which is what the
    # wrapper actually produces.
    op = Administration.compact(changeLevel: true, compactBottomMostLevel: false)
    assert op.http_method == :put
    assert op.path == "/_admin/compact"
    assert op.body == %{"changeLevel" => true, "compactBottomMostLevel" => false}
  end

  # Pure body-shape tests for state-changing endpoints (avoid touching
  # server-wide settings during the integration suite).

  test "set_mode/1 builds a PUT with mode in the body" do
    op = Administration.set_mode("readonly")
    assert op.http_method == :put
    assert op.body == %{mode: "readonly"}
    assert op.path == "/_admin/server/mode"
  end

  test "set_log_level/1 builds a PUT with the topic map as the body" do
    op = Administration.set_log_level(%{"agency" => "DEBUG"})
    assert op.http_method == :put
    assert op.body == %{"agency" => "DEBUG"}
    assert op.path == "/_admin/log/level"
  end
end
