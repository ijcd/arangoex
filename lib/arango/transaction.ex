defmodule Arango.Transaction do
  @moduledoc "ArangoDB Transaction methods"

  use Arango.API, endpoint: :transaction

  defmodule Transaction do
    @moduledoc false

    defstruct [
      :action,
      :params,
      :read_collections,
      :write_collections,
      :allow_implicit,
      :lock_timeout,
      :wait_for_sync
    ]

    @type t :: %__MODULE__{
            # the actual transaction operations to be executed, in the
            # form of stringified JavaScript code. The code will be
            # executed on server side, with late binding. It is thus
            # critical that the code specified in action properly sets up
            # all the variables it needs. If the code specified in action
            # ends with a return statement, the value returned will also
            # be returned by the REST API in the result attribute if the
            # transaction committed successfully.
            action: String.t(),

            # optional arguments passed to action.
            params: String.t(),

            # sub-attributes read and write, each being an array of
            # collection names Collections that will be written to in the
            # transaction must be declared with the write attribute or it
            # will fail, whereas non-declared collections from which is
            # solely read will be added lazily. Collections for reading
            # should be fully declared if possible, to avoid deadlocks.
            read_collections: [String.t()],
            write_collections: [String.t()],

            # The optional sub-attribute allowImplicit can be set to false
            # to let transactions fail in case of undeclared collections for
            # reading.
            allow_implicit: boolean,

            # an optional numeric value that can be used to set a timeout
            # for waiting on collection locks. If not specified, a default
            # value will be used. Setting lockTimeout to 0 will make
            # ArangoDB not time out waiting for a lock.
            lock_timeout: non_neg_integer,

            # an optional boolean flag that, if set, will force the
            # transaction to write all data to disk before returning.
            wait_for_sync: boolean
          }
  end

  @doc """
  Execute transaction

  POST /_api/transaction
  """
  @deprecated "JS-based transactions removed in API v1/4.0. Use Arango.Transaction.Stream (Phase 5)."
  @spec transaction(Transaction.t()) :: Arango.ok_error(map)
  def transaction(t) do
    collections =
      Utils.compact(%{
        "read" => t.read_collections,
        "write" => t.write_collections,
        "allowImplicit" => t.allow_implicit
      })

    body =
      Utils.compact(%{
        :collections => collections,
        :action => t.action,
        "params" => t.params,
        "lockTimeout" => t.lock_timeout,
        "waitForSync" => t.wait_for_sync
      })

    request(
      method: :post,
      path: "transaction",
      body: body
    )
  end
end
