defmodule Arangoex.GraphTraversal do
  @moduledoc "ArangoDB Traversal methods"

  alias Arangoex.Endpoint

  defmodule Traversal do
    @moduledoc false

    defstruct [
      :startVertex,
      :graphName,
      :edgeCollection,
      :direction,
      :uniqueness,
      :minDepth,
      :maxDepth,
      :strategy,
      :order,
      :itemOrder,
      :maxIterations,
      :init,
      :filter,
      :visitor,
      :expander,
      :sort
    ]

    @type t :: %__MODULE__{
      # id of the startVertex, e.g. "users/foo"
      startVertex: String.t,

      # name of the graph that contains the edges. Either
      # edgeCollection or graphName has to be given. In case both
      # values are set the graphName is prefered.
      graphName: String.t,

      # name of the collection that contains the edges.
      edgeCollection: String.t,

      # direction for traversal if set, must be either "outbound",
      # "inbound", or "any" if not set, the expander attribute must be
      # specified
      direction: String.t,

      # specifies uniqueness for vertices and edges visited. If set,
      # must be an object like this: "uniqueness": {"vertices":
      # "none"|"global"|"path", "edges": "none"|"global"|"path"}
      uniqueness: map,

      # ANDed with any existing filters): visits only nodes in at least the given depth
      minDepth: pos_integer,

      # ANDed with any existing filters visits only nodes in at most the given depth
      maxDepth: pos_integer,

      # traversal strategy can be "depthfirst" or "breadthfirst"
      strategy: String.t,

      #traversal order can be "preorder", "postorder" or "preorder-expander"
      order: String.t,

      # item iteration order can be "forward" or "backward"
      itemOrder: String.t,

      # Maximum number of iterations in each traversal. This number
      # can be set to prevent endless loops in traversal of cyclic
      # graphs. When a traversal performs as many iterations as the
      # maxIterations value, the traversal will abort with an
      # error. If maxIterations is not set, a server-defined value may
      # be used.
      maxIterations: pos_integer,

      # body (JavaScript) code of custom result initialization
      # function function signature: (config, result) -> void
      # initialize any values in result with what is required
      init: String.t,

      # default is to include all nodes: body (JavaScript code) of
      # custom filter function function signature: (config, vertex, path) ->
      # mixed can return four different string values:
      #
      #  "exclude" -> this vertex will not be visited.
      #
      #  "prune" -> the edges of this vertex will not be followed.
      #
      #  "" or undefined -> visit the vertex and follow it's edges.
      #
      #  Array -> containing any combination of the above. If there is
      #    at least one "exclude" or "prune" respectivly is contained,
      #    it's effect will occur.
      filter: String.t,

      # body (JavaScript) code of custom visitor function function
      # signature: (config, result, vertex, path, connected) -> void
      # The visitor function can do anything, but its return value is
      # ignored. To populate a result, use the result variable by
      # reference. Note that the connected argument is only populated
      # when the order attribute is set to "preorder-expander".
      visitor: String.t,

      #body (JavaScript) code of custom expander function must be set
      #if direction attribute is not set function signature: (config,
      #vertex, path) -> array expander must return an array of the
      #connections for vertex each connection is an object with the
      #attributes edge and vertex
      expander: String.t,

      # body (JavaScript) code of a custom comparison function
      # for the edges. The signature of this function is (l, r) ->
      # integer (where l and r are edges) and must return -1 if l is
      # smaller than, +1 if l is greater than, and 0 if l and r are
      # equal. The reason for this is the following: The order of
      # edges returned for a certain vertex is undefined. This is
      # because there is no natural order of edges for a vertex with
      # multiple connected edges. To explicitly define the order in
      # which edges on the vertex are followed, you can specify an
      # edge comparator function with this attribute. Note that the
      # value here has to be a string to conform to the JSON standard,
      # which in turn is parsed as function body on the server
      # side. Furthermore note that this attribute is only used for
      # the standard expanders. If you use your custom expander you
      # have to do the sorting yourself within the expander code.
      sort: String.t
    }
  end
  

  @doc """
  Executes a traversal

  POST /_api/traversal
  """
  @spec traversal(Endpoint.t, Traversal.t) :: Arangoex.ok_error(map)
  def traversal(endpoint, traversal) do
    endpoint
    |> Endpoint.post("/traversal", traversal)
  end
end
  
