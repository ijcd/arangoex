defmodule AdministrationTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Administration

  test "returns database version" do
    assert {
      :ok, %{"code" => 200, "error" => false, "version" => _}
    }  = Administration.database_version() |> arango
  end

  test "returns echo" do
    assert {
      :ok, %{
        "client" => _,
        "cookies" => %{},
        "database" => "_system",
        "headers" => %{
          "accept" => "*/*",
          "authorization" => _,
          "host" => _,
          "my-header" => "3",
          "your-header" => "4",
        },
        "internals" => %{},
        "parameters" => %{"bar" => "2", "foo" => "1"},
        "path" => "/",
        "prefix" => "/",
        "protocol" => "http",
        "rawRequestBody" => [],
        "requestType" => "GET",
        "server" => _,
        "suffix" => [],
        "url" => "/_admin/echo?bar=2&foo=1",
        "user" => "root"
      }
    } = Administration.echo(%{"foo" => 1, "bar" => 2}, %{"myHeader" => 3, "yourHeader" => 4}) |> arango
  end

  test "executes a program" do
    assert {
      :ok, %{"code" => 200, "error" => false}
    } == Administration.execute("1") |> arango

    assert {
      :ok, "1"
    } == Administration.execute("return 1;") |> arango

    assert {
      :ok, "1"
    } == Administration.execute("return 1;", returnAsJson: true) |> arango

    assert {
      :ok, "{\"a\":1,\"b\":2}"
    } == Administration.execute("return {a: 1, b: 2};") |> arango

    assert {
      :ok, "{\"a\":1,\"b\":2}"
    } == Administration.execute("return {a: 1, b: 2};", returnAsJson: true) |> arango
  end

  test "reads global logs from the server" do
    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log() |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(upto: 3) |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 <= 3))

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(level: 3) |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 == 3))

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(start: 2) |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(size: 2) |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert length(level) <= 2

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(offset: 2) |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(search: "foo") |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(sort: "asc") |> arango
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
  end

  @tag :skip
  # times out
  test "returns long_echo" do
    assert {
      :ok, %{
        "client" => _,
        "cookies" => %{},
        "database" => "_system",
        "headers" => %{
          "accept" => "*/*",
          "authorization" => _,
          "content-length" => "0",
          "host" => _,
          "user-agent" => _,
          "my-header" => "3",
          "your-header" => "4",
        },
        "internals" => %{},
        "parameters" => %{"bar" => "2", "foo" => "1"},
        "path" => "/",
        "prefix" => "/",
        "protocol" => "http",
        "rawRequestBody" => [],
        "requestType" => "GET",
        "server" => _,
        "suffix" => [],
        "url" => "/_admin/long_echo?bar=2&foo=1",
        "user" => "root"
      }
    } = Administration.long_echo(%{"foo" => 1, "bar" => 2}, %{"myHeader" => 3, "yourHeader" => 4}) |> arango
  end

  test "reloads routing" do
    assert {
      :ok, %{"code" => 200, "error" => false}
    } == Administration.reload_routing() |> arango
  end

  test "gets the server id" do
    assert {
      :error, %{"status" => 500, "resp_body" => resp_body}
    } = Administration.server_id() |> arango
    assert Regex.match?(~r/ArangoDB is not running in cluster mode/, resp_body)
  end

  test "gets the server role" do
    assert {
      :ok, %{"code" => 200, "error" => false, "role" => "SINGLE"}
    } = Administration.server_role() |> arango
  end

  test "shutdown", ctx do
    # assert {
    #   :ok, "OK"
    # } == Administration.shutdown() |> arango
    assert {ctx, "It's hard to test this since it shuts down the server..."}
  end

  test "sleep" do
    assert {
      :ok, %{"code" => 200, "duration" => 0.1, "error" => false}
    } = Administration.sleep(duration: 0.1) |> arango
  end

  test "statistics" do
    assert {
      :ok, %{
        "client" => %{
          "bytesReceived" => _,
          "bytesSent" => _,
          "connectionTime" => _,
          "httpConnections" => _,
          "ioTime" => _,
          "queueTime" => _,
          "requestTime" => _,
          "totalTime" => _,
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
          "uptime" => _,
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
    } = Administration.statistics() |> arango
  end

  test "statistics_description" do
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "figures" => [
          %{
            "description" => "Amount of time that this process has been scheduled in user mode, measured in seconds.",
            "group" => "system", "identifier" => "userTime",
            "name" => "User Time", "type" => "accumulated",
            "units" => "seconds"
          },
          %{
            "description" => "Amount of time that this process has been scheduled in kernel mode, measured in seconds.",
            "group" => "system", "identifier" => "systemTime",
            "name" => "System Time", "type" => "accumulated",
            "units" => "seconds"
          },
          %{
            "description" => "Number of threads in the arangod process.",
            "group" => "system", "identifier" => "numberOfThreads",
            "name" => "Number of Threads", "type" => "current",
            "units" => "number"
          },
          %{
            "description" => "The total size of the number of pages the process has in real memory. This is just the pages which count toward text, data, or stack space. This does not include pages which have not been demand-loaded in, or which are swapped out. The resident set size is reported in bytes.",
            "group" => "system", "identifier" => "residentSize",
            "name" => "Resident Set Size", "type" => "current",
            "units" => "bytes"
          },
          %{
            "description" => "The percentage of physical memory used by the process as resident set size.",
            "group" => "system", "identifier" => "residentSizePercent",
            "name" => "Resident Set Size", "type" => "current",
            "units" => "percent"
          },
          %{
            "description" => "On Windows, this figure contains the total amount of memory that the memory manager has committed for the arangod process. On other systems, this figure contains The size of the virtual memory the process is using.",
            "group" => "system", "identifier" => "virtualSize",
            "name" => "Virtual Memory Size", "type" => "current",
            "units" => "bytes"
          },
          %{
            "description" => "The number of minor faults the process has made which have not required loading a memory page from disk. This figure is not reported on Windows.",
            "group" => "system", "identifier" => "minorPageFaults",
            "name" => "Minor Page Faults", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "On Windows, this figure contains the total number of page faults. On other system, this figure contains the number of major faults the process has made which have required loading a memory page from disk.",
            "group" => "system", "identifier" => "majorPageFaults",
            "name" => "Major Page Faults", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "The number of connections that are currently open.",
            "group" => "client", "identifier" => "httpConnections",
            "name" => "Client Connections", "type" => "current",
            "units" => "number"
          },
          %{"cuts" => [0.01, 0.05, 0.1, 0.2, 0.5, 1],
            "description" => "Total time needed to answer a request.",
            "group" => "client", "identifier" => "totalTime",
            "name" => "Total Time", "type" => "distribution",
            "units" => "seconds"
          },
          %{"cuts" => [0.01, 0.05, 0.1, 0.2, 0.5, 1],
            "description" => "Request time needed to answer a request.",
            "group" => "client", "identifier" => "requestTime",
            "name" => "Request Time", "type" => "distribution",
            "units" => "seconds"
          },
          %{"cuts" => [0.01, 0.05, 0.1, 0.2, 0.5, 1],
            "description" => "Queue time needed to answer a request.",
            "group" => "client", "identifier" => "queueTime",
            "name" => "Queue Time", "type" => "distribution",
            "units" => "seconds"
          },
          %{"cuts" => [250, 1000, 2000, 5000, 10_000],
            "description" => "Bytes sents for a request.",
            "group" => "client", "identifier" => "bytesSent",
            "name" => "Bytes Sent", "type" => "distribution",
            "units" => "bytes"
          },
          %{"cuts" => [250, 1000, 2000, 5000, 10_000],
            "description" => "Bytes receiveds for a request.",
            "group" => "client", "identifier" => "bytesReceived",
            "name" => "Bytes Received", "type" => "distribution",
            "units" => "bytes"
          },
          %{"cuts" => [0.1, 1, 60],
            "description" => "Total connection time of a client.",
            "group" => "client", "identifier" => "connectionTime",
            "name" => "Connection Time", "type" => "distribution",
            "units" => "seconds"
          },
          %{
            "description" => "Total number of HTTP requests.",
            "group" => "http", "identifier" => "requestsTotal",
            "name" => "Total requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of asynchronously executed HTTP requests.",
            "group" => "http", "identifier" => "requestsAsync",
            "name" => "Async requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP GET requests.",
            "group" => "http", "identifier" => "requestsGet",
            "name" => "HTTP GET requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP HEAD requests.",
            "group" => "http", "identifier" => "requestsHead",
            "name" => "HTTP HEAD requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP POST requests.",
            "group" => "http", "identifier" => "requestsPost",
            "name" => "HTTP POST requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP PUT requests.",
            "group" => "http", "identifier" => "requestsPut",
            "name" => "HTTP PUT requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP PATCH requests.",
            "group" => "http", "identifier" => "requestsPatch",
            "name" => "HTTP PATCH requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP DELETE requests.",
            "group" => "http", "identifier" => "requestsDelete",
            "name" => "HTTP DELETE requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of HTTP OPTIONS requests.",
            "group" => "http", "identifier" => "requestsOptions",
            "name" => "HTTP OPTIONS requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of other HTTP requests.",
            "group" => "http", "identifier" => "requestsOther",
            "name" => "other HTTP requests", "type" => "accumulated",
            "units" => "number"
          },
          %{
            "description" => "Number of seconds elapsed since server start.",
            "group" => "server", "identifier" => "uptime",
            "name" => "Server Uptime", "type" => "current",
            "units" => "seconds"
          },
          %{
            "description" => "Physical memory in bytes.",
            "group" => "server", "identifier" => "physicalMemory",
            "name" => "Physical Memory", "type" => "current",
            "units" => "bytes"
          }
        ],
        "groups" => [
          %{
            "description" => "Statistics about the ArangoDB process",
            "group" => "system", "name" => "Process Statistics"
          },
          %{
            "description" => "Statistics about the connections.",
            "group" => "client", "name" => "Client Connection Statistics"
          },
          %{
            "description" => "Statistics about the HTTP requests.",
            "group" => "http", "name" => "HTTP Request Statistics"
          },
          %{
            "description" => "Statistics about the ArangoDB server",
            "group" => "server", "name" => "Server Statistics"
          }
        ]
      }
    } = Administration.statistics_description() |> arango
  end

  test "runs tests on the server" do
    # what are some sample test names?
    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorNum" => 400,
        "errorMessage" => "expected attribute 'tests' is missing"
      }
    } == Administration.test() |> arango
  end

  test "returns the system time" do
    assert {
      :ok, %{"code" => 200, "error" => false, "time" => _}
    } = Administration.time() |> arango
  end

  test "lists all endpoints" do
    assert {
      :ok, [%{"endpoint" => "http://0.0.0.0:8529"}]
    } = Administration.endpoints() |> arango
  end

  test "fetches the server version" do
    assert {
      :ok, %{"server" => "arango", "version" => _}
    } = Administration.version() |> arango
  end
end
