# Phase 6: Quality of Life

Status: planned

## Goal

Implement convenience features that were planned but never finished.

## Features

### `Arango.request!/2` — raise on error
Currently commented out in `lib/arango.ex`. Uncomment and implement:
```elixir
def request!(op, config_overrides \\ []) do
  case request(op, config_overrides) do
    {:ok, result} -> result
    {:error, error} -> raise Arango.Error, message: inspect(error)
  end
end
```

### `Arango.stream!/2` — cursor streaming
Returns a `Stream` that auto-fetches cursor batches:
```elixir
Arango.Cursor.create("FOR p IN products RETURN p") |> Arango.stream!()
```

### JWT Authentication
Add JWT auth flow: `POST /_open/auth` → token → Bearer header. Auto-refresh on 401.

### Typed Errors
Replace raw `{:error, map}` with structured error:
```elixir
%Arango.Error{
  code: 1203,
  error_num: 1203,
  message: "collection not found",
  http_status: 404
}
```

### Retry mechanism
Implement the retry config that's been a TODO in `lib/arango/config.ex` since the beginning.

## Files

- `lib/arango.ex` — request!, stream!
- `lib/arango/error.ex` — new, typed errors
- `lib/arango/auth.ex` — new, JWT flow
- `lib/arango/request.ex` — retry logic, error struct integration
