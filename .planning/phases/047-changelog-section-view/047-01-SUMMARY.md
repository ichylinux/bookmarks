---
phase: 047-changelog-section-view
plan: "01"
subsystem: landing
tags: [view, css, test, landing, changelog]
dependency_graph:
  requires: []
  provides: [landing-changelog-section]
  affects: [app/views/landing/show.html.erb, app/assets/stylesheets/landing.css.scss, test/controllers/landing_controller_test.rb]
tech_stack:
  added: []
  patterns: [ERB i18n t() full-key notation, SCSS flat class rules, Minitest assert_select]
key_files:
  created: []
  modified:
    - app/views/landing/show.html.erb
    - app/assets/stylesheets/landing.css.scss
    - test/controllers/landing_controller_test.rb
decisions:
  - "Used assert_select with regex matcher for English heading test instead of assert_includes, because ERB HTML-escapes the apostrophe in \"What's New\" to &#39; in the response body"
metrics:
  duration: ~8 minutes
  completed: 2026-05-10
---

# Phase 047 Plan 01: Changelog Section View Summary

Changelog section added to /landing below the value grid, rendering dated and tagged cards from the existing `changelog_entries` helper and locale YAML data, with full Minitest coverage for VIEW-01 through VIEW-04.

## Commits

| Task | Commit | Message | Files |
|------|--------|---------|-------|
| 1 | c7f19ae | feat(047): add changelog section to landing view | app/views/landing/show.html.erb |
| 2 | bb56640 | feat(047): add changelog CSS rules to landing stylesheet | app/assets/stylesheets/landing.css.scss |
| 3 | fe12dbb | test(047): add landing controller tests for changelog section (VIEW-01-VIEW-04) | test/controllers/landing_controller_test.rb |

## Verification Results

- `yarn run lint`: green (0 errors)
- `bin/rails test`: 263 runs, 1389 assertions, 0 failures, 0 errors, 0 skips
- `bundle exec rake dad:test`: 22 scenarios, 93 steps, all passed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed English heading test assertion**
- **Found during:** Task 3 verification
- **Issue:** `assert_includes response.body, "What's New"` failed because ERB HTML-escapes the apostrophe in the heading to `&#39;`, so the literal string `What's New` is not present in the raw response body.
- **Fix:** Replaced `assert_includes` with `assert_select '.changelog-heading', text: /What.s New/` which matches against the decoded text content of the element, bypassing the HTML-escape issue.
- **Files modified:** test/controllers/landing_controller_test.rb
- **Commit:** fe12dbb (included in Task 3 commit — fixed before final commit)

The plan's note about U+2019 (right single quotation mark) was also inaccurate — en.yml uses a standard ASCII apostrophe (U+0027). The HTML-escaping of U+0027 to `&#39;` is what caused the failure.

## Known Stubs

None — all changelog cards render real locale data via `changelog_entries` helper.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. T-047-03 (tag CSS class interpolation) is mitigated by ERB's automatic html_escape on `<%= entry[:tag] %>` in the class attribute.

## Self-Check: PASSED

- app/views/landing/show.html.erb: exists and contains `landing-changelog`
- app/assets/stylesheets/landing.css.scss: exists and contains `.changelog-tag--new`
- test/controllers/landing_controller_test.rb: exists with 10 tests, all passing
- Commits c7f19ae, bb56640, fe12dbb: all present in git log
