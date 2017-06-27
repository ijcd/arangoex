defmodule Arangoex.Endpoint do
  @moduledoc "Represents an ArangoDB database endpoint"

  defstruct(
    host: "localhost",
    port: 8529,
    scheme: "http",
    database_name: "_system",
    arrango_version: 30_000,
    headers: %{"Accept": "*/*"},
    use_auth: :basic,
    username: nil,
    password: nil,
  )

  @type t :: %__MODULE__{
    host: String.t,
    port: pos_integer(),
    scheme: String.t,
    database_name: String.t,
    arrango_version: pos_integer(), 
    headers: Map.t,
    use_auth: :none | :basic | :bearer,
    username: nil | String.t,
    password: nil | String.t,
  }

  @type httpoison_response :: {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} | {:error, HTTPoison.Error.t}

  @spec url(t, String.t) :: String.t
  def url(endpoint, path) do
    %URI{
      scheme: endpoint.scheme,
      host: endpoint.host,
      port: endpoint.port,
      path: db_path(endpoint, path)
    } |> URI.to_string
  end

  @spec auth_headers(t) :: Map.t
  def auth_headers(%{use_auth: :basic, username: username, password: password}) do
    %{"Authorization" => "Basic " <> Base.encode64("#{username}:#{password}")}
  end
  def auth_headers(%{use_auth: :bearer, password: password}) do
    %{"Authorization" =>  "Bearer #{password}"}
  end

  @spec request_headers(t) :: Map.t
  def request_headers(endpoint) do
    Map.merge(auth_headers(endpoint), endpoint.headers)
  end

  @spec with_db(t, String.t) :: t
  def with_db(endpoint, db_name) do
    Map.put(endpoint, :database_name, db_name)
  end

  @spec get(t, String.t, keyword) :: Arangoex.ok_error(any())
  def get(endpoint, resource, headers \\ []) do
    url = url(endpoint, resource)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))
    
    response = HTTPoison.request(:get, url, "", headers)
    handle_response(response)
  end

  @spec head(t, String.t, keyword) :: Arangoex.ok_error(any())
  def head(endpoint, resource, headers \\ []) do
    url = url(endpoint, resource)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:head, url, "", headers)
    handle_response(response)
  end
  
  @spec post(t, String.t, map, keyword) :: Arangoex.ok_error(any())
  def post(endpoint, resource, data \\ %{}, headers \\ []) do
    url = url(endpoint, resource)
    body = encode_data(data)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:post, url, body, headers)
    handle_response(response)
  end

  @spec post_raw(t, String.t, String.t, keyword) :: Arangoex.ok_error(any())
  def post_raw(endpoint, resource, data \\ "", headers \\ []) do
    url = url(endpoint, resource)
    body = data
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:post, url, body, headers)
    handle_response(response)
  end

  @spec put(t, String.t, map | [map], keyword) :: Arangoex.ok_error(any())  
  def put(endpoint, resource, data \\ %{}, headers \\ []) do
    url = url(endpoint, resource)
    body = encode_data(data)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:put, url, body, headers)
    handle_response(response)
  end

  @spec patch(t, String.t, map | [map], keyword) :: Arangoex.ok_error(any())  
  def patch(endpoint, resource, data \\ %{}, headers \\ []) do
    url = url(endpoint, resource)
    body = encode_data(data)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:patch, url, body, headers)
    handle_response(response)
  end
  
  @spec delete(t, String.t, map | [map], keyword) :: Arangoex.ok_error(any())    
  def delete(endpoint, resource, data \\ nil, headers \\ []) do
    url = url(endpoint, resource)
    body = encode_data(data)
    headers = Map.merge(request_headers(endpoint), Enum.into(headers, %{}))

    response = HTTPoison.request(:delete, url, body, headers)
    handle_response(response)
  end
  
  @spec handle_response(httpoison_response) :: Arangoex.ok_error(any())
  defp handle_response(response) do
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
  
  defp db_path(%{database_name: db_name}, path) when db_name != "_system", do: "/_db/#{db_name}/_api/#{path}"
  defp db_path(_, "/_admin/" <> path), do: "/_admin/#{path}"
  defp db_path(_, path), do: "/_api/#{path}"

  defp decode_headers(headers) do
    headers = Enum.into(headers, %{})
    etag = headers["Etag"]
    if etag do
      Map.merge(headers, %{"Etag" => Poison.decode!(etag)})
    else
      headers
    end
  end

  defp encode_data(nil), do: ""
  defp encode_data(%{} = data) when data == %{}, do: "{}"
  defp encode_data(%{__struct__: _} = data) do
    data
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})    
    |> encode_data
  end
  defp encode_data(data), do: Poison.encode!(data)
end
