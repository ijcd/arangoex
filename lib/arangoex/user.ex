defmodule Arangoex.User do
  @moduledoc "ArangoDB User methods"

  alias Arangoex.Endpoint
  alias Arangoex.Utils  

  defstruct [
    user: nil,
    active: nil,
    extra: nil,
    changePassword: nil,
    passwd: nil,
  ]
  use ExConstructor

  @type t :: %__MODULE__{
    user: String.t,
    active: boolean,
    extra: map,
    changePassword: boolean,
  }
  
  @doc """
  Create User
  
  POST /_api/user
  """
  @spec create(Endpoint.t, t) :: Arangoex.ok_error(t)  
  def create(endpoint, user) do
    endpoint
    |> Endpoint.post("user", user)
    |> to_user
  end

  @doc """
  Remove User
  
  DELETE /_api/user/{user}
  """
  @spec remove(Endpoint.t, t) :: Arangoex.ok_error(map)
  def remove(endpoint, user) do
    endpoint
    |> Endpoint.delete("user/#{user.user}")
  end

  @doc """
  List available Users

  GET /_api/user/ 
  """
  @spec users(Endpoint.t) :: Arangoex.ok_error([t])
  def users(endpoint) do
    endpoint
    |> Endpoint.get("user")
    |> to_user
  end

  @doc """
  Fetch User
  
  GET /_api/user/{user} 
  """
  @spec user(Endpoint.t, t) :: Arangoex.ok_error(t)  
  def user(endpoint, user) do
    endpoint
    |> Endpoint.get("user/#{user.user}")
    |> to_user
  end

  @doc """
  Update User
  
  PATCH /_api/user/{user} 
  """
  @spec update(Endpoint.t, t) :: Arangoex.ok_error(map)
  def update(endpoint, user, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:passwd, :active, :extra])
    
    endpoint
    |> Endpoint.patch("user/#{user.user}", properties)
    |> to_user    
  end

  @doc """
  Replace User
  
  PUT /_api/user/{user} 
  """
  @spec replace(Endpoint.t, t) :: Arangoex.ok_error(map)
  def replace(endpoint, user, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:passwd, :active, :extra])
    
    endpoint
    |> Endpoint.put("user/#{user.user}", properties)
    |> to_user
  end

  @doc """
  List the databases available to a User
   
  GET /_api/user/{user}/database
  """
  @spec databases(Endpoint.t, t) :: Arangoex.ok_error([String.t])
  def databases(endpoint, user) do
    endpoint
    |> Endpoint.get("user/#{user.user}/database")
    |> decode_result
  end

  @doc """
  Grant database access
  
  PUT /_api/user/{user}/database/{dbname} 
  """
  @spec grant(Endpoint.t, t, Database.t) :: Arangoex.ok_error([String.t])
  def grant(endpoint, user, database) do
    endpoint
    |> Endpoint.put("user/#{user.user}/database/#{database.name}", %{grant: "rw"})
  end
  
  @doc """
  Revoke database access
  
  PUT /_api/user/{user}/database/{dbname} 
  """
  @spec revoke(Endpoint.t, t, Database.t) :: Arangoex.ok_error([String.t])
  def revoke(endpoint, user, database) do
    endpoint
    |> Endpoint.put("user/#{user.user}/database/#{database.name}", %{grant: "none"})
  end
  
  @spec to_user(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())  
  defp to_user({:ok, %{"result" => result}}) when is_list(result), do: {:ok, Enum.map(result, &new(&1))}
  defp to_user({:ok, result}), do: {:ok, new(result)}
  defp to_user({:error, _} = e), do: e

  @spec decode_result(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())
  defp decode_result({:ok, %{"result" => result}}), do: {:ok, result}
  defp decode_result({:error, _} = e), do: e  
end
