# Phase 3: Deprecate & Remove Dead Modules

Status: done — 210 pass / 0 fail / 11 skip after deletions + deprecations.

## Policy: Hybrid by removal date

Two distinct categories warrant different treatment:

1. **Already gone in 3.12** (endpoint returns 404) → **delete the module**.
   The code can't work; keeping it is a trap for users.

2. **Still functional but slated for removal in v1/4.0** → **`@deprecated` annotation**.
   Code keeps working. Compiler warns callers. We delete in a future major version.

This matches the actual ArangoDB lifecycle and minimizes user disruption.

## Category 1: Delete (endpoints don't exist in 3.12)

| Module | File | Reason |
|--------|------|--------|
| `Arango.GraphTraversal` | `lib/arango/graph_traversal.ex` | `/_api/traversal` removed 3.12.0 |
| `Arango.Bulk` (stubbed) | `lib/arango/bulk.ex` | `/_api/batch` removed 3.12.3, was never working |
| `Arango.Replication` (stubbed) | `lib/arango/replication.ex` | API completely reworked, was never working |
| `Arango.Cluster` (stubbed) | `lib/arango/cluster.ex` | API completely reworked, was never working |

Also delete:
- Corresponding test files
- Endpoints from `Arango.Config.Defaults`
- References in test_helper.exs

## Category 2: Deprecate with `@deprecated` (works today, removed in v1/4.0)

For each function, add `@deprecated "..."` annotation pointing to the replacement. For entire-module deprecations, also add a banner in `@moduledoc`.

### Simple (whole module)

```elixir
defmodule Arango.Simple do
  @moduledoc """
  ArangoDB Simple Queries.

  > #### Deprecated {: .warning}
  >
  > The `/_api/simple/*` endpoints have been deprecated since ArangoDB 3.4.
  > Use AQL via `Arango.Cursor.create/1` instead. These endpoints will be
  > removed when ArangoDB 4.0 (API v1) becomes the default.
  """
```

Then `@deprecated` on each of the 14 functions.

### AQL user functions (3 functions in Aql module)

`Aql.functions/0`, `Aql.create_function/1`, `Aql.delete_function/1` — keep the rest of the module.

```elixir
@deprecated "AQL user functions are removed in v1/4.0. Inline the logic into your AQL queries."
def functions, do: ...
```

### Task (whole module)

```elixir
@moduledoc """
ArangoDB server-side scheduled tasks.

> #### Deprecated {: .warning}
>
> The `/_api/tasks/*` endpoints are removed in API v1/4.0. Use an external
> scheduler (cron, Quantum, Oban) instead.
"""
```

### Collection.load/2 and unload/1

```elixir
@deprecated "No-op on RocksDB. Removed in v1/4.0."
def load(collection, opts \\ []), do: ...

@deprecated "No-op on RocksDB. Removed in v1/4.0."
def unload(collection), do: ...
```

### Transaction.transaction/1 (JS-based)

```elixir
@deprecated "JS-based transactions removed in v1/4.0. Use Arango.Transaction.Stream (Phase 5)."
def transaction(transaction), do: ...
```

The replacement (`Arango.Transaction.Stream`) lands in Phase 5.

### Administration.execute/2

Already returns 404 in 3.12 — actually move this to **Category 1** (delete the function).

### Administration.statistics/0 and statistics_description/0

Still work in 3.12 v0, removed in v1.

```elixir
@deprecated "Use Administration.metrics/0 (Prometheus format) in v1/4.0."
def statistics, do: ...
```

(`metrics/0` lands in Phase 4.)

### Administration.reload_routing/0

```elixir
@deprecated "Removed in v1/4.0; routing handled internally."
def reload_routing, do: ...
```

### Index.create_hash/3 and create_skiplist/3

```elixir
@deprecated "Use Index.create_persistent/3 instead. Hash and skiplist indexes are unified into persistent in 3.12."
def create_hash(collection, fields, opts \\ []), do: ...
```

## What this looks like to users

When someone calls a deprecated function, they see at compile time:

```
warning: Arango.Simple.all/2 is deprecated. Use AQL via Arango.Cursor.create/1 instead.
  user_code.ex:42: MyApp.Search.find_users/0
```

Their code still works. They have a clear upgrade path. When 4.0 ships, we cut a major version of the driver and remove all `@deprecated` items.

## Verification

1. `mix compile --warnings-as-errors` — no internal usage of deprecated functions in our own code
2. `mix test` — all 199 passing tests still pass
3. `mix test test/arango/simple_test.exs` — tests still run, possibly emit deprecation warnings (could `@tag :deprecated` to suppress)

## Files to Modify

- Delete: `lib/arango/{graph_traversal,bulk,replication,cluster}.ex` and corresponding tests
- Modify: `lib/arango/simple.ex`, `task.ex`, `collection.ex`, `transaction.ex`, `aql.ex`, `administration.ex`, `index.ex`
- Modify: `lib/arango/config.ex` (Defaults map — remove deleted endpoints)
- Modify: test files for any that reference deleted modules