---
phase: 104-schema-model-refresh-guard
plan: "02"
subsystem: model
tags: [x_accounts, model, upsert, refresh_guard, minitest]
dependency_graph:
  requires: [manually_added column on x_accounts (104-01)]
  provides: [upsert_manual! class method, manually_added? refresh guard]
  affects: [app/models/x_account.rb, test/models/x_account_test.rb]
tech_stack:
  added: []
  patterns: [first_or_initialize upsert, soft-delete guard, TDD]
key_files:
  created: []
  modified:
    - app/models/x_account.rb
    - test/models/x_account_test.rb
decisions:
  - "upsert_manual! uses first_or_initialize on (user_id, x_user_id); always sets manually_added: true, deleted: false"
  - "refresh soft-delete loop gains next if acc.manually_added? immediately after next if seen[acc.x_user_id]"
  - "assign_attributes inside refresh upsert loop does NOT include manually_added: to preserve flag on overlap rows"
metrics:
  duration: "~10 minutes"
  completed: "2026-05-22"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 104 Plan 02: upsert_manual! and Refresh Guard Summary

**One-liner:** Added `XAccount.upsert_manual!` (idempotent manual-add with `manually_added: true`) and `next if acc.manually_added?` guard in the refresh soft-delete loop, with four new Minitest cases covering both behaviors.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add upsert_manual! and refresh guard to XAccount model | bfacd43 | app/models/x_account.rb |
| 2 | Write Minitest coverage for upsert_manual! and refresh guard | a98b6f0 | test/models/x_account_test.rb |

## Verification Results

- `bin/rails test test/models/x_account_test.rb` — 10 runs, 22 assertions, 0 failures, 0 errors
- `grep -n "next if acc.manually_added?" app/models/x_account.rb` — line 53, exactly one match inside soft-delete loop
- `grep -n "def self.upsert_manual!" app/models/x_account.rb` — line 62, one match
- `grep "manually_added:" app/models/x_account.rb | grep -v "upsert_manual"` — only occurrence is inside upsert_manual! body (no stray key in refresh assign_attributes)
- `yarn run lint` — green

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundary changes. T-104-02 (x_user_id cast to_s) and T-104-03 (manually_added flag set only by upsert_manual!) are satisfied as designed.

## Self-Check: PASSED

- app/models/x_account.rb — FOUND
- test/models/x_account_test.rb — FOUND
- Commit bfacd43 (feat: upsert_manual! and refresh guard) — FOUND
- Commit a98b6f0 (test: Minitest coverage) — FOUND
