---
phase: 06-html-structure
plan: 01
subsystem: ui
tags: [rails, erb, layout, navigation, drawer, hamburger, tdd]

requires:
  - phase: 05-modern-theme-css
    provides: "body.modern CSS class that Phase 7 CSS will target"

provides:
  - "button.hamburger-btn as last child of .head-box (unconditional, empty body)"
  - "div.drawer with 7 nav links inside nav, as direct child of body after .wrapper"
  - "div.drawer-overlay as direct child of body, sibling of .drawer"
  - "Both drawer+overlay guarded by user_signed_in? — guests see neither"
  - "Integration tests locking the DOM structure (7 assertions, RED→GREEN TDD cycle)"

affects: [07-modern-theme-css-drawer, 08-drawer-js]

tech-stack:
  added: []
  patterns: ["drawer/overlay rendered unconditionally per auth guard, outside .wrapper for no clipping", "nav links duplicated inline in drawer (no shared partial per D-06)"]

key-files:
  created:
    - test/controllers/layout_structure_test.rb
  modified:
    - app/views/layouts/application.html.erb

key-decisions:
  - "Hamburger button is UNCONDITIONAL — not gated on modern theme (D-02/RESEARCH §A1); Phase 7 CSS controls visibility"
  - "Drawer + overlay placed AFTER </div>.wrapper, BEFORE </body> — direct body children prevent clipping"
  - "No _drawer.html.erb partial — links duplicated inline per D-06 decision"
  - "method: 'delete' on logout link verbatim from _menu.html.erb — required for Devise UJS"
  - "_menu.html.erb left byte-identical (zero diff)"

patterns-established:
  - "Drawer selectors for Phase 7: body > .modern .drawer, body > .modern .drawer-overlay"
  - "JS toggle class target for Phase 8: body.drawer-open (Phase 8's responsibility to add)"

requirements-completed: [NAV-01, NAV-02]

duration: 15min
completed: 2026-04-29
---

# Phase 06: HTML Structure Summary

**Hamburger button + drawer/overlay HTML scaffolding added to application.html.erb via TDD — stable DOM surface for Phase 7 CSS and Phase 8 JS**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-29
- **Completed:** 2026-04-29
- **Tasks:** 2 (RED test + GREEN implementation)
- **Files modified:** 2 (1 created, 1 edited)

## Accomplishments
- Created `test/controllers/layout_structure_test.rb` with 7 Japanese-named integration tests (RED→GREEN TDD)
- Added `<button class="hamburger-btn" aria-label="メニュー"></button>` as last child of `.head-box` (unconditional)
- Added `<div class="drawer"><nav>` with 7 nav links + `<div class="drawer-overlay">` as direct `<body>` children after `.wrapper`, inside `user_signed_in?` guard
- Verified `_menu.html.erb` untouched (zero diff)
- Full minitest suite: 81 runs, 0 failures (pre-existing Cucumber failures unchanged)

## Task Commits

1. **Task 1: Failing structure tests (RED)** - `53ef05b` (test(06): add failing structure tests)
2. **Task 2: Layout edit — hamburger + drawer (GREEN)** - `75d8359` (feat(06): add hamburger button + drawer + overlay HTML structure)

## Files Created/Modified
- `test/controllers/layout_structure_test.rb` — 7 integration tests asserting hamburger, drawer, overlay, 7 nav links, body-direct placement
- `app/views/layouts/application.html.erb` — +15 lines: hamburger button in `.head-box`, drawer+overlay after `.wrapper`

## Decisions Made
- Hamburger rendered unconditionally (not inside `if user_signed_in?`) per D-02 — Phase 7 CSS uses `body.modern` to control visibility
- Drawer and overlay share one `<% if user_signed_in? %>` block — guests never see nav structure
- No `_drawer.html.erb` partial created — links duplicated inline per locked decision D-06

## Deviations from Plan
None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- **Phase 7 (CSS):** Stable selectors ready — `button.hamburger-btn`, `div.drawer`, `div.drawer-overlay`, `body > .modern` scope
- **Phase 8 (JS):** DOM surface ready — hamburger button target + drawer + overlay elements in place; Phase 8 adds `body.drawer-open` toggle
- No blockers.

---
## Self-Check: PASSED

- [x] All tasks executed
- [x] Each task committed individually
- [x] SUMMARY.md created
- [x] Tests: 7 runs, 33 assertions, 0 failures, 0 errors (GREEN)
- [x] Full suite: 81 runs, 364 assertions, 0 failures, 0 errors
- [x] `_menu.html.erb` byte-identical to pre-Phase-6 state

---
*Phase: 06-html-structure*
*Completed: 2026-04-29*
