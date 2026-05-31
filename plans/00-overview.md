# Arango Driver Modernization — Overview

Target: ArangoDB 3.12+ (API v0), modern Elixir, HTTP+JSON only.

## Phases

| # | Plan | Status |
|---|------|--------|
| 1 | [Deps modernization](./01-deps-modernization.md) | done |
| 1a | [Test harness](./01a-test-harness.md) | done — 226 pass / 0 fail / 4 skip (3.12) |
| 3 | [Deprecate & remove](./03-remove-dead-modules.md) | done — 210 pass / 0 fail / 11 skip |
| 2 | [Extract macros](./02-extract-macros.md) | done — 14 modules on `Arango.API`, 210 pass / 0 fail / 11 skip |
| 4 | [Update existing modules to 3.12](./04-update-existing.md) | done — Index, Cursor, Administration, Document, Collection, Database, AQL, User, WAL, Task (PRs #9–#19); CI + pre-commit + dialyzer + format + credo gates wired (#15); `@tag :skip` removed (#18) |
| 5 | [Add Views, Analyzers, Stream Tx, Job, Auth, Token, Import](./05-new-apis.md) | planned |
| 6 | [Quality of life (request!, stream!, JWT)](./06-quality-of-life.md) | planned |
| — | [API coverage matrix](./08-api-coverage.md) | reference |
| — | [v1/4.0 migration plan](./09-v1-migration.md) | future |
| — | [Enterprise APIs](./07-enterprise.md) | later |

## Decisions

- Package name: `arango` (already owned on hex)
- Keep ExConstructor
- Tesla + Finch for HTTP pooling (not db_connection)
- Target ArangoDB 3.12+ at API **v0** (current default)
- No Ecto adapter (poor model fit)
- HTTP+JSON only (VelocyStream dead, VelocyPack deprecated)
- Reference drivers: python-arango (API design), go-driver v2 (test patterns)
- Deprecation policy (Phase 3): **delete** endpoints already gone in 3.12, **`@deprecated`** endpoints removed in v1/4.0

## ArangoDB API versioning context

3.12.8 introduced URL-prefixed API versioning: `/_arango/v0/...` and `/_arango/v1/...`.

- **v0** = current API, all 174 endpoints. Default if no prefix.
- **v1** = cleaned-up subset, 148 endpoints. Will be the default in **4.0**.
- v1 drops 26 legacy endpoints: Foxx (12), Tasks, AQL functions, JS transactions, collection load/unload, statistics, execute, and more.

Targeting v0 today is correct. Plan 09 covers the eventual migration to v1.
