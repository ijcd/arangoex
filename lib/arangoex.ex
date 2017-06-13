# TODO: batch requests
# TODO: batch async requets
# TODO: async job loookup (does it work?)
# TODO: batch async job lookup request (does it work??)

defmodule Arangoex do
  @moduledoc File.read!("#{__DIR__}/../README.md")
 
  @type arango_error :: {:error, %{}}
  @type ok_error(success) :: {:ok, success} | arango_error
 
  defmodule Error do
    defexception message: "ArangoDB error"
  end

  @doc """
  Perform an ArangoDB request

  First build an operation from one of the APIs. Then pass it to this
  function to perform it.

  This function takes an optional second parameter of configuration
  overrides. This is useful if you want to have certain configuration
  changed on a per request basis.

  ## Examples

  ```
  {:ok, dbs} = Arangoex.Database.list_databases() |> ArangoDB.request

  {:ok, dbs} = Arangoex.Database.list_databases() |> ArangoDB.request(username: joe, password: sekret)
  ```

  """
  # @spec request(Arangoex.Operation.t) :: term
  # @spec request(Arangoex.Operation.t, Keyword.t) :: ok_error(term)
  def request(op, config_overrides \\ []) do
    Arangoex.Request.perform(op, Arangoex.Config.new(op.endpoint, config_overrides)) 
  end

  # @doc """
  # Perform an ArangoDB request, raise if it fails.

  # Same as `request/1,2` except it will either return the successful response from
  # ArangoDB or raise an exception.
  # """
  # @spec request!(Arangoex.Operation.t) :: term | no_return
  # @spec request!(Arangoex.Operation.t, Keyword.t) :: term | no_return
  # def request!(op, config_overrides \\ []) do
  #   case request(op, config_overrides) do
  #     {:ok, result} ->
  #       result

  #     error ->
  #       raise Arangoex.Error, """
  #         Arangoex Request Error!

  #         #{inspect error}
  #         """
  #   end
  # end

  # @doc """
  # Return a stream for the ArangoDB resource.

  # ## Examples
  # ```
  # Arangoex.Cursor.create("FOR p IN products RETURN p") |> Arangoex.stream!
  # ```
  # """
  # @spec stream!(Arangoex.Operation.t) :: Enumerable.t
  # @spec stream!(Arangoex.Operation.t, Keyword.t) :: Enumerable.t
  # def stream!(op, config_overrides \\ []) do
  #   Arangoex.Operation.stream!(op, Arangoex.Config.new(op.service, config_overrides))
  # end
end
