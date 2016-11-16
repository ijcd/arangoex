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

  @spec with_auth(t, atom, String.t, String.t) :: t  
  def with_auth(endpoint, :basic, username, password) do
    Map.merge(endpoint, %{use_auth: :basic, username: username, password: password})
  end

  @spec with_auth(t, atom, String.t) :: t    
  def with_auth(endpoint, :bearer, token) do
    Map.merge(endpoint, %{use_auth: :bearer, password: token})
  end

  @spec get(t, String.t) :: Arangoex.ok_error(any())
  def get(endpoint, resource) do
    url = url(endpoint, resource) 
    response = HTTPoison.request(:get, url, "", request_headers(endpoint))
    handle_response(response)
  end

  @spec post(t, String.t, map) :: Arangoex.ok_error(any())
  def post(endpoint, resource, data \\ %{}) do
    url = url(endpoint, resource)
    body = encode_data(data)
    response = HTTPoison.request(:post, url, body, request_headers(endpoint))
    handle_response(response)
  end

  @spec put(t, String.t, map) :: Arangoex.ok_error(any())  
  def put(endpoint, resource, data \\ %{}) do
    url = url(endpoint, resource)
    body = encode_data(data)
    response = HTTPoison.request(:put, url, body, request_headers(endpoint))
    handle_response(response)
  end

  @spec patch(t, String.t, map) :: Arangoex.ok_error(any())  
  def patch(endpoint, resource, data \\ %{}) do
    url = url(endpoint, resource)
    body = encode_data(data)
    response = HTTPoison.request(:patch, url, body, request_headers(endpoint))
    handle_response(response)
  end
  
  @spec delete(t, String.t) :: Arangoex.ok_error(any())    
  def delete(endpoint, resource) do
    url = url(endpoint, resource)
    response = HTTPoison.request(:delete, url, "", request_headers(endpoint))
    handle_response(response)
  end

  @spec opts_with_defaults(keyword, keyword) :: map
  def opts_with_defaults(opts, defaults \\ []) do
    extra = Keyword.keys(opts) -- Keyword.keys(defaults)
    Enum.any?(extra, &(raise "unknown key: #{&1}"))
    
    defaults
    |> Keyword.merge(opts)    
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end    

  @spec handle_response(httpoison_response) :: Arangoex.ok_error(any())
  defp handle_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code >= 200 and status_code < 300 ->
        {:ok, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{} = err} ->
        {:error, err}
      {:error, %HTTPoison.Error{}} = err ->
        err
    end
  end
  
  defp db_path(%{database_name: db_name}, path) when db_name != "_system", do: "/_db/#{db_name}/_api/#{path}"
  defp db_path(_, "/_admin/" <> path), do: "/_admin/#{path}"
  defp db_path(_, path), do: "/_api/#{path}"

  defp encode_data(%{} = data) when data == %{}, do: ""
  defp encode_data(%{__struct__: _} = data), do: encode_data(Map.from_struct(data))
  defp encode_data(data) when is_list(data), do: encode_data(Enum.into(data, %{}))
  defp encode_data(%{} = data) do
    data
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
    |> Poison.encode!
  end
end
