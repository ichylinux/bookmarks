---
phase: 08-drawer-js-interaction
plan: "01"
subsystem: ui
tags:
  - rails
  - jquery
  - drawer
  - system-test
requires: []
provides:
  - Modern-theme drawer open/close via menu.js (hamburger, overlay, Esc, nav links)
  - Headless Chrome system tests for drawer + legacy email dropdown
affects:
  - Phase 9 (full-page styles)
tech-stack:
  added: []
  patterns:
    - "Namespaced document keydown (keydown.phase8Drawer) for Esc handling"
    - "Overlay close tested via direct element click when Selenium hit-testing is blocked by stacked drawer"
key-files:
  created:
    - test/system/modern_drawer_interaction_test.rb
  modified:
    - app/assets/javascripts/menu.js
    - test/application_system_test_case.rb
    - test/test_helper.rb
key-decisions:
  - "Overlay system test uses execute_script click so the overlay handler runs even when the drawer panel intercepts center-screen pointers."
  - "test_helper adjusts PATH + prepends Browser to avoid stale chromedriver 145 on PATH with Chrome 147."
patterns-established: []
requirements-completed:
  - NAV-02
  - NAV-03
duration: 45min
completed: 2026-04-29
---

# Phase 8: Drawer JS Interaction — Plan 08-01 Summary

**Drawer behaviour is fully wired in `menu.js` for `body.modern`, with system tests proving coexistence with the legacy email dropdown.**

## Performance

- **Tasks:** 3 (menu.js, Devise on system case, system tests)
- **Files modified:** 4 paths (including new system test file)

## Accomplishments

- Hamburger, overlay, Escape, and in-drawer navigation links all toggle or clear `drawer-open` as specified; hamburger uses `stopPropagation`.
- `ApplicationSystemTestCase` includes Devise helpers for `sign_in` in system tests.
- CI-friendly Selenium setup: PATH tweak + `Browser#resolve_driver_path` prepend so incompatible `/usr/local/bin/chromedriver` does not shadow Selenium Manager.

## Task commits

_Single push may squash; intended atomic messages:_

1. **Task 1** — `feat(8-01): drawer toggles in menu.js`
2. **Task 2–3** — `test(8-01): Devise system helpers, Selenium chromedriver fix, modern drawer system tests`

## Verification

- `yarn run lint` — passed (after `yarn install` for local `eslint`)
- `bin/rails test` — passed (82 runs)

## Self-Check: PASSED
