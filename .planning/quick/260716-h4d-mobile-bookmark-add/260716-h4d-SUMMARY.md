---
phase: 260716-h4d-mobile-bookmark-add
plan: "01"
subsystem: js, css, test
tags: [mobile, bookmark-gadget, tap-to-reveal, cucumber, quick-task]
dependency_graph:
  requires: []
  provides: [QUICK-MOB-BM-ADD-01]
  affects: [features/01.ブックマーク.feature, app/assets/javascripts/bookmark_gadget.js]
tech_stack:
  added: []
  patterns: [mobile header tap-to-reveal (mirrors todos.js/title--gadget-actions-visible), CSS specificity override, source-contract test, mobile-portal Cucumber scenario]
key_files:
  modified:
    - app/assets/javascripts/bookmark_gadget.js
    - app/assets/stylesheets/welcome.css.scss
    - features/01.ブックマーク.feature
    - features/step_definitions/bookmarks.rb
  created:
    - test/assets/bookmark_gadget_mobile_css_contract_test.rb
decisions:
  - "Reused the task gadget's exact mechanism (title--gadget-actions-visible header class + mobile CSS reveal pattern) instead of inventing a new interaction, per plan objective."
  - "Scoped bookmark mobile CSS rules via the header attribute selector .title--gadget-with-icon[data-gadget-icon=\"bookmark\"] (bookmark gadget root has no .todo-style modifier class), prefixed with .gadget to match the todo rule's specificity exactly: (0,4,0) hide / (0,5,0) reveal, both overriding the desktop :hover rule at (0,3,1)."
  - "bookmark_gadget.js defines its own local MOBILE_MQ constant (separate Sprockets file from todos.js) rather than reaching into todos.js internals."
  - "Cucumber step 'ダイアログの ブックマークを追加 ボタンをクリック...' uses wait_until (not visit '/') because the dialog submit reloads the gadget via AJAX (reloadGadget), unlike the existing desktop bookmark scenario which does a full page visit."
metrics:
  duration: "~20 min (incl. two full dad:test runs)"
  completed_date: "2026-07-16"
status: complete
---

# Quick 260716-h4d Plan 01: Mobile Bookmark Add — Header Tap-to-Reveal Parity — Summary

## One-liner

