defmodule Arangoex do
  @moduledoc """
  Provides and elixir adapter for ArangoDB
  """
 
  @type arango_error :: {:error, %{}}
  @type ok_error(success) :: {:ok, success} | arango_error
 
  defmodule Error do
    defexception message: "ArangoDB error"
  end  
end
