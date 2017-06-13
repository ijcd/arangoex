defmodule Arangoex.Task do
  @moduledoc "ArangoDB Administration methods"

  alias Arangoex.Request

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
  @spec create(t) :: Arangoex.ok_error(map)
  def create(task) do
    %Request{
      endpoint: :task,
      system_only: true,   # or just /_api? Same thing?
      http_method: :post,
      path: "tasks",
      body: task
    }
  end

  @doc """
  Fetch all tasks or one task

  GET /_api/tasks
  """
  @spec tasks() :: Arangoex.ok_error(map)
  def tasks() do
    %Request{
      endpoint: :task,
      system_only: true,   # or just /_api? Same thing?
      http_method: :get,
      path: "tasks",
    }
  end

  @doc """
  Deletes the task with id

  DELETE /_api/tasks/{id}
  """
  @spec delete(String.t) :: Arangoex.ok_error(map)
  def delete(task_id) do
    %Request{
      endpoint: :task,
      system_only: true,   # or just /_api? Same thing?
      http_method: :delete,
      path: "tasks/#{task_id}",
    }
  end

  @doc """
  Fetch one task with id

  GET /_api/tasks/{id}
  """
  @spec task(String.t) :: Arangoex.ok_error(map)
  def task(task_id) do
    %Request{
      endpoint: :task,
      system_only: true,   # or just /_api? Same thing?
      http_method: :get,
      path: "tasks/#{task_id}",
    }
  end

  @doc """
  Creates a task with id

  PUT /_api/tasks/{id}
  """
  @spec create_with_id(String.t, Task.t) :: Arangoex.ok_error(map)
  def create_with_id(task_id, task) do
    %Request{
      endpoint: :task,
      system_only: true,   # or just /_api? Same thing?
      http_method: :put,
      path: "tasks/#{task_id}",
      body: task,
    }
  end
end
