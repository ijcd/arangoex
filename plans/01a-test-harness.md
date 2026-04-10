# Phase 1a: Test Harness & Test Generation Strategy

Status: in progress

## Current State (after Phase 1)

Test harness works against ArangoDB 3.12.9 via Docker.

```
docker compose up -d
ARANGO_HOST=localhost ARANGO_USER=root ARANGO_PASSWORD=test mix test
```

### Per-Module Results (226 tests, 94 failures, 4 skipped)

| Module | Pass | Fail | Skip | Notes |
|--------|------|------|------|-------|
| utils | 5 | 0 | 0 | All pass |
| user | 7 | 1 | 0 | Nearly there |
| cursor | 8 | 4 | 0 | Mostly pass |
| database | 5 | 2 | 0 | Faker word collision + assertion |
| index | 7 | 3 | 0 | hash/skiplist deprecated |
| administration | 8 | 7 | 1 | Response shape changes |
| aql | 10 | 9 | 3 | Response format changes |
| collection | 7 | 8 | 0 | Hardcoded system collection names |
| document | 43 | 22 | 0 | Jason.Encoder needed for structs |
| simple | 11 | 3 | 0 | Deprecated but mostly works |
| transaction | 2 | 3 | 0 | JS transactions deprecated |
| task | 1 | 4 | 0 | Response format changes |
| graph | 7 | 14 | 0 | Major changes |
| graph_edge | 0 | 1 | 0 | |
| graph_traversal | 0 | 15 | 0 | /_api/traversal removed in 3.12 |
| wal | 1 | 3 | 0 | Endpoints gone (RocksDB) |
| bulk/cluster/job/replication | 0 | 0 | 0 | Stubbed, no tests |

### Failure Categories

1. **Response shape changes** (~30%) — ArangoDB 3.12 returns different/extra fields
2. **Hardcoded assertions** (~25%) — Tests check exact values that changed
3. **Jason.Encoder missing** (~15%) — Poison encoded any struct, Jason needs @derive
4. **Deprecated/removed endpoints** (~15%) — graph_traversal, wal, hash/skiplist index
5. **Faker collisions** (~5%) — Short random words produce duplicate names
6. **Actual API changes** (~10%) — Transaction, task, graph API evolution

## Test Generation Strategy

### OpenAPI Spec
ArangoDB publishes OpenAPI 3.1 specs in their repo:
- `https://raw.githubusercontent.com/arangodb/arangodb/devel/OpenAPI/0-openapi.json` (174 paths, 1.4MB)
- `https://raw.githubusercontent.com/arangodb/arangodb/devel/OpenAPI/1-openapi.json` (additional paths)

### Approach: Spec-Validated Tests

1. **Download OpenAPI spec** — cache locally in `test/support/openapi/`
2. **Response shape validation** — use `open_api_spex` to validate that our responses match the spec schemas. Replace hardcoded field assertions with schema validation.
3. **Property tests with StreamData** — generate random valid inputs (collection names, document bodies, query params) and verify:
   - Response status codes match spec
   - Response bodies conform to spec schemas
   - CRUD invariants hold (create→read returns same data, delete→read returns 404)
4. **Endpoint coverage tracking** — diff our implemented endpoints against spec paths

### New Test Dependencies

```elixir
{:stream_data, "~> 1.1", only: :test}
{:open_api_spex, "~> 3.21", only: :test}
```

### Test Rewrite Priority

Fix existing tests first (unblock CI), then layer on property tests:

1. Fix test_helper Faker collisions (use longer random strings)
2. Add `@derive Jason.Encoder` to structs (or handle in encode_body)
3. Fix response shape assertions (loosen to check keys exist, not exact shape)
4. Remove graph_traversal + wal tests (endpoints gone)
5. Add spec validation layer
6. Add property tests for CRUD invariants
