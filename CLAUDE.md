# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Arango (formerly Arangoex) — low-level Elixir driver for ArangoDB. Build `Arango.Request` structs representing API operations, then execute them via Tesla + Finch. Elixir `~> 1.16`. Target: ArangoDB 3.12+ at API v0.

**In-flight modernization.** Read `plans/00-overview.md` before changing behavior. It's the roadmap (phases, decisions, what's done vs planned). Don't reinvent direction without checking it.

## Commands

```bash
mix deps.get
mix verify                                # format + compile-w-as-errors + credo + dialyzer
mix test                                  # all tests (requires running ArangoDB)
mix test test/arango/database_test.exs    # single file
mix test --only line:42                   # single test by line
mix credo
mix dialyzer                              # first run builds PLT — slow (~3 min)
mix test.watch                            # dev only: test + credo + dialyzer on change
```

`mix verify` runs every static gate CI runs except the integration tests. Use it before pushing if you skipped the pre-push hook.

## CI and pre-commit hooks

CI lives at `.github/workflows/ci.yml`. Every PR runs: `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo`, `mix dialyzer`, and `mix test` against an `arangodb:3.12` service container. The PLT is cached per `mix.lock` hash so subsequent runs are fast.

Local hooks via `lefthook` (configured in `lefthook.yml`):
- **pre-commit** (parallel): `format`, `credo`, `compile --warnings-as-errors`
- **pre-push**: `dialyzer`

One-time after cloning: `lefthook install` (writes `.git/hooks/{pre-commit,pre-push}`). `lefthook` itself is installed via Homebrew (already on this machine per `dot_config/nix/darwin/homebrew.nix`).

**Dialyzer's ignored warnings.** `.dialyzer_ignore.exs` suppresses one class of warnings: `invalid_contract` on the API-builder functions. Those functions return `%Arango.Request{}` but their `@spec`s describe the eventual post-execution shape (`Arango.ok_error(...)`) because that's what users see when they `|> Arango.request()` the op. Rewriting ~80 specs to `:: Arango.Request.t()` is a separate follow-up; until then the ignore file documents the design tension explicitly and CI still gates every other warning class.

## ArangoDB for Tests

`./reset_docker.sh` starts ArangoDB 3.12 via `docker-compose.yml` with fixed root password `test` on `localhost:8529`. Then:

```sh
ARANGO_HOST=localhost ARANGO_USER=root ARANGO_PASSWORD=test mix test
```

Env vars consumed by `Arango.Config` via `{:system, "..."}`: `ARANGO_HOST`, `ARANGO_USER`, `ARANGO_PASSWORD`.

Test isolation: each test creates a fresh db + collection and cleans up the *delta* dbs/users/AQL-functions/tasks on exit (`test/test_helper.exs:57-103`). Interrupted runs can leak; `./reset_docker.sh` wipes the container.

## Architecture

**Operation pattern.** Each API module (`Arango.Database`, `Arango.Collection`, …) builds an `Arango.Request` struct describing one HTTP call. `Arango.request/2` delegates to `Arango.Request.perform/2`.

```elixir
Arango.Database.list_databases() |> Arango.request()
Arango.Collection.create("name") |> Arango.request(database_name: "mydb")
```

**HTTP stack.** Tesla 1.x with `Tesla.Adapter.Finch` (`lib/arango/request.ex:17`). `Arango.Application` supervises `{Finch, name: Arango.Finch}`. JSON via Jason.

**Config cascade** (`lib/arango/config.ex:36-45`): Defaults → common `config :arango` → endpoint-specific `config :arango, <endpoint>` → per-call overrides → `{:system, "ENV_VAR"}` resolution over the merged map.

**Path construction** (`request.ex:135-137`):
- `path` starting with `/` → used as-is
- `system_only: true` → `/_api/<path>`
- otherwise → `/_db/<db>/_api/<path>`

This is the single source of truth for which database an op targets.

**Body encoding** (`request.ex:139-156`): structs are stripped of nil keys; `encode_body: false` passes the body through raw; POST/PUT/PATCH/DELETE with nil body default to `""`. Surprising on first read — check here before debugging request payloads.

**Response decoding.** `Arango.Request.decode_adapter_response/1` parses JSON for 2xx (success) vs other (error). Operations can set `ok_decoder: SomeModule` to post-process the success branch.

**Test helpers** (`test/test_helper.exs`): `arango/2` runs an op with test config; `on_db/2` scopes to the per-test database. Debug variants `darango/2` and `don_db/2` set `debug_requests: true`, printing operation, config, base URL, path, headers, body, raw response, and decoded result — use them when chasing protocol-level bugs.

## API surface

Modules under `lib/arango/` map 1:1 to ArangoDB REST areas at `/_api/<area>` (e.g., `Arango.Cursor` → `/_api/cursor`). See `plans/08-api-coverage.md` for the coverage matrix.
