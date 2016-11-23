defmodule Arangoex.Utils do
  @moduledoc false

  @spec opts_to_headers(keyword, [atom]) :: map
  def opts_to_headers(opts, permitted \\ []) do
    opts
    |> ensure_permitted(permitted)
    |> Enum.map(fn {k, v} -> {atom_to_header(k), v} end)
    |> Enum.into(%{})
  end

  @spec opts_to_query(keyword, [atom]) :: String.t
  def opts_to_query(opts, permitted \\ []) do
    q =
      opts
      |> opts_to_vars(permitted)
      |> Map.to_list
    if Enum.any?(q) do
      "?" <> URI.encode_query(q)
    else
      ""
    end
  end

  @spec opts_to_vars(keyword, [atom]) :: map
  def opts_to_vars(opts, permitted \\ []) do
    opts
    |> ensure_permitted(permitted)
    |> Enum.map(fn {k, v} -> {"#{k}", v} end)
    |> Enum.into(%{})
  end

  @spec ensure_permitted(keyword, [atom]) :: keyword
  def ensure_permitted(opts, permitted \\ []) do
    extra = Keyword.keys(opts) -- permitted
    Enum.any?(extra, &(raise "unknown key: #{&1}"))
    opts
    |> Enum.reject(fn {_, v} -> v == nil end)
    |> Keyword.take(permitted)
  end

  @spec atom_to_header(atom) :: String.t
  def atom_to_header(atom) do
    atom
    |> Atom.to_string
    |> Macro.underscore
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("-")
  end
end
