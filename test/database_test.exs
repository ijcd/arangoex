defmodule Arangoex.Database do
  @moduledoc "ArangoDB Database methods"

  alias Arangoex.Endpoint

  defstruct [:id, :name, :isSystem, :path, :users]
  use ExConstructor
 
  def current(endpoint) do
    endpoint
    |> Endpoint.with_db("_system")
    |> Endpoint.get("database/current")
    |> to_database
  end

  defp to_database({:ok, %{"result" => result}}) do
    new(result)
  end      
end


defmodule DatabaseTest do
  use ExUnit.Case
  doctest Arangoex

  import Arangoex.TestHelper

  alias Arangoex.Database

  test "looks up the current databsse" do
    db = testdb
    |> Database.current

    assert db == %Arangoex.Database{id: "1", isSystem: true, name: "_system", path: "/var/lib/arangodb3/databases/database-1", users: nil}
  end
end
