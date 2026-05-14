---
phase: 067-data-model-layer
plan: "01"
subsystem: data-model
tags: [migration, model, validation, portal, preference, tdd]
dependency_graph:
  requires: []
  provides: [portal_column_count-column, PORTAL_COLUMN_COUNTS-constant, parameterized-portal-columns]
  affects: [app/models/preference.rb, app/models/portal.rb, db/schema.rb]
tech_stack:
  added: []
  patterns: [inclusion-validation, delegation, Array.new-dynamic-init, downgrade-guard]
key_files:
  created:
    - db/migrate/20260515000000_add_portal_column_count_to_preferences.rb
    - test/models/portal_test.rb
  modified:
    - app/models/preference.rb
    - app/models/portal.rb
    - db/schema.rb
decisions:
  - "Use ActiveRecord::Migration[8.1] per most recent migration convention (20260514200001)"
  - "No allow_nil on portal_column_count validation — DB column is NOT NULL with default 3"
  - "Portal#portal_column_count delegates directly to user.preference.portal_column_count without nil guard — matches existing use_todo?/use_calendar? delegation pattern"
  - "Downgrade guard (next if pl.column_no >= count) redistributes out-of-range gadgets via fallback loop rather than raising IndexError or appending nil"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-15"
  tasks_completed: 3
  files_modified: 5
  commits: 5
requirements_fulfilled:
  - COL-01
  - COL-04
  - COL-06
---

# Phase 067 Plan 01: Data + Model Layer Summary

**One-liner:** Added `preferences.portal_column_count` integer column (default 3), `PORTAL_COLUMN_COUNTS = [3, 4]` constant with inclusion validation, and parameterized `Portal#portal_columns` to use stored preference count with downgrade guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Migration — add portal_column_count to preferences | 8aa9a36 | db/migrate/20260515000000_add_portal_column_count_to_preferences.rb, db/schema.rb |
| 2 (RED) | Preference model — failing test | 4028970 | test/models/preference_test.rb |
| 2 (GREEN) | Preference model — PORTAL_COLUMN_COUNTS constant and validation | b178389 | app/models/preference.rb |
| 3 (RED) | Portal model — failing tests | 9fb1e7f | test/models/portal_test.rb |
| 3 (GREEN) | Portal model — parameterize portal_columns | fcce08c | app/models/portal.rb, test/models/portal_test.rb |

## What Was Built

### Migration (Task 1)
`db/migrate/20260515000000_add_portal_column_count_to_preferences.rb` adds `portal_column_count integer DEFAULT 3 NOT NULL` to the `preferences` table. All existing rows receive the default value of 3 — no data migration required.

### Preference Model (Task 2)
Added after the `FONT_SIZES` block:
- `PORTAL_COLUMN_COUNTS = [3, 4].freeze` constant
- `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` (no `allow_nil` — column has DB default and NOT NULL constraint)

### Portal Model (Task 3)
Replaced three hardcoded references to `3`:
- `portal_column_count` now returns `user.preference.portal_column_count` (was `portal_columns.size`)
- `@portal_columns` initialized with `Array.new(count) { [] }` (was `[[], [], []]`)
- Downgrade guard added: `next if pl.column_no >= count` before processing each `PortalLayout`
- Fallback uses `i % count` (was `i % 3`)

## Verification

```
bin/rails test  →  372 runs, 1787 assertions, 0 failures, 0 errors, 0 skips

grep -c "portal_columns.size" app/models/portal.rb  →  0
grep -c "i % 3" app/models/portal.rb               →  0
grep -c "\[\[\], \[\], \[\]\]" app/models/portal.rb →  0
```

Migration status: `up 20260515000000 Add portal column count to preferences`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test association cache caused false failures in portal_test.rb**
- **Found during:** Task 3 GREEN phase
- **Issue:** Test used `portal` fixture helper which holds a cached `user` association; `update_columns` on `user.preference` updated DB but left the in-memory `user.preference` object stale. `portal.portal_column_count` then read the stale cached value (3) instead of 4.
- **Fix:** Changed test to use `Portal.find(portal.id)` to get a fresh Portal instance with fresh association chain for each assertion requiring a different column count.
- **Files modified:** test/models/portal_test.rb
- **Commit:** fcce08c (incorporated into GREEN commit)

## TDD Gate Compliance

Both TDD tasks followed the RED/GREEN/REFACTOR cycle:

| Gate | Task 2 | Task 3 |
|------|--------|--------|
| RED commit | 4028970 | 9fb1e7f |
| GREEN commit | b178389 | fcce08c |
| REFACTOR | Not needed | Not needed |

## Known Stubs

None — all data flows are wired to DB-backed values.

## Threat Flags

None — no new network endpoints or auth paths introduced. The threat mitigations defined in the plan's STRIDE register are implemented:
- T-067-01 (Tampering): `validates :portal_column_count, inclusion: { in: PORTAL_COLUMN_COUNTS }` active
- T-067-02 (DoS): `next if pl.column_no >= count` guard active

## Self-Check: PASSED

| Item | Status |
|------|--------|
| db/migrate/20260515000000_add_portal_column_count_to_preferences.rb | FOUND |
| app/models/preference.rb | FOUND |
| app/models/portal.rb | FOUND |
| test/models/portal_test.rb | FOUND |
| Commit 8aa9a36 (migration) | FOUND |
| Commit 4028970 (RED preference) | FOUND |
| Commit b178389 (GREEN preference) | FOUND |
| Commit 9fb1e7f (RED portal) | FOUND |
| Commit fcce08c (GREEN portal) | FOUND |
