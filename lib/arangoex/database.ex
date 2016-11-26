defmodule Arangoex.Database do
  @moduledoc "ArangoDB Database methods"

  alias Arangoex.Endpoint

  defstruct [:id, :name, :isSystem, :path, :users]
  use ExConstructor

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    isSystem: boolean,
    path: String.t,
    users: [String.t],
  }

  @doc """
  Create database

  POST /_api/database
  """
  @spec create(Endpoint.t, Database.t) :: Arangoex.ok_error(any())
  def create(endpoint, db) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.post("database", db)
    |> decode_result
  end

  @doc """
  Drop database

  DELETE /_api/database/{database-name}  
  """
  @spec drop(%Arangoex.Endpoint{}, String.t) :: Arangoex.ok_error(true)
  def drop(endpoint, db) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.delete("database/#{db}")
    |> decode_result
  end

  @doc """
  Information about a database

  GET /_api/database/current
  """
  @spec database(Endpoint.t, String.t) :: Arangoex.ok_error(t)
  def database(endpoint, db) do
    endpoint
    |> Endpoint.with_db(db)
    |> Endpoint.get("database/current")
    |> decode_result
  end

  @doc """
  List of databases

  GET /_api/database
  """
  @spec databases(Endpoint.t) :: Arangoex.ok_error([String.t])
  def databases(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("database")
    |> decode_result
  end

  @doc """
  List of accessible databases

  GET /_api/database/user
  """
  @spec user_databases(Endpoint.t) :: Arangoex.ok_error([String.t])
  def user_databases(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("database/user")
    |> decode_result
  end

  @spec decode_result(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())
  defp decode_result({:ok, %{"result" => %{} = result}}), do: {:ok, new(result)}
  defp decode_result({:ok, %{"result" => result}}), do: {:ok, result}
  defp decode_result({:error, _} = e), do: e
end
