# Phase 5: Add New API Modules

Status: planned

## Overview

Phase 4 reshaped existing modules to 3.12 v0. Phase 5 adds **new namespaces** the driver never had: `View` (ArangoSearch), `Analyzer`, `Transaction.Stream`, `Job`, `Auth` (JWT), `Token`, `Import`. Each is an independent sub-PR. After Phase 5 the driver covers ~150 of the ~155 in-demand v0 endpoints (~97%).

**Spec sources.** OpenAPI v0 (`OpenAPI/0-openapi.json` in arangodb/arangodb devel, 174 paths total) and python-arango (`arango/database.py` houses Views/Analyzers/Stream Tx/Tokens; `arango/job.py` for jobs; `arango/wal.py` reused-shape reference).

**Scope boundary vs Phase 4.** Stream Transactions thread `transaction_id` through Document/Cursor/Collection/Graph; Phase 4 PRs deliberately did not wire that header. Phase 5 owns both halves: the new `Arango.Transaction.Stream` module **and** the cross-cutting `:transaction_id` opt on existing request builders (Sub-PR 3.a below). Land 3.a before 3.b so the new module's tests can verify in-transaction reads/writes.

**Test verification.** Each sub-PR must pass `mix verify` (format + warnings-as-errors + credo + dialyzer) and `mix test` against `arangodb:3.12` (`./reset_docker.sh`). New test files mirror Phase 4 layout (`test/arango/<module>_test.exs`).

## Sub-PR sequencing

Recommended merge order. Priority drops from HIGH (1–3) to MEDIUM (4–7). Cross-cutting plumbing first inside the Stream Tx PR so downstream depends only on master.

1. **View** — high priority, well-isolated, big surface but no cross-cutting. AI/search story headliner.
2. **Analyzer** — high priority, tiny (4 endpoints). Pairs with View but stands alone; either order works once View is merged.
3. **Transaction.Stream** — high priority. Split into **3.a** (thread `:transaction_id` opt + `x-arango-trx-id` header through Document/Cursor/Collection/Graph) and **3.b** (the new `Arango.Transaction.Stream` module). 3.a is mechanical and reviewable in isolation; 3.b lands on top.
4. **Job** — medium priority, 2 paths (4 ops). Resurrects the Phase-3-deleted stub with the correct 3.12 surface.
5. **Auth** — medium priority. One endpoint (`POST /_open/auth`) returning JWT; Phase 6 adds auto-refresh in the Request layer. Phase 5 ships just the call.
6. **Token** — medium priority. New 3.12 personal access tokens, system-only `/_api/token/{user}`. Independent of Auth.
7. **Import** — medium priority. Single endpoint (`POST /_api/import`) but unusual: `text/plain` body, NDJSON or JSON-array. Last because the encoding wrinkle is the most likely review iteration.

Reasoning. View first because it's the most-asked-for namespace and merging it unblocks the rest psychologically (the big one is in). Analyzer next because reviewers warmed up on View read Analyzer faster. Stream Tx third because 3.a touches every Phase 4 module — regression risk is highest, so we want fresh eyes and recently-passed tests. Job/Auth/Token/Import are independent and can interleave by reviewer availability.

---

## 1. Arango.View (`lib/arango/view.ex`)

ArangoSearch views: full-text/vector/relevance search engine. Two subtypes — `arangosearch` (link-based) and `search-alias` (index-based, 3.10+). Same lifecycle, different create + properties bodies.

Spec endpoints (8):
- `GET /_api/view` — list
- `POST /_api/view` — create arangosearch (or search-alias when `type: "search-alias"`)
- `GET /_api/view/{name}` — view info (summary only)
- `DELETE /_api/view/{name}` — drop
- `GET /_api/view/{name}/properties` — read properties
- `PUT /_api/view/{name}/properties` — replace (arangosearch only)
- `PATCH /_api/view/{name}/properties` — update (both subtypes)
- `PUT /_api/view/{name}/rename` — rename (single-server only; cluster returns 501)

### Files
- `lib/arango/view.ex` (new)
- `test/arango/view_test.exs` (new)

