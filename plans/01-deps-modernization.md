# Phase 1: Deps Modernization

Status: planned

## Goal

Get the project compiling and tests runnable on modern Elixir with current dependency versions.

## Context

All deps are from 2016-2017. Tesla 0.10 → 1.x has breaking API changes. Poison → Jason is the ecosystem standard. Config syntax changed. The project won't compile on modern Elixir without these updates.

## Changes

### 1. mix.exs — update all deps

```
tesla ~> 0.10.0     → tesla ~> 1.15
poison >= 1.0.0     → jason ~> 1.4
exconstructor 1.0.2 → exconstructor ~> 1.2
faker > 0.0.0       → faker ~> 0.18
mix_test_watch 0.2  → mix_test_watch ~> 1.0
credo ~> 0.8        → credo ~> 1.7
dialyxir ~> 0.4     → dialyxir ~> 1.4
ex_doc ~> 0.14      → ex_doc ~> 0.34
(new)                 finch ~> 0.19
```

Also: bump `elixir: "~> 1.5"` → `elixir: "~> 1.16"`, update `build_embedded`/`start_permanent` (deprecated patterns).

### 2. config/config.exs — modernize syntax

- `use Mix.Config` → `import Config`

### 3. lib/arango/request.ex — Tesla 1.x migration

This is the only file with Tesla/Poison usage. Changes:

**ApiConn module (lines 4-41):**

| Line | Old (Tesla 0.10) | New (Tesla 1.x) |
|------|-----------------|-----------------|
| 20 | `adapter Tesla.Adapter.Httpc` | `adapter Tesla.Adapter.Finch` |
| 22 | `plug Tesla.Middleware.Tuples` | keep (still works) |
| 23 | `plug Tesla.Middleware.Headers, %{"User-Agent" => ...}` | `plug Tesla.Middleware.Headers, [{"user-agent", ...}]` |
| 26 | `Tesla.build_client [...]` | `Tesla.client [...]` |
| 38 | `{ok_error, %Tesla.Env{...}}` pattern | same shape, but headers are now `[{k,v}]` not map |

**Response struct (line 8-15):**
- `headers: Map.t` → `headers: [{String.t, String.t}]`

**decode_headers (lines 162-168):**
- `headers["etag"]` → find etag in list of tuples

**Poison → Jason (lines 148, 165, 181, 187):**
- `Poison.encode!` → `Jason.encode!`
- `Poison.decode!` → `Jason.decode!`

### 4. Finch supervision

Need to start Finch in application supervision tree. Add to `application/0` in mix.exs or create `lib/arango/application.ex`.

Simplest approach: start a named Finch instance that Tesla's Finch adapter uses.

### 5. Delete mix.lock

Regenerate from scratch with `mix deps.get`.

## Files to Modify

- `mix.exs` — deps, elixir version, application config
- `mix.lock` — delete and regenerate
- `config/config.exs` — Mix.Config → Config
- `lib/arango/request.ex` — Tesla 1.x API, Poison → Jason, Finch adapter
- New: `lib/arango/application.ex` — Finch supervision (if needed)

## Verification

1. `mix deps.get` succeeds
2. `mix compile --warnings-as-errors` succeeds
3. `mix test` runs (tests may fail if no ArangoDB available, but compilation + test framework boot should work)
