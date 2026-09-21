---
quick_id: 260609-pnm
status: complete
date: "2026-06-09"
commit: 4d87b5e
---

# Quick Task 260609-pnm: Refresh landing page — Summary

## Completed

- Changelog entries prepended for 2026-06-09 landing refresh, TODO highlight, and bookmark gadget partial reload (ja/en)
- `landing.values.organize.body` updated to mention task highlighting (ja/en)
- `root_path_test` asserts newest changelog headline on Japanese locale

## Verification

- `yarn run lint` ✓
- `bin/rails test` (root_path + application_helper) 25/25 ✓
- `bundle exec rake dad:test` 38/38 ✓

## Commits

- `4d87b5e` — Refresh landing page changelog and value copy for June 2026 updates