### Functions
- `views/0` — `GET /_api/view`. List all views; returns `result: [...]`. Decoder strips the wrapper.
- `view/1` — `GET /_api/view/{name}`. Summary only (id, name, type, globallyUniqueId).
- `properties/1` — `GET /_api/view/{name}/properties`. Full properties block (links/indexes, consolidation, primarySort, storedValues, etc.).
- `create_arangosearch/2` — `POST /_api/view` with body `%{name, type: "arangosearch", ...opts}`. Opts whitelist (per spec): `links`, `primarySort`, `primarySortCompression`, `primarySortCache`, `primaryKeyCache`, `storedValues`, `consolidationIntervalMsec`, `consolidationPolicy`, `commitIntervalMsec`, `cleanupIntervalStep`, `optimizeTopK`, `writebufferActive`, `writebufferIdle`, `writebufferSizeMax`. Pass raw map for nested structures (`links`, `consolidationPolicy`).
- `create_search_alias/2` — `POST /_api/view` with body `%{name, type: "search-alias", indexes: [...]}`. `indexes` is a list of `%{collection, index}`.
- `drop/1` — `DELETE /_api/view/{name}`. Returns `result: true`.
- `update_properties/2` — `PATCH /_api/view/{name}/properties`. Partial properties map; server merges. Works for both subtypes.
- `replace_properties/2` — `PUT /_api/view/{name}/properties`. Full replacement; arangosearch only (search-alias accepts PATCH only). Document in moduledoc.
- `rename/2` — `PUT /_api/view/{name}/rename`, body `%{name: new_name}`. Single-server only.

