---
phase: quick-260729-qew
plan: 01
subsystem: ui
tags: [i18n, locale, landing-page, changelog]

requires: []
provides:
  - 6 new guest-facing changelog entries in config/locales/en.yml (landing.changelog.entries)
  - 6 mirrored changelog entries in config/locales/ja.yml, key-for-key and date/tag-in-sync with en.yml
  - root_path_test re-pointed to assert the current top-of-cap headline
affects: [landing-page, welcome_controller]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - config/locales/en.yml
    - config/locales/ja.yml
    - test/controllers/welcome_controller/root_path_test.rb

key-decisions:
  - "Content-only locale edit — landing.changelog.entries only, no changes to _landing.html.erb, landing.css.scss, or application_helper.rb"
  - "Re-pointed the newest-headline test assertion to the new top entry (feed gadget settings dialog) since the 10-entry cap in changelog_entries pushed the old 2026-06-09 headline out of the rendered set"

patterns-established: []

requirements-completed: [LANDING-CHANGELOG-REFRESH]

coverage:
  - id: D1
    description: "Guest landing changelog (en.yml) announces the 6 shipped features/fixes since 2026-06-25, newest entry 2026-07-29"
    requirement: "LANDING-CHANGELOG-REFRESH"
    verification:
      - kind: unit
        ref: "bin/rails runner presence/shape check for the 6 new dates in landing.changelog.entries (:en)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guest landing changelog (ja.yml) mirrors en.yml key-for-key and date/tag-for-date/tag"
    requirement: "LANDING-CHANGELOG-REFRESH"
    verification:
      - kind: unit
        ref: "bin/rails runner positional (date,tag) equality check between :en and :ja locale entries"
        status: pass
    human_judgment: false
  - id: D3
    description: "root_path_test asserts a headline that is actually inside the 10-entry render cap"
    requirement: "LANDING-CHANGELOG-REFRESH"
    verification:
      - kind: integration
        ref: "test/controllers/welcome_controller/root_path_test.rb#test_日本語ロケールで最新changelog見出しが表示される"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-29
status: complete
---

# Quick Task 260729-qew: Refresh Landing Page Changelog Summary

**Added 6 mirrored en/ja changelog entries (feed gadget settings dialog, sticky Simple-theme header, mobile bookmark/task header-tap add, two header-interaction fixes) and re-pointed the newest-headline test to the new top entry.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-29T10:05:00Z (approx, session start)
- **Completed:** 2026-07-29
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- `config/locales/en.yml` gained 6 new `landing.changelog.entries` items (2026-07-29 newest → 2026-06-27), each with `date`/`headline`/`tag`/`description`
- `config/locales/ja.yml` mirrors the same 6 entries with identical `date`/`tag` pairs in the same positions and natural Japanese copy
- `test/controllers/welcome_controller/root_path_test.rb`'s `test_日本語ロケールで最新changelog見出しが表示される` now asserts the feed-gadget-settings headline, which is the entry actually rendered under `changelog_entries`' 10-item cap after the addition

## Task Commits

Each task was committed atomically:

1. **Task 1: Add 6 changelog entries to en.yml** - `33455b0` (feat)
2. **Task 2: Mirror the 6 entries into ja.yml** - `f7fccb8` (feat)
3. **Task 3: Re-point the newest-headline assertion and run the gates** - `f136f88` (test)

_No plan-metadata commit — docs artifacts (SUMMARY.md, STATE.md) are committed separately by the orchestrator._

## Files Created/Modified
- `config/locales/en.yml` - 6 new English changelog entries prepended to `landing.changelog.entries`
- `config/locales/ja.yml` - 6 new Japanese changelog entries prepended to `landing.changelog.entries`, key-for-key with en.yml
- `test/controllers/welcome_controller/root_path_test.rb` - Updated asserted headline string to the current top entry

## Decisions Made
- Kept the edit strictly to `landing.changelog.entries` in both locale files — no markup, CSS, or helper changes, per plan scope
- Re-pointed rather than expanded the helper's cap: the plan explicitly disallowed modifying `application_helper.rb`, so the test was updated to match the new top-10 window instead

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- No blockers. This was a self-contained content refresh; no follow-up work implied.

## Verification Results

- `bin/rails test test/controllers/welcome_controller/root_path_test.rb test/helpers/application_helper_test.rb test/i18n/changelog_i18n_test.rb` → 39 runs, 366 assertions, 0 failures, 0 errors
- `yarn run lint` → clean (no output, exit 0)
- `bin/rails test` (full suite) → 701 runs, 3142 assertions, 0 failures, 0 errors, 0 skips
- `dad:test` (Cucumber) — not run, per plan (no feature references landing changelog copy)

## Self-Check: PASSED

- FOUND: config/locales/en.yml
- FOUND: config/locales/ja.yml
- FOUND: test/controllers/welcome_controller/root_path_test.rb
- FOUND commit 33455b0
- FOUND commit f7fccb8
- FOUND commit f136f88

---
*Phase: quick-260729-qew*
*Completed: 2026-07-29*
