defmodule Arango.GraphEdge do
  @moduledoc "ArangoDB Graph Edge methods"

  use Arango.API, endpoint: :graph_edge

  @doc """
  Read in or outbound edges

  GET /_api/edges/{collection-id}
  """
  @spec edges(String.t, String.t, String.t) :: Arango.ok_error(map)
  def edges(collection_name, vertex_id, direction \\ nil) do
    query = case direction do
              d when d in ["in", "out"] -> Utils.opts_to_query([vertex: vertex_id, direction: d], [:vertex, :direction])
              nil -> Utils.opts_to_query([vertex: vertex_id], [:vertex])
            end

    request(
      method: :get,
      path: "edges/#{collection_name}",
      query: query
    )
  end
end
