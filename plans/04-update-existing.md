# Phase 4: Update Existing Modules to 3.12 API

Status: planned

## Overview

Bring already-implemented modules to current 3.12 v0 surface: add endpoints, options, and parameters introduced since 3.1; switch endpoints whose path/verb changed; drop dead paths. Each module is an independent sub-PR — small, reviewable, mergeable in any order. No new namespaces (Views, Analyzers, Stream Transactions, Auth, Token, Import, Job) — those are Phase 5.

**Scope boundary vs Phase 5.** The previous sketch listed stream transactions here under "Transaction — rework". Move them to Phase 5. Justification: stream tx is a new module (`Arango.Transaction.Stream`), new lifecycle (begin/commit/abort/status), and the `transaction_id` parameter must thread through Document/Cursor/Collection — a cross-cutting feature, not a within-module update. Phase 4 stays "shape today's modules to 3.12 v0"; Phase 5 adds new things. Existing `Arango.Transaction` (JS) keeps its `@deprecated` tag from Phase 3 and gets no other change here.

**Test verification.** Each sub-PR must pass `mix test` against the 3.12 Docker container (`./reset_docker.sh`). Skipped tests get unskipped where the new endpoint enables them; new endpoints get new tests.

**References.** OpenAPI v0 spec (`OpenAPI/0-openapi.json` in arangodb/arangodb devel); python-arango `database.py`, `collection.py`, `cursor.py`, `aql.py`, `wal.py`.

## Sub-PR sequencing

Recommended merge order (small/independent first, builds confidence; risky/large last):

1. **Index** — biggest win, well-isolated, drives a lot of test additions.
2. **Cursor** — protocol change (POST next-batch + retry), small surface, unlocks Phase 5 stream tx.
3. **Administration** — many small additions, no cross-cutting risk.
4. **Document** — option additions only; low risk.
5. **Collection** — option additions plus `compact`/`shards`.
6. **Database** — three options on create.
7. **AQL** — verify slow/kill; add query-plan-cache + optimizer rules listing.
8. **User** — collection-level grant/revoke.
9. **WAL** — rework: old `/_admin/wal/*` is gone, new `/_api/wal/*` replaces it.
10. **Task** — verify-only; tag `@deprecated` if not already.

Reasoning: Index first because it has the most net-new function value (vector, inverted, TTL, MDI for AI workloads) and the existing `create_*` shapes don't need to change. Cursor early because the verb change is small but is a correctness fix that affects every cursor-using test. WAL late because it's effectively a delete-then-rewrite — the worst diff to review, best done when reviewers have warmed up on the easy ones.

---

## 1. Index (`lib/arango/index.ex`)

### Files
- `lib/arango/index.ex`
- `test/arango/index_test.exs`

### Functions
- `create_inverted(collection_name, fields, opts \\ [])` — POST `/_api/index#inverted`. ArangoSearch inverted index; body `type: "inverted"`, `fields`, opts: `name`, `analyzer`, `features`, `includeAllFields`, `searchField`, `trackListPositions`, `parallelism`, `consolidationIntervalMsec`, `commitIntervalMsec`, `cleanupIntervalStep`, `primarySort`, `storedValues`.
- `create_ttl(collection_name, field, expire_after, opts \\ [])` — POST `/_api/index#ttl`. Single field, `expireAfter` seconds, opts: `name`, `inBackground`.
- `create_mdi(collection_name, fields, field_value_types, opts \\ [])` — POST `/_api/index#mdi`. Multi-dimensional (replaces zkd); body `type: "mdi"`, `fields`, `fieldValueTypes`, opts: `unique`, `sparse`, `storedValues`, `name`, `inBackground`.
- `create_vector(collection_name, field, params, opts \\ [])` — POST `/_api/index#vector`. Vector embedding index; body `type: "vector"`, `fields: [field]`, `params` (map: `metric`, `dimension`, `nLists`, `trainingIterations`, `factory`), opts: `name`, `inBackground`, `storedValues`, `parallelism`.

### Removals
None. Keep `create_hash/3` and `create_skiplist/3` with their existing `@deprecated` markers from Phase 3 — server accepts them in 3.12 and rewrites to persistent.

