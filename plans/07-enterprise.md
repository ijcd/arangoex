# Phase 7: Enterprise APIs

Status: later

## Goal

Add support for ArangoDB Enterprise Edition features, when/if needed.

## Candidate Modules

### Arango.HotBackup
- `create/1` — create backup
- `restore/1` — restore from backup
- `list/0` — list backups
- `delete/1` — delete backup

### Arango.License
- `license/0` — get license info
- `set_license/1` — set license key

### Enhanced Replication (new API)
- Modern replication API (replaced old replication module removed in Phase 3)

### Encryption at Rest
- Key rotation endpoints

## Prerequisites

- Enterprise Edition Docker image for testing
- License key for CI

## Decision

Revisit after Phases 1-6 are complete and there's user demand.
