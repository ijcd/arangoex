defmodule Arango.API do
  @moduledoc """
  Compile-time helpers for API modules.

  ## Usage

      defmodule Arango.Collection do
        use Arango.API, endpoint: :collection

        def collections do
          request(method: :get, path: "collection")
        end
      end

  `use Arango.API, endpoint: :foo` pins `@endpoint` for the module and imports
  the `request/1` macro. `request/1` builds an `Arango.Request` struct with
  `endpoint` pre-filled from `@endpoint`. Pass any other struct field as a
  keyword (`:method` is rewritten to `:http_method`).
  """

  defmacro __using__(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    quote do
      @endpoint unquote(endpoint)
      alias Arango.Request
      alias Arango.Utils
      import Arango.API, only: [request: 1]
    end
  end

  @doc """
  Build an `%Arango.Request{}` with the module's `@endpoint` pre-filled.

  Accepts any `Arango.Request` field. Use `:method` as shorthand for
  `:http_method`.
  """
  defmacro request(opts) do
    quote do
      Arango.API.__build__(@endpoint, unquote(opts))
    end
  end

  @doc false
  def __build__(endpoint, opts) do
    {method, opts} = Keyword.pop(opts, :method)
    fields = [endpoint: endpoint] ++ if(method, do: [http_method: method], else: []) ++ opts
    struct(Arango.Request, fields)
  end
end
