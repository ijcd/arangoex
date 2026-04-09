# Phase 3: Remove Dead Modules

Status: planned

## Goal

Remove modules targeting ArangoDB endpoints that are deprecated or removed in 3.12.

## Removals

| Module | File | Test File | Reason |
|--------|------|-----------|--------|
| Simple | `lib/arango/simple.ex` | `test/arango/simple_test.exs` | `/_api/simple/*` deprecated 3.4, use AQL |
| GraphTraversal | `lib/arango/graph_traversal.ex` | `test/arango/graph_traversal_test.exs` | `/_api/traversal` removed 3.12 |
| Bulk | `lib/arango/bulk.ex` | `test/arango/bulk_test.exs` | `/_api/batch` removed 3.12.3 (was stubbed anyway) |
| Replication | `lib/arango/replication.ex` | `test/arango/replication_test.exs` | API completely reworked (was stubbed anyway) |
| Cluster | `lib/arango/cluster.ex` | `test/arango/cluster_test.exs` | API completely reworked (was stubbed anyway) |

## Also

- Remove `Simple` from Config.Defaults endpoint list
- Remove `GraphTraversal` from Config.Defaults endpoint list
- Remove `Bulk`, `Replication`, `Cluster` from Config.Defaults
- Remove references in test_helper.exs if any
- Keep test files in git history for reference when writing new tests

## Verification

`mix compile --warnings-as-errors` — no dangling references.
