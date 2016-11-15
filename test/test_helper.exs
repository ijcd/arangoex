ExUnit.start()

defmodule Arangoex.TestHelper do
  def test_endpoint do
    %Arangoex.Endpoint{
      host: System.get_env("ARANGO_HOST"),
      use_auth: :basic,
      username: System.get_env("ARANGO_USER"),
      password: System.get_env("ARANGO_PASSWORD"),
    }
  end
end
