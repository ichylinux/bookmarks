# Phase 114: Discussion Log

**Mode:** --auto (fully autonomous, no user interaction)
**Date:** 2026-05-24

## Gray Areas Covered

### Schema
- Q: "Rails standard timestamps or custom fields?"
  → Selected: Rails standard `created_at`/`updated_at` (recommended default)

### Upsert Strategy
- Q: "find_or_create_by + update! vs raw upsert?"
  → Selected: `find_or_create_by!` then `update!` (readable Rails idiom, recommended)

### from_omniauth Integration
- Q: "Where to inject identity upsert in from_omniauth?"
  → Selected: Before implicit return in each branch, guarded by `user.persisted?` (recommended)

### Backfill Migration
- Q: "Same migration as schema or separate?"
  → Selected: Separate data migration (auditable independently, recommended)

## Deferred Ideas

- None

## Auto-mode Log

```
[auto] Selected all gray areas: Schema, Upsert Strategy, from_omniauth Integration, Backfill Migration
[auto] Schema — Q: "Timestamps style?" → Selected: "Rails standard created_at/updated_at" (recommended default)
[auto] Upsert — Q: "Strategy?" → Selected: "find_or_create_by! + update!" (recommended)
[auto] Integration — Q: "Injection point?" → Selected: "Before return, guarded by persisted?" (recommended)
[auto] Backfill — Q: "Same or separate migration?" → Selected: "Separate data migration" (recommended)
```
