defmodule EndpointTest do
  use ExUnit.Case
  doctest Arangoex

  alias Arangoex.Endpoint

  describe "opts_with_defaults" do
    test "sets defaults" do
      defaults = [foo: 1, bar: 2]      
      assert %{foo: 1, bar: 2} = Endpoint.opts_with_defaults([], defaults)
    end

    test "works with empty defaults" do
      defaults = []      
      m = Endpoint.opts_with_defaults([], defaults)
      assert length(Map.to_list(m)) == 0
    end

    test "complains about unknown key" do
      defaults = [foo: 1]
      assert_raise RuntimeError, ~r/^unknown key/, fn ->
        Endpoint.opts_with_defaults([bar: 2], defaults)
      end
    end
  end
end
