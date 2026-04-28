---
status: passed
phase: 8-drawer-js-interaction
verified: 2026-04-29
---

# Phase 8 Verification — Drawer JS Interaction

## Must-haves (from 08-01-PLAN / ROADMAP)

| Criterion | Evidence |
|-----------|----------|
| Hamburger toggles `body.drawer-open`; `stopPropagation` on hamburger | `menu.js` |
| Overlay click closes drawer | Same; system test uses `document.querySelector('.drawer-overlay').click()` because panel stacks above overlay at many pointer coordinates |
| Escape closes when open | `keydown.phase8Drawer` + `Escape` |
| Drawer nav `a` closes without `preventDefault` | Delegated click on `.drawer nav` |
| Non-`modern` early return | Guard unchanged at top of IIFE |
| Legacy email menu + `$('html').click` still works | `modern_drawer_interaction_test.rb` (modern theme; outside click on `#header .head-box .header-icon`) |
| `yarn run lint` | ESLint clean on `app/assets/javascripts/**/*.js` |
| `bin/rails test` | 82 runs, 0 failures |

## Automated

- `test/system/modern_drawer_interaction_test.rb` — `driven_by :headless_chrome`
- `test/test_helper.rb` — strips `/usr/local/bin` from `PATH` when it contains a `chromedriver` binary so Selenium Manager can supply a driver matching installed Chrome; prepends `Browser` to clear stale `Chrome::Service.driver_path` between registrations

## Human verification

Optional: manual smoke on drawer + email dropdown in browser (CI covers scripted paths).

## Gaps

None for phase goal.

## human_verification

- (optional) Confirm hamburger / overlay / Esc / nav / email menu in real Chrome
