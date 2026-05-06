---
phase: "38"
plan_id: "038-01"
status: complete
created: "2026-05-06T20:35:00+09:00"
---

# Plan 038-01 Summary

## What Changed

- Added migration `20260506190000_migrate_font_size_baseline_for_existing_users.rb`:
  - adds `preferences.font_size_notice_pending`
  - migrates legacy `font_size` values (`nil`/`medium`) to `small`
  - marks affected users with one-time pending notice.
- Added `Preference.migrate_legacy_font_sizes!` for deterministic/idempotent migration updates.
- Added `ApplicationController#render_font_size_migration_notice` to show and clear one-time notice.
- Added locale strings for migration notice in JA/EN.
- Added model/controller tests for migration behavior and one-time notice flow.