### Tests
- `create_inverted/3 creates an inverted index on a collection` — assert returned `type: "inverted"`, fields echo.
- `create_ttl/4 creates a TTL index with expireAfter` — insert doc, check it disappears after threshold (or skip in CI, assert metadata only).
- `create_mdi/4 creates a multi-dimensional index` — geographic-style points, assert `type: "mdi"`.
- `create_vector/4 creates a vector index with params` — assert metadata; gated on server build flags (skip if 400).
- `indexes/1 lists all created index types` — extend existing test to include inverted/ttl/mdi/vector.

---

## 2. Cursor (`lib/arango/cursor.ex`)

### Files
- `lib/arango/cursor.ex`
- `test/arango/cursor_test.exs`

### Functions
- `cursor_next/1` — change verb from `:put` to `:post` on `/_api/cursor/{cursor-id}`. PUT is still accepted in 3.12 but `POST` is the documented form going forward; v1 will drop PUT.
- `cursor_next_batch/2` (new) — POST `/_api/cursor/{cursor-id}/{batch-id}`. Retry-fetch of a specific batch; only valid when the cursor was created with `allowRetry: true`. Returns the batch identified by `batch-id`.
- `cursor_create/1` — extend the `Cursor` struct with `:allow_retry` (`allowRetry` in options) and `:stream` (`stream` in options). Both go in the `options` sub-object. `:ttl` is already declared on the struct but not emitted; wire it through to the top-level body.

### Tests
- `cursor_next/1 uses POST and returns next batch` — observe verb via Tesla test adapter or assert behavior matches a PUT-based control run.
- `cursor_next_batch/2 re-fetches a batch when allowRetry is set` — create with `allow_retry: true`, fetch batch 1, call again with the same batch id, assert identical payload.
- `cursor_create/1 emits stream option when set` — body assertion via debug request.
- `cursor_create/1 emits ttl at the top level` — bodies sent today drop ttl; assert present.

---

## 3. Administration (`lib/arango/administration.ex`)

### Files
- `lib/arango/administration.ex`
- `test/arango/administration_test.exs`

