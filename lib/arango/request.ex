defmodule Arango.Request do
  require Logger

  defmodule ApiConn do
    use Tesla

    defmodule Response do
      defstruct [:status, :headers, :body]

      @type t :: %__MODULE__{
        status: pos_integer(),
        headers: Map.t,
        body: nil | String.t
      }
    end

    # TODO: config or detect when loading
    # adapter Tesla.Adapter.Ibrowse
    # adapter Tesla.Adapter.Hackney
    adapter Tesla.Adapter.Httpc

    plug Tesla.Middleware.Tuples
    plug Tesla.Middleware.Headers, %{"User-Agent" => "Arango", "Content-Type" => "application/json"}

    def client(base_url) do
      Tesla.build_client [
        # {Tesla.Middleware.Tuples, nil},
        {Tesla.Middleware.BaseUrl, base_url}
      ]
    end

    def go(client, options) do
      request(client, options)
      |> decode_response
    end

    @spec decode_response(Tesla.Env.t) :: Response.t
    def decode_response({ok_error, %Tesla.Env{status: status, headers: headers, body: body}}) do
      {ok_error, %Response{status: status, headers: headers, body: body}}
    end
  end

  @moduledoc """
  Makes requests to ArangoDB
  """

  defstruct [
    endpoint: nil,
    system_only: false,
    http_method: nil,
    headers: %{},
    path: nil,
    query: %{},
    body: nil,
    encode_body: true,
    database_name: nil,
    ok_decoder: nil,
  ]
  use ExConstructor

  @type t :: %__MODULE__{
    endpoint: atom(),
    system_only: boolean(),
    http_method: :get | :post | :put | :patch | :delete,
    headers: Keyword.t,
    path: String.t,
    query: Map.t,
    body: Map.t | String.t,
    encode_body: boolean(),
    database_name: String.t,
    ok_decoder: module(),
  }

  # @type httpoison_response :: {:ok, HTTPossison.Response.t | HTTPoison.AsyncResponse.t} | {:error, HTTPoison.Error.t}

  def perform(%__MODULE__{} = op, call_config) do
    config =
      Arango.Config.new(op.endpoint, call_config)

    op = %{op | database_name: config[:database_name]}

    if config[:debug_requests] do
      IO.puts("=================================================")
      IO.inspect(op, label: "OPERATION")
      IO.inspect(config, label: "CONFIG")
    end

    base_url = %URI{
      scheme: config.scheme,
      host: config.host,
      port: config.port,
    } |> URI.to_string

    path = path_for_operation(op)

    headers =
      auth_headers(config)
      |> Map.merge(config.headers |> Enum.into(%{}))
      |> Map.merge(Map.get(op, :headers, %{}) |> Enum.into(%{}))

    body = encode_body(op, config)

    if config[:debug_requests] do
      IO.inspect(base_url, label: "BASE_URL")
      IO.inspect(path, label: "PATH")
      IO.inspect(headers, label: "HEADERS")
      IO.inspect(body, label: "BODY")
    end

    client = ApiConn.client(base_url)

    response = ApiConn.go(client,
      method: op.http_method,
      url: path,                              # Tesla will build onto the client's base_Url
      query: op.query,
      headers: headers,
      body: body,
    )

    decoded =
      response
      |> decode_adapter_response
      |> decode_operation_response(op)

    if config[:debug_requests] do
      IO.inspect(response, label: "RESPONSE")
      IO.inspect(decoded, label: "DECODED")
    end

    decoded
  end

  @spec auth_headers(Map.t) :: Map.t
  def auth_headers(%{use_auth: :basic, username: username, password: password}) do
    %{"Authorization" => "Basic " <> Base.encode64("#{username}:#{password}")}
  end
  def auth_headers(%{use_auth: :bearer, password: password}) do
    %{"Authorization" =>  "Bearer #{password}"}
  end

  defp path_for_operation(%{path: "/" <> path}), do: "/#{path}"
  defp path_for_operation(%{path: path, system_only: true}), do: "/_api/#{path}"
  defp path_for_operation(%{path: path, database_name: db_name}), do: "/_db/#{db_name}/_api/#{path}"

  # defp encode_body(%{} = data) when data == %{}, do: ""
  defp encode_body(%{body: body, encode_body: false}, _config), do: body
  defp encode_body(%{body: %{__struct__: _} = body}, config), do: encode_body(%{body: map_without_nil_values(body)}, config)
  defp encode_body(%{body: body}, _) when body != nil, do: Poison.encode!(body)
  defp encode_body(%{http_method: :post}, _), do: ""
  defp encode_body(%{http_method: :patch}, _), do: ""
  defp encode_body(%{http_method: :put}, _), do: ""
  defp encode_body(%{http_method: :delete}, _), do: ""
  defp encode_body(_, _), do: nil

  def map_without_nil_values(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end

  defp decode_headers(headers) do
    etag = headers["etag"]
    if etag do
      Map.merge(headers, %{"etag" => Poison.decode!(etag)})
    else
      headers
    end
  end

  # TODO: second arg of Map.t should be an operation type
  @spec decode_operation_response(Arango.ok_error(any()), Map.t) :: Map.t
  defp decode_operation_response({:ok, response}, %{ok_decoder: decoder}) when decoder != nil, do: decoder.decode_ok(response)
  defp decode_operation_response(response, _), do: response

  # @spec decode_adapter_response(httpoison_response) :: Arango.ok_error(any())
  defp decode_adapter_response(response) do
    case response do
      {:ok, %ApiConn.Response{status: status, headers: headers, body: body}} when status >= 200 and status < 300 ->
        try do
          {:ok, Poison.decode!(body)}
        rescue
          _ -> {:ok, decode_headers(headers)}
        end
      {:ok, %ApiConn.Response{status: status, headers: headers, body: body}}  ->
        try do
          {:error, Poison.decode!(body)}
        rescue
          _ -> {:error, %{
                   status: status,
                   headers: headers,
                   body: body,
                   response: response
                }}
        end
      {:error, _} = e -> e
    end
  end
end
