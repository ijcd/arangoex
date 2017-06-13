defmodule Arangoex.Request do
  require Logger

  @moduledoc """
  Makes requests to ArangoDB
  """

  defstruct [
    endpoint: nil,
    system_only: false,
    http_method: nil,
    headers: [],
    path: nil,
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
    body: Map.t | String.t,
    encode_body: boolean(),
    ok_decoder: module(),
    config_overrides: Keyword.t,
  }

  @type httpoison_response :: {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} | {:error, HTTPoison.Error.t}

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

    response = HTTPoison.request(operation.http_method, url, body, headers)

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
  defp encode_body(_, _), do: ""

  def map_without_nil_values(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end

  defp decode_headers(headers) do
    headers = Enum.into(headers, %{})
    etag = headers["Etag"]
    if etag do
      Map.merge(headers, %{"Etag" => Poison.decode!(etag)})
    else
      headers
    end
  end

  # TODO: second arg of Map.t should be an operation type
  @spec decode_operation_response(Arangoex.ok_error(any()), Map.t) :: Map.t
  defp decode_operation_response({:ok, response}, %{ok_decoder: decoder}) when decoder != nil, do: decoder.decode_ok(response)
  defp decode_operation_response(response, _), do: response

  @spec decode_adapter_response(httpoison_response) :: Arangoex.ok_error(any())
  defp decode_adapter_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body} = embedded_response} when status_code >= 200 and status_code < 300 ->
        try do
          {:ok, Poison.decode!(body)}
        rescue
          _ -> {:ok, decode_headers(embedded_response.headers)}
        end
      {:ok, %HTTPoison.Response{body: body} = response} ->
        try do
          {:error, Poison.decode!(body)}
        rescue
        _ -> {:error, response}
        end
      {:ok, %HTTPoison.Response{} = err} ->
        {:error, err}
      {:error, %HTTPoison.Error{}} = err ->
        err
    end
  end
end