### Tests
- `views/0 returns empty list on fresh db` — assert `result == []`.
- `create_arangosearch/2 with empty opts creates a view` — assert `type == "arangosearch"`, id present.
- `create_arangosearch/2 with links links a collection` — create with `links: %{coll => %{includeAllFields: true}}`, read properties, assert link present.
- `create_search_alias/2 with indexes creates search-alias` — depends on a pre-built inverted index (Phase 4 added); assert `type == "search-alias"`.
- `view/1 returns summary` — assert `type` present, no `links`/`indexes` (those live under properties).
- `properties/1 returns full block` — assert `consolidationIntervalMsec` numeric.
- `update_properties/2 patches arangosearch view` — round-trip assertion.
- `replace_properties/2 replaces an arangosearch view` — set links, replace with empty, assert empty.
- `rename/2 renames the view (or surfaces 501 on cluster)` — `:skip` is banned (see #18); assert on the response shape. Accept either `{:ok, %{"name" => new_name}}` (single-server) or `{:error, %{"code" => 501}}` (cluster). Alternative: pure body-shape test asserting the request struct, leaving server-side coverage to whichever deployment runs CI.
- `drop/1 removes a view` — subsequent `view/1` returns 404.

---

## 2. Arango.Analyzer (`lib/arango/analyzer.ex`)

Text-processing pipelines used by ArangoSearch links (identity, text, ngram, stem, norm, classification, geojson, geo_s2, geopoint, aql, pipeline, segmentation, collation, minhash, nearest_neighbors, delimiter). Driver is type-agnostic — passes `type` + `properties` map through.

Spec endpoints (4):
- `GET /_api/analyzer` — list
- `POST /_api/analyzer` — create
- `GET /_api/analyzer/{name}` — definition
- `DELETE /_api/analyzer/{name}` — remove (query param `force`)

### Files
- `lib/arango/analyzer.ex` (new)
- `test/arango/analyzer_test.exs` (new)

### Functions
- `analyzers/0` — `GET /_api/analyzer`. Returns `result: [...]`.
- `analyzer/1` — `GET /_api/analyzer/{name}`. Single definition.
- `create/1` — `POST /_api/analyzer`. Body `%{name, type, properties, features}`. Required: `name`, `type`. `features` defaults to `[]`; allowed values per spec: `frequency`, `norm`, `position`, `offset`.
- `drop/2` — `DELETE /_api/analyzer/{name}`, opts: `force` (boolean, query param). Force removes even when in use by a view.

### Tests
- `analyzers/0 returns built-in identity and text analyzers` — assert at least `"identity"` and `"text_en"` present.
- `create/1 creates a delimiter analyzer` — `%{name: "comma", type: "delimiter", properties: %{delimiter: ","}}`; assert `properties` echoed.
- `create/1 with features creates a text analyzer` — features `["frequency","position","norm"]`; assert echoed.
- `analyzer/1 returns a created definition` — round-trip.
- `drop/2 removes an analyzer` — subsequent `analyzer/1` returns 404.
- `drop/2 with force removes in-use analyzer` — create, link via a view, drop without force (409), drop with force (200).

---

## 3. Arango.Transaction.Stream (two sub-PRs)

Stream transactions are multi-step stateful: `begin` returns a transaction id, subsequent operations carry `x-arango-trx-id: <id>`, then `commit` or `abort`. Replaces the deprecated JS-based `Arango.Transaction.transaction/1`.

Spec endpoints (5):
- `GET /_api/transaction` — list running
- `POST /_api/transaction/begin` — begin
- `GET /_api/transaction/{id}` — status
- `PUT /_api/transaction/{id}` — commit
- `DELETE /_api/transaction/{id}` — abort

### Sub-PR 3.a — cross-cutting `:transaction_id` opt

**Files**
- `lib/arango/document.ex`, `lib/arango/cursor.ex`, `lib/arango/collection.ex`, `lib/arango/graph.ex`
- `lib/arango/utils.ex` (small helper)
- Tests updated alongside (smoke only here; round-trip coverage lands in 3.b)

**Endpoints needing the header** (paths declaring `x-arango-trx-id` in `parameters`, cross-referenced against the spec):
- Document: `POST/PUT/PATCH/DELETE /_api/document/{collection}`, `POST /_api/document/{collection}#multiple`, `PUT /_api/document/{collection}#get`, all `{key}` variants
- Cursor: `POST /_api/cursor`
- Collection: `GET /_api/collection/{name}/count`, `PUT /_api/collection/{name}/truncate`
- Graph: all `/_api/gharial/{graph}/{edge|vertex}/{collection}[/{key}]` verbs

**Mechanism.** Each builder accepts `transaction_id:` in opts. When present, emit `{"x-arango-trx-id", trx_id}` in the request's `headers`. Cleanest: add `Utils.transaction_header(opts) :: %{} | %{"x-arango-trx-id" => v}` and merge into the existing headers map at each call site. `Utils.opts_to_headers/2`'s atom-to-header capitalization would map `:transaction_id → "Transaction-Id"`, which is wrong — hence the dedicated helper.

**Functions changed (no new public functions, signatures only):**
- `Arango.Document.create/3`, `document/2`, `update/4`, `replace/4`, `delete/3`, plus multi-doc variants — append `:transaction_id` to permitted opts; route to headers.
- `Arango.Cursor.cursor_create/1` — accept `transaction_id` on the `Cursor` struct (new field) and emit header. `cursor_next/1` and `cursor_next_batch/2` do **not** need the header (server tracks cursor↔tx affinity).
- `Arango.Collection.count/1`, `truncate/1` — accept `transaction_id` opt.
- `Arango.Graph.*` vertex/edge mutators — accept `transaction_id` opt.

**Tests**
- One unit test per touched module asserting the header is emitted when `transaction_id` is set and omitted when not. Snoop via `debug_requests: true` and the `darango`/`don_db` debug variants in the test harness.
- Behavior round-trips land in 3.b.

### Sub-PR 3.b — `Arango.Transaction.Stream`

**Files**
- `lib/arango/transaction/stream.ex` (new — nested under `Arango.Transaction.*` to coexist with deprecated `Arango.Transaction`)
- `test/arango/transaction/stream_test.exs` (new)

**Functions**
- `begin/2` — `POST /_api/transaction/begin`, body whitelist: `collections` (required, `%{read, write, exclusive}`), `waitForSync`, `allowImplicit`, `lockTimeout`, `maxTransactionSize`, `skipFastLockRound`. Returns `%{id, status: "running"}`.
- `commit/1` — `PUT /_api/transaction/{id}`. Returns `%{id, status: "committed"}`.
- `abort/1` — `DELETE /_api/transaction/{id}`. Returns `%{id, status: "aborted"}`.
- `status/1` — `GET /_api/transaction/{id}`. Returns `%{id, status: "running" | "committed" | "aborted"}`.
- `transactions/0` — `GET /_api/transaction`. Returns `transactions: [...]` (current running list).

**Decoder.** `OkDecoder` unwraps `%{"result" => %{...}}` for begin/commit/abort/status. `transactions/0` unwraps `transactions:`.

**Tests**
- `begin/2 with read collection returns a running id` — assert id is a numeric string, status running.
- `begin/2 rejects missing collections` — 400.
- `status/1 returns running for active tx, aborted after abort` — sequenced assertion.
- `commit/1 commits a write tx` — begin write tx, insert doc with `transaction_id:` (uses 3.a), commit, read outside tx, assert doc visible.
- `abort/1 rolls back a write tx` — begin, insert with `transaction_id:`, abort, read outside, assert doc absent.
- `transactions/0 lists a running tx` — begin, list, assert id present; commit, list, assert id absent.
- `Cursor with transaction_id sees uncommitted writes` — begin write tx, insert doc with `transaction_id:`, AQL query with same `transaction_id:`, assert doc returned; same AQL outside tx returns empty until commit.

---

## 4. Arango.Job (`lib/arango/job.ex`)

Async job results — the client side of fire-and-forget requests made with `x-arango-async: store`. Only 2 paths in OpenAPI but the `{job-id}` slot is overloaded: status strings (`pending`, `done`) list jobs in that state; an actual id returns/fetches results.

Spec endpoints (2 paths, 4 ops):
- `GET /_api/job/{job-id}` — list by status (`{job-id}` = `pending` or `done`) **OR** get status of a specific job
- `PUT /_api/job/{job-id}` — fetch results (one-shot; server consumes the result)
- `DELETE /_api/job/{job-id}` — delete result(s); `{job-id}` may be `all`, `expired`, or a specific id
- `PUT /_api/job/{job-id}/cancel` — cancel a running job

### Files
- `lib/arango/job.ex` (new — Phase 3 deleted the old stub; this is fresh)
- `test/arango/job_test.exs` (new)

### Functions
- `pending/0` — `GET /_api/job/pending`. List of pending job ids.
- `done/0` — `GET /_api/job/done`. List of completed job ids.
- `status/1` — `GET /_api/job/{id}`. 200 (done), 204 (pending), or 404.
- `result/1` — `PUT /_api/job/{id}`. Fetches and **consumes** result; subsequent reads 404.
- `cancel/1` — `PUT /_api/job/{id}/cancel`.
- `delete/1` — `DELETE /_api/job/{id}`. Accepts literal `"all"` (purge), `"expired"` (purge expired), or a specific id.

Tests need the server to actually defer something. Use a long-running AQL query (`FOR i IN 1..1000000 RETURN i`) submitted with `x-arango-async: store`. Phase 6 will add `async:` as a first-class request opt; for Phase 5 the tests set the header manually via `headers:` on a request struct.

### Tests
- `pending/0 returns ids after async submit` — assert list non-empty.
- `status/1 returns 204 for pending, 200 for done` — assert via response status (harness may need a `:raw` decoder branch; flag in unresolved).
- `result/1 consumes a done job` — submit, poll done, fetch, assert second fetch 404.
- `cancel/1 cancels a pending job` — status moves to done with cancellation marker.
- `delete/1 with "all" purges results` — subsequent `done/0` empty.

---

## 5. Arango.Auth (`lib/arango/auth.ex`)

JWT session token issuance. `POST /_open/auth` is unauthenticated (the `/_open/*` family bypasses normal auth) and returns `{jwt: "..."}`. The Request layer already supports `use_auth: :bearer` (see `Arango.Request.auth_headers/1`), so this PR is just the call.

Spec endpoint (1):
- `POST /_open/auth` — body `%{username, password}`; returns `%{jwt}`.

### Files
- `lib/arango/auth.ex` (new)
- `test/arango/auth_test.exs` (new)

### Functions
- `login/2` — `POST /_open/auth`, body `%{username, password}`. Path uses raw `/_open/auth` (leading-slash passes through verbatim per `request.ex:135`); set `system_only: false` and override `path: "/_open/auth"`. Returns `{:ok, %{"jwt" => "..."}}`.
- `login/1` — convenience: `login(password)` for password-only (per spec, `username` is optional when `password` is itself an access token from the Token module).

Auto-refresh on 401 is **Phase 6**. This PR ships the explicit call only — users hold the token themselves and pass it via `password: jwt, use_auth: :bearer` in endpoint config.

### Tests
- `login/2 returns a JWT for valid credentials` — assert string starts with `eyJ` (JWS prefix).
- `login/2 with bad password returns 401` — error tuple.
- Integration: login, then use jwt to call `Arango.Database.databases/0` via `use_auth: :bearer` — assert ok.

Note: the access-token variant (`login/1 with an access token returns JWT`) lives in the **Token PR**, not here — adding it to the Auth PR would either force a skip or require Token to land first. Keep Auth runnable standalone.

---

## 6. Arango.Token (`lib/arango/token.ex`)

Personal access tokens — per-user, scoped like full user creds, intended for non-interactive workflows. New in 3.12.

Spec endpoints (3, all system-only):
- `GET /_api/token/{user}` — list tokens
- `POST /_api/token/{user}` — create (body `%{name, valid_until}`)
- `DELETE /_api/token/{user}/{token-id}` — delete

### Files
- `lib/arango/token.ex` (new)
- `test/arango/token_test.exs` (new)

### Functions
- `tokens/1` — `GET /_api/token/{user}`. System-only (no `/_db/` prefix; same `system_only: true` flag as `Arango.User`). Returns token metadata only (no plaintext — that's create-time only).
- `create/2` — `POST /_api/token/{user}`, body `%{name, valid_until}` (both required; `valid_until` is Unix seconds integer). Response includes the one-time `token` plus `id`, `fingerprint`, `created_at`, `active`. Caller stores the token securely.
- `delete/2` — `DELETE /_api/token/{user}/{token-id}`. `{}` on success.

### Tests
- `create/2 returns a plaintext token once` — assert `token` non-nil; store for later.
- `tokens/1 lists tokens after create` — assert fingerprint matches the created token's prefix.
- `delete/2 removes a token` — subsequent `tokens/1` does not list it.
- `create/2 with past valid_until returns inactive token` — assert `active: false`.
- Integration: use plaintext token from `create/2` as `password` with `use_auth: :bearer`, hit `databases/0`, assert ok.

---

## 7. Arango.Import (`lib/arango/import.ex`)

Bulk document load. Unlike everything else in the driver, the request body is **not** JSON-encoded — it's either NDJSON (one object per line) or a JSON array, sent as `Content-Type: text/plain` per the spec. Driver must bypass `Jason.encode!` for this path.

Spec endpoint (1):
- `POST /_api/import?collection=...&type=...&...` — bulk import; body is raw text

### Files
- `lib/arango/import.ex` (new)
- `test/arango/import_test.exs` (new)

### Functions
- `documents/3` — `POST /_api/import?collection={coll}&type=documents`, body NDJSON. Accept `[map]`; serialize locally as `Enum.map_join(docs, "\n", &Jason.encode!/1)`; set `encode_body: false`. Opts whitelist (query params, per spec): `waitForSync`, `onDuplicate` (`error` | `update` | `replace` | `ignore`), `overwrite`, `complete`, `details`, `fromPrefix`, `toPrefix`, `overwriteCollectionPrefix`. Returns `%{created, errors, empty, updated, ignored, details?}`.
- `array/3` — `POST /_api/import?collection={coll}` (no `type` → JSON-array mode). Accept `[map]`, serialize once with `Jason.encode!`, send `encode_body: false`. Same opts as `documents/3`.
- `tabular/3` — `POST /_api/import?collection={coll}&type=auto` with NDJSON-of-arrays (first line is header). Opts add `ignoreMissing`. Skip in initial PR if scope creep — add a `# TODO Phase 5b` note.

**Content-type override.** The driver pins `content-type: application/json` globally in `Arango.Request.ApiConn` (`request.ex:25`). Import needs `text/plain; charset=utf-8`. Mechanism: pass `headers: %{"content-type" => "text/plain; charset=utf-8"}` on the request struct; `request.ex:91-94` merges op headers over middleware headers via `Map.merge`. Verify Tesla's actual behavior in a small spike inside this PR (last-write-wins on duplicate headers should hold — confirm with `debug_requests: true`).

### Tests
- `documents/3 imports NDJSON into a collection` — 3 docs, assert `created: 3`.
- `documents/3 with onDuplicate update merges existing` — pre-insert `{_key: "a", v: 1}`, import `{_key: "a", v: 2}` with `onDuplicate: "update"`, assert `updated: 1` and re-read shows v: 2.
- `documents/3 with complete: true aborts on first error` — import with a unique-violation; assert whole import fails.
- `array/3 imports a JSON array` — same shape, different body format.
- `documents/3 with details: true reports per-error info` — force a duplicate, assert `details` non-empty.

---

## Module Map (Phase 5 final state)

After Phase 5, `lib/arango/` adds: `view.ex`, `analyzer.ex`, `transaction/stream.ex`, `job.ex`, `auth.ex`, `token.ex`, `import.ex`. `transaction.ex` (JS, `@deprecated`) stays untouched.

Coverage: ~150 endpoints of ~155 in-demand v0 endpoints (~97%). Remaining ~80 endpoints are foxx (deprecated), cluster admin, replication, backup/license (enterprise) — deferred to Phase 7 per `plans/08-api-coverage.md`.

---

## Cross-cutting changes (flag in PR bodies)

- **3.a (Stream Tx plumbing).** Adds `:transaction_id` opt to Document/Cursor/Collection/Graph. Strictly additive; existing callers unchanged. Pure opt-in.
- **Import content-type override.** First module to override the global `content-type` header. If Tesla middleware doesn't allow per-request override, fall back to dropping middleware-level content-type and setting it per-call (touches every module). Spike inside the Import PR before relying on the simpler path.
- **Auth path prefix.** `/_open/auth` is neither `/_db/.../_api/` nor `/_api/`. The leading-slash rule in `Arango.Request.path_for_operation/1` (`request.ex:135`) already handles this; no plumbing change.
- **Job async submit.** Job module ships with a `# TODO Phase 6` note in moduledoc — `x-arango-async` first-class opt is Phase 6 QoL.

---

## Decisions

All twelve open questions resolved during plan review. Recording them here so the sub-PRs land without re-litigating.

- **Stream Tx ergonomics**: opt-on-builder this phase; the higher-level wrapper (`Arango.in_transaction(opts, fn -> ... end)`, Ecto-style with process-dict-tracked trx id) lands in **Phase 6**. The wrapper builds on the opt — not parallel work. Cross-driver reference: Ecto uses process-dict; python-arango uses a stateful `TransactionDatabase` wrapper; go-driver v2 uses per-call `.WithTransaction(tx)`.
- **Stream Tx PR split**: two PRs. 3.a = `:transaction_id` opt + `x-arango-trx-id` header threaded through every existing builder (Document/Cursor/Collection/Graph). 3.b = new `Arango.Transaction.Stream` module (`begin`/`commit`/`abort`/`status`/`transactions`).
- **Stream Tx naming**: nested `Arango.Transaction.Stream`. The existing JS `Arango.Transaction.transaction/1` is `@deprecated` and going away in v1; stream is its successor.
- **View module shape**: single `Arango.View` module with `create_arangosearch/2` + `create_search_alias/2`. The shared half (`views/0`, `view/1`, `properties/1`, `drop/1`) is genuinely shared. Matches python-arango's choice (single `views.py` with `ArangoSearch` + `SearchAlias` sharing a base).
- **View rename cluster handling**: accept either `{:ok, _}` OR `{:error, %{"code" => 501}}` in the test — both are valid outcomes, the wrapper is correct either way. No `:skip` (banned by #18).
- **Analyzer `type`**: pass-through string. Spec just says `"type": "string"` with no enum; server validates. ArangoDB ships 1–3 new analyzer types per minor release (~12 cumulative since 3.7), so an atom enum is recurring maintenance for marginal user benefit.
- **Auth `login/2`**: returns the JWT as a plain value. No in-process cache, no auto-flip of the Request layer's bearer mode. Both deferred to Phase 6 (managed-auth construct).
- **Token `valid_until`**: integer pass-through (Unix seconds, matches the server wire format). Users call `DateTime.from_unix!/1` if they want. python-arango has no token module yet, so no precedent — server-shape wins.
- **Import format API**: separate functions (`Arango.Import.documents/2` for NDJSON, `Arango.Import.array/2` for JSON array). Body shape + serialization differ enough that one polymorphic function would obscure more than it'd share. Mirrors python-arango's split.
- **Import content-type override**: spike inside the Import PR — confirm `Tesla.Middleware.Headers` allows per-call override of the globally-pinned `application/json`; if not, lift the header out of `Arango.Request.ApiConn` middleware. Either path is local to that PR.
- **Job polling**: punt the `wait_for_job/1` helper to Phase 6 (alongside the QoL retry mechanism — same backoff/timeout design). Phase 5 tests poll inline with a 5s budget.
- **View `arangosearch` vs `search-alias` domain context**: arangosearch view is server-managed (links + analyzer pipeline; server builds indexes); search-alias view is a thin facade over manually-built inverted indexes (from `Index.create_inverted/3` in Phase 4). Different ownership models, shared query surface — hence one module with two creates.
