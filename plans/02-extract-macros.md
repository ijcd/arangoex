# Phase 2: Extract Macros

Status: done — `Arango.API` macro at `lib/arango/api.ex` provides `use Arango.API, endpoint: :foo` (pins `@endpoint`, aliases `Request`/`Utils`) and `request(method: X, path: Y, ...)` (builds `%Request{}` with endpoint pre-filled, `:method` → `:http_method`). All 14 API modules converted: administration, aql, collection, cursor, database, document, graph, graph_edge, index, simple, task, transaction, user, wal. Decoder helpers deferred — too many shapes (PlainDecoder, struct-list/single, custom list+to_document) for a single macro to be a win. 210 pass / 0 fail / 11 skip.

## Goal

Reduce ~130 Request-building functions from 5-10 repeating patterns into macro-assisted definitions. Target: ~400-500 lines eliminated.

## New File

`lib/arango/api.ex` — macro module providing:

### Macro 1: `use Arango.API, endpoint: :collection`

Sets `@endpoint` module attribute, aliases Request/Utils. Every API module uses this instead of manually aliasing.

### Macro 2: `request/1` helper

Builds `%Request{}` with `@endpoint` pre-filled:

```elixir
# Before (repeated 130+ times):
%Request{endpoint: :collection, http_method: :get, path: "collection"}

# After:
request(method: :get, path: "collection")
```

### Macro 3: `struct_decoder/1` and `plain_decoder/0`

```elixir
# Before (repeated 8+ times, 6 lines each):
defmodule CollectionDecoder do
  def decode_ok(%{"result" => result}) when is_list(result), do: {:ok, Enum.map(result, &Collection.new(&1))}
  def decode_ok(result), do: {:ok, Collection.new(result)}
end

# After:
defmodule Decoder do
  use Arango.API.Decoder, struct: Arango.Collection
end
```

## Migration Order

1. Write `lib/arango/api.ex` with macros
2. Convert `Collection` module as proof of concept
3. Run collection tests to verify
4. Convert remaining modules one at a time, testing each

## Pre-coding tasks

Before writing the macros, we need to:

1. **Pick 5-10 representative call sites** from different modules and write before/after pairs by hand. This validates the macro design holds up across the variety of patterns (simple GET, POST with body, opts splitting, decoder-using, system_only, etc.).
2. **Decide on quoted-syntax mechanics**:
   - `@endpoint` module attribute or implicit from `use` macro?
   - How does the macro know about the module's nested decoders?
3. **Decide test strategy**: do macros get their own unit tests, or only integration via existing module tests?

## Files to Change

- New: `lib/arango/api.ex`
- Modify: all 18 implemented modules in `lib/arango/*.ex`

## Not Doing

- No full DSL that hides function signatures
- No `defapi` — functions stay explicit and readable
- No test macros (tests are verbose but clear, leave them)
