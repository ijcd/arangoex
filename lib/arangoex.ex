defmodule Arangoex do
  @moduledoc """
  Provides and elixir adapter for ArangoDB
  """

  defmodule Error do
    defexception message: "ArangoDB error"
  end  
end
