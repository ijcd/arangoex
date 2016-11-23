defmodule UtilsTest do
  use ExUnit.Case
  doctest Arangoex

  alias Arangoex.Utils
 
  # test "headers_from_opts" do
  #   assert %{} = Utils.headers_from_opts([], [])
  #   assert %{} = Utils.headers_from_opts([], [:foo])
  #   assert %{"Foo" => 1} = Utils.headers_from_opts([foo: 1], [:foo, :bar, :baz])
  #   assert %{"Foo" => 1, "Bar" => 2, "Baz" => 3} = Utils.headers_from_opts([foo: 1, bar: 2, baz: 3], [:foo, :bar, :baz])
  #   assert %{"Foo" => 1, "Bingo-Boo" => 2} = Utils.headers_from_opts([foo: 1, bingo_boo: 2], [:foo, :bingo_boo])
  #   assert %{"Foo" => 1, "Bingo-Boo" => 2} = Utils.headers_from_opts([foo: 1, bingoBoo: 2], [:foo, :bingoBoo])    
  #   assert_raise RuntimeError, "unknown key: bar", fn ->
  #     Utils.headers_from_opts([foo: 1, bar: 2, baz: 3], [:foo, :baz])      
  #   end
  # end
  
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

  # test "atom_to_header" do
  #   assert "One" = Utils.atom_to_header(:one)
  #   assert "One-Two" = Utils.atom_to_header(:one_two)
  #   assert "One-Two-Three" = Utils.atom_to_header(:one_two_three)    
  #   assert "One-Two" = Utils.atom_to_header(:oneTwo)
  #   assert "One-Two-Three" = Utils.atom_to_header(:oneTwoThree)
  # end

  # test "atom_to_var" do
  #   assert "one" = Utils.atom_to_var(:one)
  #   assert "oneTwo" = Utils.atom_to_var(:one_two)
  #   assert "oneTwoThree" = Utils.atom_to_var(:one_two_three)    
  #   assert "oneTwo" = Utils.atom_to_var(:oneTwo)
  #   assert "oneTwoThree" = Utils.atom_to_var(:oneTwoThree)
  # end
end
