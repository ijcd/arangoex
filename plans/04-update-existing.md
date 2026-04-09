# Phase 4: Update Existing Modules to 3.12 API

Status: planned

## Goal

Update remaining modules to match ArangoDB 3.12 REST API. Reference: python-arango source.

## Module Updates

### Collection — minor
- Add `computedValues`, `schema` params to create
- Add `cacheEnabled` property support

### Document — minor
- Add `refillIndexCaches` param
- Add `versionAttribute` support
- Verify multi-doc ops match current API

### Database — minor
- Add `sharding`, `replicationFactor`, `writeConcern` options

### AQL — minor
- Add query results cache endpoints
- Verify slow query / kill query still match

### Index — significant
- Add `create_inverted/3` (ArangoSearch)
- Add `create_ttl/3` (time-to-live)
- Add `create_zkd/3` (multi-dimensional)
- Remove `create_hash/3`, `create_skiplist/3` (merged into `persistent` in 3.12)

### Transaction — rework
- Add stream transactions: `begin/1`, `commit/1`, `abort/1`, `status/1`
- Keep JS transactions but mark `@deprecated`

### Cursor — update
- Change next-batch from `PUT` to `POST` (3.12 change)
- Add `allowRetry` option
- Add stream mode option

### User — minor
- Add collection-level permissions (`grant/3`, `revoke/3` with collection param)

### Administration — update
- Add `engine/0`, `metrics/0`
- Remove `execute/2` (JS execution removed in 3.12)

### Wal — verify
- Verify endpoints still work with RocksDB
- May need adjustments

### Task — verify
- Should work as-is, verify against 3.12

## Verification

Run full test suite against ArangoDB 3.12 Docker container.
