# Phase 5: Add New API Modules

Status: planned

## Goal

Add API modules for features introduced since ArangoDB 3.1. Prioritized by relevance to ArangoDB's AI/search direction.

## New Modules

### Arango.View (high priority)
ArangoSearch views — full-text/relevance search engine.

- `views/0` — list all views
- `create/1` — create arangosearch or search-alias view
- `drop/1` — delete view
- `view/1` — get view info
- `properties/1` — read view properties
- `set_properties/1` — update view properties (PUT for arangosearch, PATCH for search-alias)

Reference: python-arango `arangosearch.py`

### Arango.Analyzer (high priority)
Text processing pipelines for ArangoSearch.

- `analyzers/0` — list analyzers
- `create/1` — create analyzer
- `drop/1` — delete analyzer
- `analyzer/1` — get analyzer definition

Reference: python-arango `analyzer.py`

### Arango.Job (medium priority)
Async job management — was stubbed, still valid API.

- `job/1` — get job status
- `result/1` — fetch job result
- `cancel/1` — cancel job
- `delete/1` — delete job result
- `jobs/1` — list jobs by status

Reference: python-arango `async.py`

## Verification

Each module gets a test file testing against live ArangoDB 3.12.
