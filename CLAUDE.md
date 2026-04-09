# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Arango (formerly Arangoex) — a low-level Elixir driver for ArangoDB. Builds `Arango.Request` structs representing API operations, then executes them via Tesla/httpc.

## Commands

```bash
mix deps.get              # install dependencies
mix test                  # run all tests (requires running ArangoDB)
mix test test/arango/database_test.exs  # run single test file
mix test --only line:42   # run single test by line number
mix credo                 # lint
mix dialyzer              # type checking
mix test.watch            # auto-run tests + credo + dialyzer on change (dev only)
```

## ArangoDB for Tests

Tests require a running ArangoDB instance. Use `./reset_docker.sh` to start one in Docker (ArangoDB 3.1.26). It generates a random root password, copies it to clipboard, and updates `../.envrc`.

Environment variables needed:
- `ARANGO_HOST` — ArangoDB host (default: localhost)
- `ARANGO_USER` — ArangoDB username
- `ARANGO_PASSWORD` — ArangoDB root password

## Architecture

**Operation pattern**: Each API module (e.g., `Arango.Database`, `Arango.Collection`) builds an `Arango.Request` struct describing the HTTP call. The struct is then passed to `Arango.request/2` which delegates to `Arango.Request.perform/2` for execution.

```elixir
# Build operation, then execute
Arango.Database.list_databases() |> Arango.request()
Arango.Collection.create("name") |> Arango.request(database_name: "mydb")
```

**Key modules**:
- `Arango.Request` — HTTP execution via Tesla, auth headers, response decoding
- `Arango.Config` — Layered config: defaults → app env → endpoint env → call overrides
- `Arango.Request.ApiConn` — Tesla client setup (httpc adapter)

**Config layering** (`Arango.Config.new/2`): Defaults → `config :arango` → `config :arango, :endpoint` → per-call overrides. Supports `{:system, "ENV_VAR"}` for runtime values.

**Response decoding**: Modules can define an `ok_decoder` (e.g., `PlainDecoder`) on the Request struct for custom success response parsing. Generic JSON decoding happens in `decode_adapter_response/1`.

**Test infrastructure** (`test/test_helper.exs`): `Arango.TestCase` creates a fresh database and collection per test, cleans up databases/users/functions/tasks on exit. Helper functions: `arango/2` (request with test config), `on_db/2` (request scoped to test database).

## API Coverage

Modules map 1:1 to ArangoDB REST API areas: Administration, AQL, Bulk, Cluster, Collection, Cursor, Database, Document, Graph, GraphEdge, GraphTraversal, Index, Job, Replication, Simple, Task, Transaction, User, WAL.