### Functions
- `engine/0` — GET `/_api/engine`. Reports the storage engine (rocksdb on 3.12).
- `engine_stats/0` — GET `/_api/engine/stats`. Engine internals (rocks counters).
- `metrics/0` — GET `/_admin/metrics/v2`. Prometheus text format; `ok_decoder: PlainDecoder` (it's text, not JSON). Replaces `statistics/0` and `statistics_description/0` (already `@deprecated`).
- `status/0` — GET `/_admin/status`. Server boot/process status.
- `mode/0` — GET `/_admin/server/mode`. Returns `default` or `readonly`.
- `set_mode/1` — PUT `/_admin/server/mode`, body `%{mode: "default" | "readonly"}`.
- `availability/0` — GET `/_admin/server/availability`. 200 = ready to serve.
- `support_info/0` — GET `/_admin/support-info`. Diagnostics bundle.
- `log_level/0` — GET `/_admin/log/level`. Per-topic log levels.
- `set_log_level/1` — PUT `/_admin/log/level`, body is a map of topic → level.
- `log_entries/1` — GET `/_admin/log/entries`. Same params as `log/1` but returns structured entries (`log/1` keeps the legacy parallel-arrays shape).
- `compact/1` — PUT `/_admin/compact`, body `%{changeLevel: bool, compactBottomMostLevel: bool}`.

### Removals
None at the module level. `execute/2` was already removed in Phase 3 (404 in 3.12).

### Tests
- `engine/0 returns rocksdb` — assert `name: "rocksdb"`.
- `engine_stats/0 returns counter map` — non-empty map.
- `metrics/0 returns Prometheus text` — assert string starts with `#` or contains `arangodb_`.
- `status/0 reports running server` — assert `serverInfo.state` present.
- `mode/0 returns default` — fresh container.
- `set_mode/1 round-trips readonly then back` — guard with reset to default in on_exit.
- `availability/0 returns 200` — assert ok.
- `log_level/0 returns topic map` — non-empty map.
- `set_log_level/1 changes one topic and restores` — assert delta.
- `log_entries/1 returns structured entries` — assert `messages` array.
- `compact/1 succeeds on empty database` — assert ok.

---

## 4. Document (`lib/arango/document.ex`)

### Files
- `lib/arango/document.ex`
- `test/arango/document_test.exs`

### Functions (option additions on existing endpoints)
- All insert/update/replace functions accept new query params:
  - `refillIndexCaches` (bool) — repopulate index caches after the write.
  - `versionAttribute` (string) — optimistic concurrency by external version field.
- Multi-document operations (`#multiple` endpoint) — verify the same options pass through; today they go via the same insert paths.

No new functions; this is options threading through `Utils.opts_to_query/2` allowlists.

### Tests
- `document_create/3 with refillIndexCaches succeeds` — assert ok; behavior is observable only under load, so smoke-test only.
- `document_update/4 with versionAttribute rejects stale version` — insert v=1, update with v=2 (ok), update again with v=1 (412/conflict).
- `documents_create/3 (multi) accepts refillIndexCaches` — smoke-test ok.

---

## 5. Collection (`lib/arango/collection.ex`)

### Files
- `lib/arango/collection.ex`
- `test/arango/collection_test.exs`

### Functions
- `create/2` — extend body allowlist with `:schema` (JSON Schema for document validation), `:computedValues` (auto-derived attributes), `:cacheEnabled` (in-memory cache).
- `properties/1` — verify returned shape includes `cacheEnabled`, `schema`, `computedValues` when set.
- `set_properties/2` — extend body allowlist with `:cacheEnabled`, `:schema`, `:computedValues` (server allows PATCH on these).
- `compact/1` (new) — PUT `/_api/collection/{name}/compact`. Triggers compaction.
- `shards/1` (new) — GET `/_api/collection/{name}/shards`. Cluster-only; in single-server returns 400 — test should skip or assert 400.
- `responsible_shard/2` (new) — PUT `/_api/collection/{name}/responsibleShard`, body is a document; returns shard id. Cluster-only; same skip rule.

### Tests
- `create/2 with schema validates documents` — set schema rejecting missing field, insert valid + invalid, assert second is rejected.
- `create/2 with computedValues populates derived attribute` — insert doc, assert derived attr present.
- `create/2 with cacheEnabled returns flag in properties` — assert echoed.
- `set_properties/2 toggles cacheEnabled` — assert via properties read-back.
- `compact/1 succeeds on a populated collection` — insert 100 docs, compact, assert ok.
- `shards/1 returns shards in cluster mode (skip in single server)` — tag `:cluster`.
- `responsible_shard/2 returns shard id (skip in single server)` — tag `:cluster`.

---

## 6. Database (`lib/arango/database.ex`)

### Files
- `lib/arango/database.ex`
- `test/arango/database_test.exs`

### Functions
- `create/2` — extend body `options` sub-object allowlist with `:sharding` (string: "single" | "flexible"), `:replicationFactor` (int or "satellite"), `:writeConcern` (int). Per spec these go under `options:`, not at top level.

### Tests
- `create/2 with sharding sets sharding strategy` — create db with `sharding: "single"`, fetch via `current/0`, assert.
- `create/2 with replicationFactor accepts integer` — cluster-only behaviour; single-server tolerates the field; assert no error.
- `create/2 with writeConcern accepts integer` — same; tag `:cluster` if cluster-only.

---

## 7. AQL (`lib/arango/aql.ex`)

### Files
- `lib/arango/aql.ex`
- `test/arango/aql_test.exs`

### Functions
- `query_rules/0` — GET `/_api/query/rules`. Lists optimizer rules and whether each is on/off by default.
- `clear_plan_cache/0` — DELETE `/_api/query-plan-cache`. Empties the plan cache.
- `plan_cache_entries/0` — GET `/_api/query-plan-cache`. Lists cached plans.
- Verify `slow_queries/0`, `clear_slow_queries/0`, `kill_query/1`, `current_queries/0`, `query_properties/0`, `set_query_properties/1` still match 3.12 (likely unchanged — spec inspection shows same paths and shapes).
- AQL user functions (`functions/0`, `create_function/1`, `delete_function/1`) remain `@deprecated` (Phase 3); no code change.

### Tests
- `query_rules/0 returns optimizer rules` — assert non-empty list, each entry has `name` and `flags`.
- `clear_plan_cache/0 succeeds` — run a query, clear, assert ok.
- `plan_cache_entries/0 lists cached plans` — run a query with `usePlanCache: true` (Cursor option), assert at least one entry.
- `slow_queries/0 still returns expected shape` — sanity test against 3.12.

---

## 8. User (`lib/arango/user.ex`)

### Files
- `lib/arango/user.ex`
- `test/arango/user_test.exs`

### Functions
- `grant/3` — PUT `/_api/user/{user}/database/{dbname}/{collection}`, body `%{grant: "rw" | "ro" | "none"}`. Adds collection-level permission alongside the existing database-level `grant/2`.
- `revoke/3` — DELETE `/_api/user/{user}/database/{dbname}/{collection}`. Removes collection-level permission (falls back to database-level default).
- `permissions/1` and `permissions/2` (new) — GET `/_api/user/{user}/database` (existing `databases/1`) and `/_api/user/{user}/database/{dbname}` (effective db permission). Add the per-db lookup; existing `databases/1` becomes `permissions/1`'s underlying call.
- `permission/3` — GET `/_api/user/{user}/database/{dbname}/{collection}`. Returns the effective collection-level grant.

Keep two-arg `grant/2`, `revoke/2` (database-level). New three-arg variants take an extra `collection` param.

### Tests
- `grant/3 grants ro on a collection` — create user, grant ro, assert via `permission/3`.
- `grant/3 with rw allows writes via that user` — sanity test: open a cursor as the user, write succeeds.
- `revoke/3 removes collection-level grant` — assert falls back to db default.
- `permission/3 returns the effective grant` — covers grant levels: rw/ro/none/undefined.

---

## 9. WAL (`lib/arango/wal.ex`)

### Files
- `lib/arango/wal.ex`
- `test/arango/wal_test.exs`

### Functions
**Remove (404 in 3.12):**
- `flush/1` — `/_admin/wal/flush` no longer exists.
- `properties/0` — `/_admin/wal/properties` no longer exists.
- `set_properties/1` — same.
- `transactions/0` — `/_admin/wal/transactions` no longer exists.

**Replace with:**
- `last_tick/0` — GET `/_api/wal/lastTick`. Current WAL position.
- `range/0` — GET `/_api/wal/range`. Min/max tick range available.
- `tail/1` — GET `/_api/wal/tail`. Streams WAL operations; opts: `global`, `from`, `to`, `lastScanned`, `chunkSize`, `syncerId`, `serverId`, `clientInfo`. Returns NDJSON or JSON depending on Accept.

Drop the `Arango.Wal` struct and `WalDecoder` — there are no more "properties" to model. New endpoints return plain maps/streams.

### Tests
- `last_tick/0 returns a numeric tick` — assert tick is a string of digits.
- `range/0 returns tickMin/tickMax` — both numeric strings, min ≤ max.
- `tail/1 with from=0 returns operations` — write a doc, tail from 0, assert at least one entry references the collection.
- Delete the existing tests for flush/properties/transactions.

This is a breaking change to the public API; flag prominently in the PR body. Reasonable because the old endpoints return 404 — no user can be relying on them.

---

## 10. Task (`lib/arango/task.ex`)

### Files
- `lib/arango/task.ex`
- `test/arango/task_test.exs`

### Functions
- Verify-only. All five endpoints (`tasks/0`, `task/1`, `create/2`, `register/2`, `delete/1`) work as-is in 3.12 v0. Confirm with the existing test suite.
- Already tagged `@deprecated` per Phase 3 (v1/4.0 removal). No code change unless tests fail.

### Tests
- Existing tests should pass. If any are skipped, attempt to un-skip and document.

---

## Unresolved questions

- Cursor: keep `cursor_next/1` PUT for back-compat and add `cursor_next_post/1`, or flip in place (breaks any caller that mocks the verb)? Prop: flip in place — no observable behavior diff.
- Index: `create_inverted/3` opts surface is huge. Pass opts map raw or curate? Prop: curate the docs, pass map raw (server validates).
- WAL rework: hard-break (delete fns) vs soft-break (raise with replacement hint)? Prop: hard-delete — endpoints return 404 anyway.
- Administration: `metrics/0` is text/plain, not JSON. Add a generic `text_ok_decoder` or per-call `decode_body: false`? Prop: add an explicit `:text` ok_decoder branch in `Arango.Request`.
- Collection schema/computedValues: model as Elixir struct or pass raw map? Prop: raw map for now; struct in a later QoL pass.
- Database options: spec wraps `replicationFactor`/`writeConcern`/`sharding` under `options:`. Existing tests pass them flat. Confirm by curl against 3.12 — fix tests if needed.
- User collection-level: spec uses `DELETE /_api/user/.../{collection}` for revoke but `PUT` with `grant: "none"` also works. Pick one. Prop: DELETE for revoke, PUT for grant.
- Sub-PR isolation: each sub-PR branches off master or chains? Prop: branch off master; merge order is sequencing not dependency.
