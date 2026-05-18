---
phase: 84-data-layer-controller
plan: "01"
subsystem: data-layer
tags: [migration, model, visited-links, upsert, mysql]
dependency_graph:
  requires: []
  provides: [visited_links-table, VisitedLink-model, VisitedLink.record!, VisitedLink.urls_for, VisitedLink.normalize_url]
  affects: [db/schema.rb]
tech_stack:
  added: []
  patterns: [mysql-prefix-index, activerecord-upsert-mysql, ruby-set-aggregation]
key_files:
  created:
    - db/migrate/20260518200000_create_visited_links.rb
    - app/models/visited_link.rb
    - test/models/visited_link_test.rb
    - test/fixtures/visited_links.yml
  modified:
    - db/schema.rb
decisions:
  - "unique_by: not supported by Mysql2Adapter — MySQL upsert uses the unique index automatically without unique_by; removed the option"
  - "Prefix length reduced from url: 768 to url: 767 because MySQL 8.4 rejects exactly 3072-byte keys (768*4=3072 = InnoDB limit); 767*4=3068 bytes succeeds"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-18"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
---

# Phase 84 Plan 01: Data Layer — visited_links table and VisitedLink model

**One-liner:** MySQL `visited_links` migration (utf8mb4 prefix index url(767)) and `VisitedLink` model with atomic upsert idempotency, fragment-stripping normalization, and Set-returning `urls_for`.

## What Was Built

### Task 1: Migration

`db/migrate/20260518200000_create_visited_links.rb` creates `visited_links` with:
- `user_id integer NOT NULL`
- `url varchar(2083) NOT NULL`
- `visited_at datetime NOT NULL`
- `timestamps`
- Unique prefix index on `(user_id, url(767))` named `index_visited_links_on_user_id_and_url`

### Task 2: Model + Tests

`app/models/visited_link.rb`:
- `belongs_to :user`, `validates :url, presence: true`
- `normalize_url(url)`: `url.to_s.sub(/#.*$/, '')` — strips fragment, nil-safe
- `record!(user, url)`: normalizes, blank-guards, then `upsert({user_id:, url:, visited_at:})` — atomic insert-or-update via MySQL's `ON DUPLICATE KEY UPDATE` semantics
- `urls_for(user)`: `where(user_id: user.id).pluck(:url).to_set` — returns Ruby Set

12 unit tests in `test/models/visited_link_test.rb` covering all behaviors. Full suite: 429 runs, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MySQL 8.4 rejects prefix length url: 768**
- **Found during:** Task 1 (migration run)
- **Issue:** `768 * 4 bytes/char = 3072 bytes` equals the InnoDB max key length exactly; MySQL 8.4 requires strictly less than 3072 bytes
- **Fix:** Reduced prefix from `url: 768` to `url: 767` (767*4=3068 bytes)
- **Files modified:** `db/migrate/20260518200000_create_visited_links.rb`
- **Commit:** 331c9d4

**2. [Rule 1 - Bug] unique_by: not supported by Mysql2Adapter**
- **Found during:** Task 2 (model tests)
- **Issue:** `ActiveRecord::ConnectionAdapters::Mysql2Adapter does not support :unique_by` — this is a PostgreSQL-specific option. MySQL's `upsert` maps to `INSERT ... ON DUPLICATE KEY UPDATE` and automatically uses the unique index without specifying it
- **Fix:** Removed `unique_by:` argument from `upsert` call; idempotency verified working (2 upserts → 1 row)
- **Files modified:** `app/models/visited_link.rb`
- **Commit:** 5059e4f

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 — Migration | 331c9d4 | feat(84-01): create visited_links table with prefix index |
| 2 — Model + Tests | 5059e4f | feat(84-01): add VisitedLink model with record!, urls_for, normalize_url; unit tests |

## Verification

- `bin/rails db:migrate:status` shows `up 20260518200000 Create visited links`
- `db/schema.rb` contains `create_table "visited_links"` with url limit: 2083, `index_visited_links_on_user_id_and_url` unique prefix index url: 767
- `bin/rails test test/models/visited_link_test.rb` — 12 runs, 0 failures, 0 errors
- `bin/rails test` — 429 runs, 0 failures, 0 errors

## Known Stubs

None — all behaviors are fully implemented and tested.

## Threat Flags

None — no new network endpoints or trust boundaries beyond what the plan's threat model covers.

## Self-Check: PASSED

- [x] `db/migrate/20260518200000_create_visited_links.rb` — FOUND
- [x] `app/models/visited_link.rb` — FOUND
- [x] `test/models/visited_link_test.rb` — FOUND
- [x] `test/fixtures/visited_links.yml` — FOUND
- [x] Commit 331c9d4 — FOUND
- [x] Commit 5059e4f — FOUND
