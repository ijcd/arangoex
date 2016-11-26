defmodule Arangoex.Document do
  @moduledoc "ArangoDB Document methods"

  alias Arangoex.Endpoint
  alias Arangoex.Collection
  alias Arangoex.Utils

  defmodule Docref do
    @moduledoc false
    
    defstruct [:_key, :_id, :_rev, :_oldRev]
    use ExConstructor
  end

  @type t :: %__MODULE__.Docref{
    _key: String.t,
    _id: String.t,
    _rev: String.t,
    _oldRev: String.t,    
  }

  @doc """  
  Create document

  POST /_api/document/{collection}
  """
  @spec create(Endpoint.t, Collection.t, map | [map]) :: Arangoex.ok_error(map | [map])
  def create(endpoint, coll, doc, opts \\ []) do
    query = Utils.opts_to_query(opts, [:waitForSync, :returnNew])

    endpoint
    |> Endpoint.post("document/#{coll.name}#{query}", doc)
    |> to_result
  end

  @doc """
  Read document header

  HEAD /_api/document/{document-handle} 
  """
  @spec header(Endpoint.t, map, keyword) :: Arangoex.ok_error(map)
  def header(endpoint, doc, opts \\ []) do
    headers = Utils.opts_to_headers(opts, [:ifNoneMatch, :ifMatch])

    endpoint
    |> Endpoint.head("document/#{doc._id}", headers)
  end

  @doc """
  Read document

  GET /_api/document/{document-handle} 
  """
  @spec document(Endpoint.t, t, keyword) :: Arangoex.ok_error(map)
  def document(endpoint, doc, opts \\ []) do
    headers = Utils.opts_to_headers(opts, [:ifNoneMatch, :ifMatch]) 

    endpoint
    |> Endpoint.get("document/#{doc._id}", headers)
  end
  
  @doc """
  Read all documents

  PUT /_api/simple/all-keys 
  """
  @spec documents(Endpoint.t, Collection.t, keyword) :: Arangoex.ok_error(t | [t])
  def documents(endpoint, coll, opts \\ []) do
    type = Utils.ensure_permitted(opts, [:type])[:type]
    body = cond do
      type == :id   -> %{"collection" => coll.name, "type" => "id"}
      type == :path -> %{"collection" => coll.name, "type" => "path"}
      type == :key  -> %{"collection" => coll.name, "type" => "key"}
      type == nil   -> %{"collection" => coll.name}
      true -> raise "unknown type: #{type}"
    end
    
    endpoint
    |> Endpoint.put("simple/all-keys", body)
  end

  def update(endpoint, coll, docs, opts \\ [])
  
  @doc """
  Update documents

  PATCH /_api/document/{collection}
  """
  @spec update(Endpoint.t, Collection.t, [map], keyword) :: Arangoex.ok_error([map])
  def update(endpoint, coll, new_docs, opts) when is_list(new_docs) do
    query = Utils.opts_to_query(opts, [:keepNull, :mergeObjects, :waitForSync, :ignoreRevs, :returnOld, :returnNew])

    endpoint
    |> Endpoint.patch("document/#{coll.name}#{query}", new_docs)
    |> to_result
  end

  @doc """
  Update document

  PATCH /_api/document/{document-handle} 
  """
  @spec update(Endpoint.t, map, map, keyword) :: Arangoex.ok_error(map)
  def update(endpoint, doc, new_doc, opts) do
    {header_opts, query_opts} = Keyword.split(opts, [:ifMatch])
    headers = Utils.opts_to_headers(header_opts, [:ifMatch])
    query = Utils.opts_to_query(query_opts, [:keepNull, :mergeObjects, :waitForSync, :ignoreRevs, :returnOld, :returnNew])

    endpoint
    |> Endpoint.patch("document/#{doc._id}#{query}", new_doc, headers)
    |> to_result
  end

  def replace(endpoint, coll, docs, opts \\ [])
  
  @doc """
  Replace documents

  PATCH /_api/document/{collection}
  """
  @spec replace(Endpoint.t, Collection.t, [map], keyword) :: Arangoex.ok_error([map])
  def replace(endpoint, coll, new_docs, opts) when is_list(new_docs) do
    query = Utils.opts_to_query(opts, [:keepNull, :mergeObjects, :waitForSync, :ignoreRevs, :returnOld, :returnNew])

    endpoint
    |> Endpoint.put("document/#{coll.name}#{query}", new_docs)
    |> to_result
  end

  @doc """
  Replace document

  PUT /_api/document/{document-handle} 
  """
  @spec replace(Endpoint.t, t, map) :: Arangoex.ok_error(t | [t])
  def replace(endpoint, doc, new_doc, opts) do
    {header_opts, query_opts} = Keyword.split(opts, [:ifMatch])
    headers = Utils.opts_to_headers(header_opts, [:ifMatch])
    query = Utils.opts_to_query(query_opts, [:keepNull, :mergeObjects, :waitForSync, :ignoreRevs, :returnOld, :returnNew])

    endpoint
    |> Endpoint.put("document/#{doc._id}#{query}", new_doc, headers)
    |> to_result
  end

  @doc """
  Removes multiple documents

  DELETE /_api/document/{collection}
  """
  @spec delete_multi(Endpoint.t, Collection.t, [map], keyword) :: Arangoex.ok_error(t | [t])
  def delete_multi(endpoint, coll, docs, opts \\ []) when is_list(docs) do
    query = Utils.opts_to_query(opts, [:waitForSync, :ignoreRevs, :returnOld])

    endpoint
    |> Endpoint.delete("document/#{coll.name}#{query}", docs)
    |> to_result
  end

  @doc """
  Removes a document

  DELETE /_api/document/{document-handle} 
  """
  @spec delete(Endpoint.t, t, keyword) :: Arangoex.ok_error(t | [t])
  def delete(endpoint, doc, opts \\ []) do
    {header_opts, query_opts} = Keyword.split(opts, [:ifMatch])
    headers = Utils.opts_to_headers(header_opts, [:ifMatch])
    query = Utils.opts_to_query(query_opts, [:waitForSync, :returnOld])

    endpoint
    |> Endpoint.delete("document/#{doc._id}#{query}", %{}, headers)
    |> to_result
  end
  
  @spec to_result(Arangoex.ok_error(any())) :: Arangoex.ok_error(any())
  defp to_result({:ok, result}) when is_list(result), do: Enum.map(result, &to_document(&1))
  defp to_result({:ok, result}), do: to_document(result)
  defp to_result({:error, _} = e), do: e

  @spec to_document(map) :: Arangoex.ok_error(t| map)
  defp to_document(%{} = result) do
    case result do
      %{"error" => true, "errorMessage" => _em, "errorNum" => _en} -> {:error, result}
      %{"old" => old, "new" => new} -> {:ok, {Docref.new(result), old, new}}
      %{"old" => old} -> {:ok, {Docref.new(result), old}}
      %{"new" => new} -> {:ok, {Docref.new(result), new}}
      %{"_id" => _id} -> {:ok, Docref.new(result)}
    end
  end
end
