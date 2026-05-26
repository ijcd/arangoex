# Phase 1a: Test Harness & Test Generation Strategy

Status: done — 226 pass / 0 fail / 4 skip against ArangoDB 3.12 (commit `5d7cfcc`).

## Current State

Test harness runs green against ArangoDB 3.12 via Docker.

```
docker compose up -d
ARANGO_HOST=localhost ARANGO_USER=root ARANGO_PASSWORD=test mix test
```

The 4 skips are tests for endpoints removed in 3.12 (`/_admin/execute`, `/_admin/sleep`, `/_admin/test`, `long_echo` timing) — they're documented with `@tag :skip` and a comment naming the removal.

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
