# Arango Driver Modernization — Overview

Target: ArangoDB 3.12+, modern Elixir, HTTP+JSON only.

## Phases

| # | Plan | Status |
|---|------|--------|
| 1 | [Deps modernization](./01-deps-modernization.md) | planned |
| 2 | [Extract macros](./02-extract-macros.md) | planned |
| 3 | [Remove dead modules](./03-remove-dead-modules.md) | planned |
| 4 | [Update existing modules to 3.12](./04-update-existing.md) | planned |
| 5 | [Add Views, Analyzers, Job](./05-new-apis.md) | planned |
| 6 | [Quality of life (request!, stream!, JWT)](./06-quality-of-life.md) | planned |
| 7 | [Enterprise APIs](./07-enterprise.md) | later |

## Decisions

- Package name: `arango` (already owned on hex)
- Keep ExConstructor
- Tesla + Finch for HTTP pooling (not db_connection)
- 3.12+ only
- No Ecto adapter (poor model fit)
- HTTP+JSON only (VelocyStream dead, VelocyPack deprecated)
- Reference drivers: python-arango (API design), go-driver v2 (test patterns)
