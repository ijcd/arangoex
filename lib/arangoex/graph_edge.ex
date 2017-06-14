defmodule Arangoex.GraphEdge do
  @moduledoc "ArangoDB Graph Edge methods"

  alias Arangoex.Request
  alias Arangoex.Utils

  @doc """
  Read in or outbound edges

  GET /_api/edges/{collection-id}
  """
  @spec edges(String.t, String.t, String.t) :: Arangoex.ok_error(map)
  def edges(collection_name, vertex_id, direction \\ nil) do
    query = case direction do
              d when d in ["in", "out"] -> Utils.opts_to_query([vertex: vertex_id, direction: d], [:vertex, :direction])
              nil -> Utils.opts_to_query([vertex: vertex_id], [:vertex])
            end

    %Request{
      endpoint: :graph_edge,
      http_method: :get,
      path: "edges/#{collection_name}",
      query: query,
    }
  end
end
