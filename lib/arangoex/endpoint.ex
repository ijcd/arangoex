defmodule Arangoex.Endpoint do
  @moduledoc "Represents an ArangoDB database endpoint"

  defstruct(
    host: "localhost",
    port: 8529,
    scheme: "http",
    database_name: "_system",
    arrango_version: 30_000,
    headers: ["Accept": "*/*"],
    use_auth: :basic,
    username: nil,
    password: nil,
  )

  def url(endpoint, path) do
    %URI{
      scheme: endpoint.scheme,
      host: endpoint.host,
      port: endpoint.port,
      path: db_path(endpoint, path)
    } |> URI.to_string
  end

  def auth_headers(%{use_auth: :basic, username: username, password: password}) do
    ["Authorization": "Basic " <> Base.encode64("#{username}:#{password}")]
  end

  def auth_headers(%{use_auth: :bearer, password: password}) do
    ["Authorization": "Bearer #{password}"]
  end
  
  def request_headers(endpoint) do
    Keyword.merge(auth_headers(endpoint), endpoint.headers)
  end

  def with_db(endpoint, db_name) do
    Map.put(endpoint, :database_name, db_name)
  end

  def with_auth(endpoint, :basic, username, password) do
    Map.merge(endpoint, %{use_auth: :basic, username: username, password: password})
  end

  def with_auth(endpoint, :bearer, token) do
    Map.merge(endpoint, %{use_auth: :bearer, password: token})
  end

  def get(endpoint, resource) do
    url = url(endpoint, resource)
    response = HTTPoison.request(:get, url, "", request_headers(endpoint))
    handle_response(response)
  end

  defp handle_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code >= 200 and status_code < 300 ->
        {:ok, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, Poison.decode!(body)}
      {:error, %HTTPoison.Error{reason: reason}} ->
        raise %Arangoex.Error{message: reason}
    end
  end
  
  defp db_path(%{database_name: db_name}, path) when db_name != "_system", do: "/_db/#{db_name}/_api/#{path}"
  defp db_path(_, path), do: "/_api/#{path}"    
end