Bookmark gadget header now reveals 「追加」 on mobile tap (mirroring the task gadget's `title--gadget-actions-visible` mechanism), letting mobile users open the existing new-bookmark dialog and create a bookmark end-to-end.

## What Was Built

Previously, on a mobile viewport the bookmark gadget's 「追加」 link was permanently unreachable (`opacity: 0` + `pointer-events: none` via both the shared base rule and `@media (hover: none)`), while the task gadget already had a tap-to-reveal escape hatch. This closes that gap using the exact same mechanism, per the plan's parity objective — no new interaction was invented.

### Task 1 — JS + CSS wiring (`app/assets/javascripts/bookmark_gadget.js`, `app/assets/stylesheets/welcome.css.scss`)

- Added a local `MOBILE_MQ = window.matchMedia('(max-width: 767px)')` and a `BOOKMARK_HEADER_SELECTOR` constant inside the existing `$(document).ready` closure.
- Changed the `.bookmark-gadget-new-link` mousedown-only stopPropagation binding to `mousedown touchstart` (prevents jQuery UI sortable/touch-punch from swallowing the tap on mobile, exactly as `todos.js` does for its action links).
- Added a `mousedown touchstart` handler on the bookmark header that stops propagation unless the target is inside `.bookmark-gadget-new-link`.
- Added a `click` handler on the bookmark header that, only when `MOBILE_MQ.matches` and the target isn't inside `.bookmark-gadget-new-link`, stops propagation and toggles `title--gadget-actions-visible`.
- Added a document-level `touchstart` handler that clears `title--gadget-actions-visible` from the bookmark header when tapping outside it on mobile.
- All handlers use `$(document).on(...)` delegation, matching this file's existing style, so they survive `reloadGadget`'s DOM replacement.
- `welcome.css.scss`: added bookmark-scoped rules inside the existing `@media (max-width: 767px)` block:
  - `.gadget .title--gadget-with-icon[data-gadget-icon="bookmark"] .bookmark-gadget-new-link { opacity: 0; pointer-events: none; }` — specificity (0,4,0), matching the todo hide rule.
  - `.gadget .title--gadget-with-icon[data-gadget-icon="bookmark"].title--gadget-actions-visible .bookmark-gadget-new-link { opacity: 1; pointer-events: auto; }` — specificity (0,5,0), matching the todo reveal rule.
  - Both comfortably override the desktop `div.title:hover` rule at (0,3,1).
- `todos.js` and `.gadget.todo` rules were left untouched.

### Task 2 — Source-contract test (`test/assets/bookmark_gadget_mobile_css_contract_test.rb`)

New test file modeled on `todo_gadget_mobile_css_contract_test.rb`, asserting (via whitespace-tolerant regex against the raw source):
1. `welcome.css.scss` sets `opacity: 0` and `pointer-events: none` on `.bookmark-gadget-new-link` scoped under the bookmark header attribute selector, inside `@media (max-width: 767px)`.
2. `welcome.css.scss` reveals it (`opacity: 1`, `pointer-events: auto`) when the header carries `.title--gadget-actions-visible`.
3. `bookmark_gadget.js` binds a `click` handler on the bookmark header that toggles `title--gadget-actions-visible`.
4. `bookmark_gadget.js` stops propagation on `mousedown touchstart` for `.bookmark-gadget-new-link`.

4 tests, 14 assertions, all passing. The existing todo contract test was left unmodified.

### Task 3 — `@mobile_portal` Cucumber scenario (`features/01.ブックマーク.feature`, `features/step_definitions/bookmarks.rb`)

Added scenario 「モバイルでヘッダをタップしてブックマークを追加できる」, modeled on the task gadget's equivalent in `features/02.タスク.feature`/`todos.rb`:

- New steps: sign in + `ensure_mobile_viewport!` + `visit root_path` + defensive column-tab navigation (`navigate_to_bookmark_gadget_column!`, iterates `.portal-column-tab` buttons only if `#bookmark_gadget` isn't already visible — in practice the bookmark gadget renders in the default-active column 0 for the fixture user, so no tab click is needed at runtime, but the helper is defensive against future gadget-ordering changes).
- Tap the header (`.gadget-title-text`), assert `.title--gadget-actions-visible` appears.
- Tap the revealed `.bookmark-gadget-new-link` via `click_bookmark_gadget_new_link` (execute_script click, mirroring `click_todo_gadget_new_link`), assert `dialog#bookmark-new-dialog[open]`.
- Reused the existing 「URLを入力し、「URLから取得」ボタンでサイトのタイトルを取得します。」step unchanged (fills `bookmark[url]`, clicks the fetch button, waits for the title to populate) — it works identically inside the dialog form since only one `bookmark[url]` field exists per page.
- New step submits the dialog form and asserts the bookmark appears in `#bookmark_gadget .root-bookmarks` via `wait_until` (not `visit '/'`, since the dialog submit reloads the gadget via AJAX/`reloadGadget` rather than a full page navigation).

## Task Commits

1. **Task 1: Wire bookmark gadget header tap-to-reveal (JS + CSS parity)** — `387bfb3` (feat)
2. **Task 2: Source-contract unit test** — `11648b4` (test)
3. **Task 3: @mobile_portal Cucumber scenario + full 3-suite gate** — `0b3117f` (test)

## Files Created/Modified

- `app/assets/javascripts/bookmark_gadget.js` — header tap-to-reveal handlers (mousedown/touchstart stopPropagation, click toggle, document touchstart close)
- `app/assets/stylesheets/welcome.css.scss` — mobile reveal/hide rules scoped to the bookmark header attribute selector
- `test/assets/bookmark_gadget_mobile_css_contract_test.rb` — new source-contract test (created)
- `features/01.ブックマーク.feature` — new `@mobile_portal` scenario
- `features/step_definitions/bookmarks.rb` — new step definitions + `navigate_to_bookmark_gadget_column!` / `click_bookmark_gadget_new_link` helpers

## Decisions Made

See frontmatter `decisions`. In short: pure mechanism reuse (no new interaction), CSS specificity matched exactly to the todo precedent, local `MOBILE_MQ` kept file-scoped since `bookmark_gadget.js` is a separate Sprockets bundle from `todos.js`, and the final submit step uses AJAX-aware waiting rather than the existing desktop scenario's `visit '/'` pattern.

## Deviations from Plan

None — plan executed exactly as written. The `node_modules` directory was missing in this worktree (fresh worktree checkout); ran `yarn install` to restore it before `yarn run lint` could execute — this is standard worktree setup, not a code deviation, and no files were committed for it.

## Issues Encountered

The first `bundle exec rake dad:test` run reported 1 failed scenario: 「管理者が利用状況レポートを閲覧できる」(`features/10.X_API利用状況.feature`), failing with `Unable to find xpath "/html"` inside `preferences_reset.rb` — unrelated to this task's files (X API admin report page, no bookmark/mobile/gadget involvement). Per CLAUDE.md's flakiness re-run policy, re-ran the full suite once more: 42/42 scenarios passed, 0 failures, confirming it was pre-existing flakiness and not a regression introduced by this change.

## Verification Results

| Suite | Result |
|-------|--------|
| `yarn run lint` | green |
| `bin/rails test` | 692 runs, 3053 assertions, 0 failures, 0 errors, 0 skips |
| `bundle exec rake dad:test` (1st run) | 42 scenarios (1 failed, 41 passed) — unrelated flake, see Issues Encountered |
| `bundle exec rake dad:test` (2nd run) | 42 scenarios (42 passed), 186 steps (186 passed), 0 failed |

## Known Stubs

None.

## Threat Flags

None — CSS + client-side JS + tests only, no new network endpoints, auth paths, or data access patterns. See plan's `<threat_model>` (T-h4d-01, T-h4d-02, both `accept` disposition, no new backend surface).

## Self-Check: PASSED

- `app/assets/javascripts/bookmark_gadget.js` — FOUND (modified)
- `app/assets/stylesheets/welcome.css.scss` — FOUND (modified)
- `test/assets/bookmark_gadget_mobile_css_contract_test.rb` — FOUND (created)
- `features/01.ブックマーク.feature` — FOUND (modified)
- `features/step_definitions/bookmarks.rb` — FOUND (modified)
- commit `387bfb3` — FOUND
- commit `11648b4` — FOUND
- commit `0b3117f` — FOUND
