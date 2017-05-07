defmodule Arangoex.Administration do
  @moduledoc "ArangoDB Administration methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils

  defmodule Task do
    @moduledoc false
    
    defstruct [:name, :command, :params, :period, :offset]

    @type t :: %__MODULE__{
      # The name of the task
      name: String.t,

      # The JavaScript code to be executed      
      command: String.t,

      # The parameters to be passed into command
      params: map,

      # Number of seconds between the executions
      period: non_neg_integer,

      # Number of seconds initial delay      
      offset: nil | non_neg_integer,      
    }
  end
  
  @doc """
  Return the required version of the database
  
  GET /_admin/database/target-version
  """
  @spec target_version(Endpoint.t) :: Arangoex.ok_error(map)
  def target_version(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/database/target-version")
  end
  
  @doc """
  Return current request
    
  GET /_admin/echo
  """
  @spec echo(Endpoint.t) :: Arangoex.ok_error(map)
  def echo(endpoint, query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/echo#{query}", headers)
  end

  @doc """
  Execute program
  
  POST /_admin/execute
  """
  @spec execute(Endpoint.t, String.t, keyword) :: Arangoex.ok_error(map)
  def execute(endpoint, code, opts \\ []) do
    query = Utils.opts_to_query(opts, [:returnAsJson])
    
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.post_raw("/_admin/execute#{query}", code)
  end

  @doc """
  Read global logs from the server
  
  GET /_admin/log
  """
  @spec log(Endpoint.t) :: Arangoex.ok_error(map)
  def log(endpoint, opts \\ []) do
    query = Utils.opts_to_query(opts, [:upto, :level, :start, :size, :offset, :search, :sort])
    
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/log#{query}")
  end
  
  @doc """
  Return current request and continues
    
  GET /_admin/long_echo
  """
  @spec long_echo(Endpoint.t) :: Arangoex.ok_error(map)
  def long_echo(endpoint, query_opts \\ [], header_opts \\ []) do
    headers = Utils.opts_to_headers(header_opts, [:*])
    query = Utils.opts_to_query(query_opts, [:*])

    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/long_echo#{query}", headers)
  end
  
  @doc """
  Reloads the routing information
  
  POST /_admin/routing/reload
  """
  @spec routing_reload(Endpoint.t) :: Arangoex.ok_error(map)
  def routing_reload(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.post("/_admin/routing/reload")
  end
  
  @doc """
  Return id of a server in a cluster
  
  GET /_admin/server/id
  """
  @spec server_id(Endpoint.t) :: Arangoex.ok_error(map)
  def server_id(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/server/id")
  end
  
  @doc """
  Return role of a server in a cluster
  
  GET /_admin/server/role
  """
  @spec server_role(Endpoint.t) :: Arangoex.ok_error(map)
  def server_role(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/server/role")
  end
  
  @doc """
  Initiate shutdown sequence
  
  DELETE /_admin/shutdown
  """
  @spec shutdown(Endpoint.t) :: Arangoex.ok_error(map)
  def shutdown(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.delete("/_admin/shutdown")
  end
  
  @doc """
  Sleep for a specified amount of seconds
  
  GET /_admin/sleep
  """
  @spec sleep(Endpoint.t, keyword) :: Arangoex.ok_error(map)
  def sleep(endpoint, opts \\ []) do
    query = Utils.opts_to_query(opts, [:duration])
    
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/sleep#{query}")
  end
  
  @doc """
  Read the statistics
  
  GET /_admin/statistics
  """
  @spec statistics(Endpoint.t) :: Arangoex.ok_error(map)
  def statistics(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/statistics")
  end
  
  @doc """
  Statistics description
  
  GET /_admin/statistics-description
  """
  @spec statistics_description(Endpoint.t) :: Arangoex.ok_error(map)
  def statistics_description(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/statistics-description")
  end
  
  @doc """
  Runs tests on server
  
  POST /_admin/test
  """
  @spec test(Endpoint.t) :: Arangoex.ok_error(map)
  def test(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.post("/_admin/test")
  end
  
  @doc """
  Return system time
  
  GET /_admin/time
  """
  @spec time(Endpoint.t) :: Arangoex.ok_error(map)
  def time(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("/_admin/time")
  end
  
  @doc """
  Return list of all endpoints
  
  GET /_api/endpoint
  """
  @spec endpoints(Endpoint.t) :: Arangoex.ok_error(map)
  def endpoints(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("endpoint")
  end
  
  @doc """
  Creates a task
  
  POST /_api/tasks
  """
  @spec task_create(Endpoint.t, Task.t) :: Arangoex.ok_error(map)
  def task_create(endpoint, task) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.post("tasks", task)
  end
  
  @doc """
  Fetch all tasks or one task
  
  GET /_api/tasks
  """
  @spec tasks(Endpoint.t) :: Arangoex.ok_error(map)
  def tasks(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("tasks")
  end
  
  @doc """
  Deletes the task with id
  
  DELETE /_api/tasks/{id}
  """
  @spec task_delete(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def task_delete(endpoint, task_id) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.delete("tasks/#{task_id}")
  end
  
  @doc """
  Fetch one task with id
  
  GET /_api/tasks/{id}
  """
  @spec task(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def task(endpoint, task_id) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("tasks/#{task_id}")
  end
  
  @doc """
  Creates a task with id
  
  PUT /_api/tasks/{id}
  """
  @spec task_create_with_id(Endpoint.t, String.t, Task.t) :: Arangoex.ok_error(map)
  def task_create_with_id(endpoint, task_id, task) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.put("tasks/#{task_id}", task)
  end
  
  @doc """
  Return server version
  
  GET /_api/version
  """
  @spec version(Endpoint.t) :: Arangoex.ok_error(map)
  def version(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")    
    |> Endpoint.get("version")
  end
end
