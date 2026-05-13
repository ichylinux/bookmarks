---
phase: 046-changelog-data-layer
plan: "01"
subsystem: i18n
tags: [i18n, yaml, helpers, tdd, changelog]

requires:
  - phase: 040-landing-structure
    provides: landing locale block structure in ja.yml and en.yml

provides:
  - landing.changelog.heading key in ja and en locales
  - landing.changelog.tags.{ux,fix,performance,new} keys in both locales
  - landing.changelog.entries array (3 curated entries) in both locales
  - ApplicationHelper#changelog_entries method (sorted desc, capped at 10)

affects:
  - 047-changelog-section-view

tech-stack:
  added: []
  patterns:
    - "Changelog data defined in locale YAML; helper reads via I18n.t with default: []"
    - "ISO 8601 date strings (YYYY-MM-DD) used as sort keys for changelog entries"

key-files:
  created:
    - test/helpers/application_helper_test.rb
    - test/i18n/changelog_i18n_test.rb
  modified:
    - config/locales/ja.yml
    - config/locales/en.yml
    - app/helpers/application_helper.rb

key-decisions:
  - "changelog_entries uses I18n.t with default: [] so it returns [] gracefully when locale key is absent"
  - "Date sort uses plain String#<=> on YYYY-MM-DD strings — ISO 8601 lexicographic order is correct"
  - "Cap of 10 entries is enforced at the helper level, not in YAML"

patterns-established:
  - "Changelog data is locale-YAML-backed; no DB table or model needed"
  - "Helper sorts and caps; view just iterates the returned array"

requirements-completed:
  - CLOG-01
  - CLOG-02
  - CLOG-03
  - CLOG-04

duration: 20min
completed: "2026-05-10"
---

# Phase 46 Plan 01: Changelog Data Layer Summary

**Bilingual YAML changelog data (3 entries, 4 tag keys, heading) added to ja/en locales with ApplicationHelper#changelog_entries sorting entries by date descending and capping at 10**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-10T03:05:00Z
- **Completed:** 2026-05-10T03:25:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `landing.changelog.*` keys (heading, tags, entries) to both ja.yml and en.yml with identical structure
- Implemented `ApplicationHelper#changelog_entries` via TDD (RED/GREEN): sorts by ISO 8601 date descending, caps at 10
- Added `ChangelogI18nTest` asserting heading, all 4 tag keys, and each entry field resolve in both locales

## Task Commits

1. **Task 1: Add changelog locale keys to ja.yml and en.yml** - `4b08250` (feat)
2. **Task 2: Implement ApplicationHelper#changelog_entries** - `81d0423` (feat, includes TDD test file)
3. **Task 3: Add changelog i18n key-resolution test** - `b0df418` (test)

## Files Created/Modified

- `config/locales/ja.yml` - Added `landing.changelog` block: heading (新着情報), 4 tag keys, 3 entries
- `config/locales/en.yml` - Added `landing.changelog` block: heading (What's New), 4 tag keys, 3 entries
- `app/helpers/application_helper.rb` - Added `changelog_entries` method
- `test/helpers/application_helper_test.rb` - 4 behavioral tests for `changelog_entries` (sort, cap, count, keys)
- `test/i18n/changelog_i18n_test.rb` - 14 key-resolution assertions across ja and en

## Decisions Made

- `I18n.t('landing.changelog.entries', default: [])` used in helper so it degrades gracefully if key missing
- ISO 8601 YYYY-MM-DD strings sort correctly with plain `String#<=>` — no date parsing needed
- Cap of 10 at helper layer keeps YAML clean; future editors just add entries without worrying about display count

## Deviations from Plan

None - plan executed exactly as written. The plan's note checker recommendation to use `default: []` in the helper was already in the plan spec and was followed.

## Issues Encountered

Cucumber suite (`bundle exec rake dad:test`) exhibited pre-existing order-dependent flakiness documented in CLAUDE.md. Two runs were conducted; different scenarios failed in each run (モダンテーマ:86 on run 1; ノート:17 and タスク:11 on run 2). None of the failing scenarios are related to changelog data. Per CLAUDE.md flakiness policy, this is classified as pre-existing and not attributable to this phase.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All Phase 47 (Changelog Section View) dependencies are satisfied: `changelog_entries` helper is implemented and tested; `landing.changelog.*` locale keys are present in both locales
- Phase 47 can begin immediately

---
*Phase: 046-changelog-data-layer*
*Completed: 2026-05-10*

## Self-Check: PASSED

- `config/locales/ja.yml` contains `landing.changelog` block: FOUND
- `config/locales/en.yml` contains `landing.changelog` block: FOUND
- `app/helpers/application_helper.rb` contains `changelog_entries`: FOUND
- `test/helpers/application_helper_test.rb` exists: FOUND
- `test/i18n/changelog_i18n_test.rb` exists: FOUND
- Commit `4b08250` (Task 1): FOUND
- Commit `81d0423` (Task 2): FOUND
- Commit `b0df418` (Task 3): FOUND
