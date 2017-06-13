defmodule Arangoex.Task do
  @moduledoc "ArangoDB Administration methods"

  alias Arangoex.Endpoint

  defstruct [
    :name,
    :command,
    :params,
    :period,
    :offset
  ]
  use ExConstructor

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

  @doc """
  Creates a task

  POST /_api/tasks
  """
  @spec create(Endpoint.t, t) :: Arangoex.ok_error(map)
  def create(endpoint, task) do
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
  @spec delete(Endpoint.t, String.t) :: Arangoex.ok_error(map)
  def delete(endpoint, task_id) do
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
  @spec create_with_id(Endpoint.t, String.t, Task.t) :: Arangoex.ok_error(map)
  def create_with_id(endpoint, task_id, task) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.put("tasks/#{task_id}", task)
  end
end
