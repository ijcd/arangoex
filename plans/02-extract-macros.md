# Phase 2: Extract Macros

Status: planned

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

## Files to Change

- New: `lib/arango/api.ex`
- Modify: all 18 implemented modules in `lib/arango/*.ex`

## Not Doing

- No full DSL that hides function signatures
- No `defapi` — functions stay explicit and readable
- No test macros (tests are verbose but clear, leave them)
