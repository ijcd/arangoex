defmodule Arango.APITest do
  use ExUnit.Case, async: true

  # Throwaway module exercising the macro the way a real API module does.
  defmodule Sample do
    use Arango.API, endpoint: :sample

    def simple, do: request(method: :get, path: "things")
    def with_body, do: request(method: :post, path: "things", body: %{a: 1})

    def full,
      do: request(method: :put, path: "things/1", query: %{x: 1}, system_only: true, encode_body: false)
  end

  test "pre-fills endpoint from @endpoint" do
    assert %Arango.Request{endpoint: :sample} = Sample.simple()
  end

  test "maps :method to :http_method" do
    assert %Arango.Request{http_method: :get} = Sample.simple()
    assert %Arango.Request{http_method: :post} = Sample.with_body()
  end

  test "passes through path and body" do
    assert %Arango.Request{path: "things"} = Sample.simple()
    assert %Arango.Request{path: "things", body: %{a: 1}} = Sample.with_body()
  end

  test "leaves Request struct defaults intact when fields omitted" do
    op = Sample.simple()
    assert op.query == %{}
    assert op.headers == %{}
    assert op.system_only == false
    assert op.encode_body == true
    assert op.body == nil
  end

  test "carries optional fields when given" do
    op = Sample.full()
    assert op.query == %{x: 1}
    assert op.system_only == true
    assert op.encode_body == false
  end
end
