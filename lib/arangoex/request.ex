defmodule Arangoex.Request do
  require Logger

  defmodule MyConn do
    use Maxwell.Builder

    # TODO: config or detect when loading
    # adapter Maxwell.Adapter.Ibrowse
    # adapter Maxwell.Adapter.Hackney
    adapter Maxwell.Adapter.Httpc

    middleware Maxwell.Middleware.Headers, %{"User-Agent" => "Arangoex", "Content-Type" => "application/json"}

    def request(http_method, url, query, headers, body) do
      conn =
        url
        |> new()
        |> put_query_string(query)
        |> put_req_headers(headers)
        |> put_req_body(body)

      response = case http_method do
                   :get -> get(conn)
                   :head -> head(conn)
                   :post -> post(conn)
                   :put -> put(conn)
                   :patch -> patch(conn)
                   :delete -> delete(conn)
                   :trace -> trace(conn)
                   :options -> options(conn)
                 end
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
    ok_decoder: nil,

    # This is awkward, thing more about how to handle database_name, etc, in the operation
    config_overrides: [],
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
    ok_decoder: module(),
    config_overrides: Keyword.t,
  }

  # @type httpoison_response :: {:ok, HTTPossison.Response.t | HTTPoison.AsyncResponse.t} | {:error, HTTPoison.Error.t}

  def perform(%__MODULE__{} = operation, config) do
    config = Map.merge(config, Enum.into(operation.config_overrides, %{}))

    operation =
      %{database_name: config[:database_name]}
      |> Map.merge(operation)

    if config[:debug_requests] do
      IO.puts("=================================================")
      IO.inspect(operation, label: "OPERATION")
      IO.inspect(config, label: "CONFIG")
    end

    url = %URI{
      scheme: config.scheme,
      host: config.host,
      port: config.port,
      path: path_for_operation(operation)
    } |> URI.to_string

    headers =
      auth_headers(config)
      |> Map.merge(config.headers |> Enum.into(%{}))
      |> Map.merge(Map.get(operation, :headers, %{}) |> Enum.into(%{}))

    body = encode_body(operation, config)

    if config[:debug_requests] do
      IO.inspect(url, label: "URL")
      IO.inspect(headers, label: "HEADERS")
      IO.inspect(body, label: "BODY")
    end

    response = MyConn.request(operation.http_method, url, operation.query, headers, body)

    decoded =
      response
      |> decode_adapter_response
      |> decode_operation_response(operation)

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
  defp encode_body(%{body: body}, config) when body != nil, do: config[:json_codec].encode!(body)
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
  @spec decode_operation_response(Arangoex.ok_error(any()), Map.t) :: Map.t
  defp decode_operation_response({:ok, response}, %{ok_decoder: decoder}) when decoder != nil, do: decoder.decode_ok(response)
  defp decode_operation_response(response, _), do: response

  # @spec decode_adapter_response(httpoison_response) :: Arangoex.ok_error(any())
  defp decode_adapter_response(response) do
    case response do
      {:ok, %Maxwell.Conn{state: :sent, status: status, resp_headers: resp_headers, resp_body: resp_body}} when status >= 200 and status < 300 ->
        try do
          {:ok, Poison.decode!(resp_body)}
        rescue
          _ -> {:ok, decode_headers(resp_headers)}
        end
      {:ok, %Maxwell.Conn{state: :sent, resp_body: resp_body} = response} ->
        resp_body_as_string = to_string(resp_body)
        try do
          {:error, Poison.decode!(resp_body_as_string)}
        rescue
          _ -> {:error, %{
                   "status" => response.status,
                   "resp_headers" => response.resp_headers,
                   "resp_body" => resp_body_as_string,
                   "response" => response
                }}
        end
      # {:ok, %HTTPoison.Response{} = err} ->
      #   {:error, err}
      {:error, _} = err ->
        err
    end
  end
end
