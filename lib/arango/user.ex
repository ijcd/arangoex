defmodule Arango.User do
  @moduledoc "ArangoDB User methods"

  use Arango.API, endpoint: :user

  defstruct user: nil,
            active: nil,
            extra: nil,
            changePassword: nil,
            passwd: nil

  use ExConstructor

  @type t :: %__MODULE__{
          user: String.t(),
          active: boolean,
          extra: map,
          changePassword: boolean,
          passwd: String.t()
        }

  @doc """
  Create User

  POST /_api/user
  """
  @type create_user_opts :: [
          {:user, String.t()} | {:passwd, String.t()} | {:active, boolean} | {:extra, map()}
        ]
  @spec create(create_user_opts | t) :: Arango.ok_error(t)
  def create(user \\ [])
  def create(%__MODULE__{user: name}), do: create(user: name)

  def create(opts) do
    request(
      method: :post,
      system_only: true,
      path: "user",
      body: opts |> Keyword.take([:user, :passwd, :active, :extra]) |> Enum.into(%{}),
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Remove User

  DELETE /_api/user/{user}
  """
  @spec remove(t | String.t()) :: Arango.ok_error(map)
  def remove(%__MODULE__{user: name}), do: remove(name)

  def remove(name) do
    request(
      method: :delete,
      system_only: true,
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
      system_only: true,
      path: "user",
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  Fetch User

  GET /_api/user/{user}
  """
  @spec user(String.t() | t) :: Arango.ok_error(t)
  def user(%__MODULE__{user: name}), do: user(name)

  def user(name) do
    request(
      method: :get,
      system_only: true,
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
      system_only: true,
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
      system_only: true,
      path: "user/#{user.user}",
      body: properties,
      ok_decoder: __MODULE__.UserDecoder
    )
  end

  @doc """
  List the databases available to a User

  GET /_api/user/{user}/database
  """
  @spec databases(String.t() | t) :: Arango.ok_error([String.t()])
  def databases(%__MODULE__{user: name}), do: databases(name)

  def databases(user_name) do
    request(
      method: :get,
      system_only: true,
      path: "user/#{user_name}/database",
      ok_decoder: __MODULE__.PlainDecoder
    )
  end

  @doc """
  Grant database access

  PUT /_api/user/{user}/database/{dbname}
  """
  @spec grant(t, Arango.Database.t()) :: Arango.ok_error([String.t()])
  def grant(%__MODULE__{user: user_name}, database_name), do: grant(user_name, database_name)

  def grant(user_name, database_name) do
    request(
      method: :put,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}",
      body: %{grant: "rw"}
    )
  end

  @doc """
  Revoke database access

  PUT /_api/user/{user}/database/{dbname}
  """
  @spec revoke(t, Arango.Database.t()) :: Arango.ok_error([String.t()])
  def revoke(%__MODULE__{user: user_name}, database_name), do: revoke(user_name, database_name)

  def revoke(user_name, database_name) do
    request(
      method: :put,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}",
      body: %{grant: "none"}
    )
  end

  @doc """
  Grant collection-level access.

  PUT /_api/user/{user}/database/{dbname}/{collection}

  `level` is `"rw" | "ro" | "none"` and defaults to `"rw"` to match
  `grant/2`. Use `revoke/3` (DELETE) to remove the collection-level
  override entirely so the user falls back to the database-level grant.
  """
  @spec grant(t() | String.t(), String.t(), String.t(), String.t()) :: Arango.Request.t()
  def grant(user, database_name, collection, level \\ "rw")

  def grant(%__MODULE__{user: user_name}, database_name, collection, level),
    do: grant(user_name, database_name, collection, level)

  def grant(user_name, database_name, collection, level) when is_binary(user_name) do
    request(
      method: :put,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}/#{collection}",
      body: %{grant: level}
    )
  end

  @doc """
  Revoke a collection-level grant. Removes the override entirely;
  effective permission falls back to the database-level default.

  DELETE /_api/user/{user}/database/{dbname}/{collection}
  """
  @spec revoke(t() | String.t(), String.t(), String.t()) :: Arango.Request.t()
  def revoke(%__MODULE__{user: user_name}, database_name, collection),
    do: revoke(user_name, database_name, collection)

  def revoke(user_name, database_name, collection) when is_binary(user_name) do
    request(
      method: :delete,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}/#{collection}"
    )
  end

  @doc """
  List a user's database permissions.

  GET /_api/user/{user}/database

  Alias for `databases/1` under the permissions/permission family.
  """
  @spec permissions(t() | String.t()) :: Arango.Request.t()
  def permissions(user), do: databases(user)

  @doc """
  Effective database-level permission for a user.

  GET /_api/user/{user}/database/{dbname}
  """
  @spec permissions(t() | String.t(), String.t()) :: Arango.Request.t()
  def permissions(%__MODULE__{user: user_name}, database_name),
    do: permissions(user_name, database_name)

  def permissions(user_name, database_name) when is_binary(user_name) do
    request(
      method: :get,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}"
    )
  end

  @doc """
  Effective collection-level permission for a user.

  GET /_api/user/{user}/database/{dbname}/{collection}
  """
  @spec permission(t() | String.t(), String.t(), String.t()) :: Arango.Request.t()
  def permission(%__MODULE__{user: user_name}, database_name, collection),
    do: permission(user_name, database_name, collection)

  def permission(user_name, database_name, collection) when is_binary(user_name) do
    request(
      method: :get,
      system_only: true,
      path: "user/#{user_name}/database/#{database_name}/#{collection}"
    )
  end

  defmodule UserDecoder do
    @moduledoc false
    alias Arango.User

    @spec decode_ok(map()) :: Arango.ok_error(User.t())
    def decode_ok(%{"result" => result}) when is_list(result), do: {:ok, Enum.map(result, &User.new(&1))}
    def decode_ok(result), do: {:ok, User.new(result)}
  end

  defmodule PlainDecoder do
    @moduledoc false
    @spec decode_ok(any()) :: Arango.ok_error(any())
    def decode_ok(%{"result" => %{} = result}), do: {:ok, result}
    def decode_ok(%{"result" => result}), do: {:ok, result}
  end
end
