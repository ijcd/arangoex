defmodule Arango do
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
  {:ok, dbs} = Arango.Database.list_databases() |> ArangoDB.request

  {:ok, dbs} = Arango.Database.list_databases() |> ArangoDB.request(username: joe, password: sekret)
  ```

  """
  @spec request(Arango.Request.t, Keyword.t) :: ok_error(term)
  def request(op, config_overrides \\ []) do
    Arango.Request.perform(op, config_overrides)
  end
end
