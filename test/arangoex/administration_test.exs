defmodule AdministrationTest do
  use Arangoex.TestCase
  doctest Arangoex

  alias Arangoex.Administration

  test "returns target_version", ctx do
    assert {
      :ok, %{"code" => 200, "error" => false, "version" => "30010"}
    } == Administration.target_version(ctx.endpoint)
  end

  test "returns echo", ctx do
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
        "url" => "/_admin/echo?bar=2&foo=1",
        "user" => "root"
      }
    } = Administration.echo(ctx.endpoint, %{"foo" => 1, "bar" => 2}, %{"myHeader" => 3, "yourHeader" => 4})
  end

  test "executes a program", ctx do
    assert {
      :ok, %{"code" => 200, "error" => false}
    } == Administration.execute(ctx.endpoint, "1")

    assert {
      :ok, "1"
    } == Administration.execute(ctx.endpoint, "return 1;")

    assert {
      :ok, "1"
    } == Administration.execute(ctx.endpoint, "return 1;", returnAsJson: true)

    assert {
      :ok, "{\"a\":1,\"b\":2}"
    } == Administration.execute(ctx.endpoint, "return {a: 1, b: 2};")

    assert {
      :ok, "{\"a\":1,\"b\":2}"
    } == Administration.execute(ctx.endpoint, "return {a: 1, b: 2};", returnAsJson: true)
  end

  @tag :wip
  test "reads global logs from the server", ctx do
    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, upto: 3)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 <= 3))

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, level: 3)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert Enum.all?(level, &(&1 == 3))

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, start: 2)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
   
    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, size: 2)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
    assert length(level) <= 2
    
    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, offset: 2)
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)
        
    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, search: "foo")
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)

    assert {
      :ok, %{"level" => level, "lid" => lid, "text" => text, "timestamp" => timestamp, "totalAmount" => _}
    } = Administration.log(ctx.endpoint, sort: "asc")
    assert is_list(level)
    assert is_list(lid)
    assert is_list(text)
    assert is_list(timestamp)    
  end

  # test "returns long_echo", ctx do
  #   assert {
  #     :ok, %{
  #       "client" => _,
  #       "cookies" => %{},
  #       "database" => "_system",
  #       "headers" => %{
  #         "accept" => "*/*",
  #         "authorization" => _,
  #         "content-length" => "0",
  #         "host" => _,
  #         "user-agent" => _,
  #         "my-header" => "3",
  #         "your-header" => "4",
  #       },
  #       "internals" => %{},
  #       "parameters" => %{"bar" => "2", "foo" => "1"},
  #       "path" => "/",
  #       "prefix" => "/",
  #       "protocol" => "http",
  #       "rawRequestBody" => [],
  #       "requestType" => "GET",
  #       "server" => _,
  #       "suffix" => [],
  #       "url" => "/_admin/long_echo?bar=2&foo=1",
  #       "user" => "root"
  #     }
  #   } = Administration.long_echo(ctx.endpoint, %{"foo" => 1, "bar" => 2}, %{"myHeader" => 3, "yourHeader" => 4})
  # end

  test "reloads routing", ctx do
    assert {
      :ok, %{"code" => 200, "error" => false}
    } == Administration.routing_reload(ctx.endpoint)
  end

  test "gets the server id", ctx do
    assert {
      :error, %HTTPoison.Response{body: body, status_code: 500}
    } = Administration.server_id(ctx.endpoint)
    assert Regex.match?(~r/ArangoDB is not running in cluster mode/, body)
  end

  test "gets the server role", ctx do
    assert {
      :ok, %{"code" => 200, "error" => false, "role" => "SINGLE"}
    } = Administration.server_role(ctx.endpoint)
  end

  test "shutdown", ctx do
    # assert {
    #   :ok, "OK"
    # } == Administration.shutdown(ctx.endpoint)
    assert {ctx, "It's hard to test this since it shuts down the server..."}
  end

  test "sleep", ctx do
    assert {
      :ok, %{"code" => 200, "duration" => 0.1, "error" => false}
    } = Administration.sleep(ctx.endpoint, duration: 0.1)
  end

  test "statistics", ctx do
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
    } = Administration.statistics(ctx.endpoint)
  end

  test "statistics_description", ctx do
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
    } = Administration.statistics_description(ctx.endpoint)
  end

  test "runs tests on the server", ctx do
    # what are some sample test names?
    assert {
      :error, %{
        "code" => 400,
        "error" => true,
        "errorNum" => 400,
        "errorMessage" => "expected attribute 'tests' is missing"
      }
    } == Administration.test(ctx.endpoint)
  end

  test "returns the system time", ctx do
    assert {
      :ok, %{"code" => 200, "error" => false, "time" => _}
    } = Administration.time(ctx.endpoint)
  end

  test "lists all endpoints", ctx do
    assert {
      :ok, [%{"endpoint" => "http://0.0.0.0:8529"}]
    } = Administration.endpoints(ctx.endpoint)
  end

  test "creates a task", ctx do
    task = %Administration.Task{ 
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    
    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => "(function(params) { require('@arangodb').print(params); })(params)",
        "created" => _,
        "database" => "_system",
        "id" => _,
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = Administration.task_create(ctx.endpoint, task)
  end

  test "lists a task or tasks", ctx do
     {:ok, tasks} = Administration.tasks(ctx.endpoint)
     assert [
        %{
          "command" => "(function () {\n        require('@arangodb/foxx/queues/manager').manage();\n      })(params)",
          "created" => _,
          "database" => "_system",
          "id" => "149",
          "name" => "user-defined task",
          "period" => 1,
          "type" => "periodic"
        },
        %{
          "command" => "require('@arangodb/statistics').garbageCollector();",
          "created" => _,
          "database" => "_system",
          "id" => "statistics-gc",
          "name" => "statistics-gc",
          "period" => 450,
          "type" => "periodic"
        },
        %{
          "command" => "require('@arangodb/statistics').historian();",
          "created" => _,
          "database" => "_system",
          "id" => "statistics-collector",
          "name" => "statistics-collector",
          "period" => 10,
          "type" => "periodic"
        },
        %{
          "command" => "require('@arangodb/statistics').historianAverage();",
          "created" => _,
          "database" => "_system",
          "id" => "statistics-average-collector",
          "name" => "statistics-average-collector",
          "period" => 900,
          "type" => "periodic"
        },
      ] = Enum.sort(tasks)
  end

  test "deletes a task", ctx do
    assert {
      :error, %{
        "code" => 404,
        "error" => true,
        "errorNum" => 1852,
        "errorMessage" => "task not found"
      }
    } = Administration.task_delete(ctx.endpoint, "1234")
    
    task = %Administration.Task{ 
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    {:ok, %{"id" => task_id}} = Administration.task_create(ctx.endpoint, task)

    assert {
      :ok, %{"code" => 200, "error" => false}
    } = Administration.task_delete(ctx.endpoint, task_id)
  end

  test "fetch a task by id", ctx do
    task = %Administration.Task{ 
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    {:ok, %{"id" => task_id}} = Administration.task_create(ctx.endpoint, task)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => "(function(params) { require('@arangodb').print(params); })(params)",
        "created" => _,
        "database" => "_system",
        "id" => ^task_id,
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = Administration.task(ctx.endpoint, task_id)    
  end

  test "create a task by id", ctx do
    task = %Administration.Task{ 
      name: "SampleTask", 
      command: "(function(params) { require('@arangodb').print(params); })(params)", 
      params: %{ 
        foo: "fooey",
        bar: "barey"
      }, 
      period: 2 
    }
    assert {:ok, _} = Administration.task_create_with_id(ctx.endpoint, "foobar", task)

    assert {
      :ok, %{
        "code" => 200,
        "error" => false,
        "command" => "(function(params) { require('@arangodb').print(params); })(params)",
        "created" => _,
        "database" => "_system",
        "id" => "foobar",
        "name" => "SampleTask",
        "period" => 2,
        "type" => "periodic"
      }
    } = Administration.task(ctx.endpoint, "foobar")
  end

  test "fetches the server version", ctx do
    assert {
      :ok, %{"server" => "arango", "version" => _}
    } = Administration.version(ctx.endpoint)    
  end  
 end
