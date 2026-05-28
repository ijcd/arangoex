defmodule Arango.User do
  @moduledoc "ArangoDB User methods"

  use Arango.API, endpoint: :user

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
    passwd: String.t,
  }

  @doc """
  Create User

  POST /_api/user
  """
  @type create_user_opts :: [{:user, String.t} | {:passwd, String.t} | {:active, boolean} | {:extra, Map.t}]
  @spec create(create_user_opts | t) :: Arango.ok_error(t)
  def create(user \\ [])
  def create(%__MODULE__{user: name}), do: create(user: name)
  def create(opts) do
    request(
      method: :post,
      system_only: true,   # or just /_api? Same thing?
      path: "user",
      body: opts |> Keyword.take([:user, :passwd, :active, :extra]) |> Enum.into(%{}),
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Remove User

  DELETE /_api/user/{user}
  """
  @spec remove(t | String.t) :: Arango.ok_error(map)
  def remove(%__MODULE__{user: name}), do: remove(name)
  def remove(name) do
    request(
      method: :delete,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{name}"
    )
  end

  @doc """
  List available Users

  GET /_api/user/
  """
  @spec users() :: Arango.ok_error([t])
  def users() do
    request(
      method: :get,
      system_only: true,   # or just /_api? Same thing?
      path: "user",
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Fetch User

  GET /_api/user/{user}
  """
  @spec user(String.t | t) :: Arango.ok_error(t)
  def user(%__MODULE__{user: name}), do: user(name)
  def user(name) do
    request(
      method: :get,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{name}",
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Update User

  PATCH /_api/user/{user}
  """
  @spec update(t) :: Arango.ok_error(map)
  def update(user, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:passwd, :active, :extra])

    request(
      method: :patch,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{user.user}",
      body: properties,
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Replace User

  PUT /_api/user/{user}
  """
  @spec replace(t) :: Arango.ok_error(map)
  def replace(user, opts \\ []) do
    properties = Utils.opts_to_vars(opts, [:passwd, :active, :extra])

    request(
      method: :put,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{user.user}",
      body: properties,
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  List the databases available to a User

  GET /_api/user/{user}/database
  """
  @spec databases(String.t | t) :: Arango.ok_error([String.t])
  def databases(%__MODULE__{user: name}), do: databases(name)
  def databases(user_name) do
    request(
      method: :get,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{user_name}/database",
      ok_decoder: __MODULE__.PlainDecoder
    )
  end

  @doc """
  Grant database access

  PUT /_api/user/{user}/database/{dbname}
  """
  @spec grant(t, Database.t) :: Arango.ok_error([String.t])
  def grant(%__MODULE__{user: user_name}, database_name), do: grant(user_name, database_name)
  def grant(user_name, database_name) do
    request(
      method: :put,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{user_name}/database/#{database_name}",
      body: %{grant: "rw"}
    )
  end

  @doc """
  Revoke database access

  PUT /_api/user/{user}/database/{dbname}
  """
  @spec revoke(t, Database.t) :: Arango.ok_error([String.t])
  def revoke(%__MODULE__{user: user_name}, database_name), do: revoke(user_name, database_name)
  def revoke(user_name, database_name) do
    request(
      method: :put,
      system_only: true,   # or just /_api? Same thing?
      path: "user/#{user_name}/database/#{database_name}",
      body: %{grant: "none"}
    )
  end

  defmodule UserDecoder do
    alias Arango.User

    @spec decode_ok(Map.t) :: Arango.ok_error(User.t)
    def decode_ok(%{"result" => result}) when is_list(result), do: {:ok, Enum.map(result, &User.new(&1))}
    def decode_ok(result), do: {:ok, User.new(result)}
  end

  defmodule PlainDecoder do
    @spec decode_ok(any()) :: Arango.ok_error(any())
    def decode_ok(%{"result" => %{} = result}), do: {:ok, result}
    def decode_ok(%{"result" => result}), do: {:ok, result}
  end
end
