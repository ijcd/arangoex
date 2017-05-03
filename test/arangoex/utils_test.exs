defmodule UtilsTest do
  use ExUnit.Case
  doctest Arangoex

  alias Arangoex.Utils
 
  test "opts_to_headers" do
    assert [] = Utils.opts_to_headers([], [])
    assert [] = Utils.opts_to_headers([], [:foo])
    assert [{"Foo", 1}] = Utils.opts_to_headers([foo: 1], [:foo, :bar, :baz])
    assert [{"Foo", 1}, {"Bar", 2}, {"Baz", 3}] = Utils.opts_to_headers([foo: 1, bar: 2, baz: 3], [:foo, :bar, :baz])
    assert [{"Foo", 1}, {"Bingo-Boo", 2}] = Utils.opts_to_headers([foo: 1, bingo_boo: 2], [:foo, :bingo_boo])
    assert [{"Foo", 1}, {"Bingo-Boo", 2}] = Utils.opts_to_headers([foo: 1, bingoBoo: 2], [:foo, :bingoBoo])    
    assert_raise RuntimeError, "unknown key: bar", fn ->
      Utils.opts_to_headers([foo: 1, bar: 2, baz: 3], [:foo, :baz])      
    end
  end
  
  test "opts_to_query" do
    assert "" = Utils.opts_to_query([], [])
    assert "" = Utils.opts_to_query([], [:foo])
    assert "" = Utils.opts_to_query([foo: nil, bar: nil], [:foo, :bar])        
    assert "?foo=1" = Utils.opts_to_query([foo: 1], [:foo, :bar, :baz])
    assert "?bar=2&baz=3&foo=1" = Utils.opts_to_query([foo: 1, bar: 2, baz: 3], [:foo, :bar, :baz])
    assert "?bingo_boo=2&foo=1" = Utils.opts_to_query([foo: 1, bingo_boo: 2], [:foo, :bingo_boo])
    assert "?bingoBoo=2&foo=1" = Utils.opts_to_query([foo: 1, bingoBoo: 2], [:foo, :bingoBoo])
    assert_raise RuntimeError, "unknown key: bar", fn ->
      Utils.opts_to_query([foo: 1, bar: 2, baz: 3], [:foo, :baz])      
    end
  end

  test "opts_to_vars" do
    assert %{} = Utils.opts_to_vars([], [])
    assert %{} = Utils.opts_to_vars([], [:foo])
    assert %{} = Utils.opts_to_vars([foo: nil, bar: nil], [:foo, :bar])    
    assert %{"foo" => 1} = Utils.opts_to_vars([foo: 1], [:foo, :bar, :baz])
    assert %{"foo" => 1, "bar" => 2, "baz" => 3} = Utils.opts_to_vars([foo: 1, bar: 2, baz: 3], [:foo, :bar, :baz])
    assert_raise RuntimeError, "unknown key: bar", fn ->
      Utils.opts_to_vars([foo: 1, bar: 2, baz: 3], [:foo, :baz])      
    end
  end

  test "ensure_permitted" do
    assert [] = Utils.ensure_permitted([], [])
    assert [] = Utils.ensure_permitted([], [:foo])
    assert [] = Utils.ensure_permitted([foo: nil, bar: nil], [:foo, :bar])
    assert [foo: 1] = Utils.ensure_permitted([foo: 1], [:foo, :bar, :baz])
    assert [foo: 1, bar: 2, baz: 3] = Utils.ensure_permitted([foo: 1, bar: 2, baz: 3], [:foo, :bar, :baz])
    assert_raise RuntimeError, "unknown key: bar", fn ->
      Utils.ensure_permitted([foo: 1, bar: 2, baz: 3], [:foo, :baz])      
    end
  end

  test "to_header_name" do
    assert "One" = Utils.to_header_name(:one)
    assert "One-Two" = Utils.to_header_name(:one_two)
    assert "One-Two-Three" = Utils.to_header_name(:one_two_three)    
    assert "One-Two" = Utils.to_header_name(:oneTwo)
    assert "One-Two-Three" = Utils.to_header_name(:oneTwoThree)
  end
end
