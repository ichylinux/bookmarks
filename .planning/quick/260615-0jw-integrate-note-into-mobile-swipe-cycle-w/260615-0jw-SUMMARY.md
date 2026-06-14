---
phase: quick-260615-0jw
plan: "01"
subsystem: frontend-js
tags: [mobile, swipe, note-pane, portal, circular-navigation]
dependency_graph:
  requires: []
  provides: [window.notePane API, circular-swipe-cycle]
  affects: [notes_tabs.js, portal_mobile_tabs.js, _dashboard.html.erb]
tech_stack:
  added: []
  patterns: [modular-wrap-around-arithmetic, shared-reveal-API, localStorage-sentinel]
key_files:
  created: []
  modified:
    - app/assets/javascripts/notes_tabs.js
    - app/assets/javascripts/portal_mobile_tabs.js
    - app/views/welcome/_dashboard.html.erb
    - test/assets/portal_mobile_tabs_js_contract_test.rb
    - features/03.モダンテーマ.feature
decisions:
  - "Note sentinel stored as string 'note' in localStorage portalMobileActiveColumn; parseInt('note',10) is NaN so the existing NaN guard in the prehydrate script no-ops it correctly with no code change."
  - "cycleLength replaces colCount in the guard: `if (cycleLength < 2) return;` allows 1-column + note to be swipeable."
  - "Circular modular arithmetic ((currentIndex + direction) % cycleLength + cycleLength) % cycleLength; the old if (newIndex !== currentIndex) guard removed as redundant when cycleLength >= 2."
  - "hiddenClass derived from theme at init time (simple-tab-panel--hidden vs welcome-tab-panel--hidden); $homePanel likewise resolved by theme — no cross-theme hardcoding."
  - "Contract test and Cucumber scenario updated to reflect new circular behavior (old clamping assertions replaced)."
metrics:
  duration: "~45 minutes"
  completed_date: "2026-06-15"
  tasks_completed: 2
  files_changed: 5
---

# Phase quick-260615-0jw Plan 01: Integrate Note into Mobile Swipe Cycle — Summary

One-liner: Theme-agnostic `window.notePane` API plus modular wrap-around arithmetic in the mobile swipe engine, inserting the note pane as the final circular slot when `use_note` is enabled.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extract theme-agnostic window.notePane reveal module | c3af148 | notes_tabs.js, _dashboard.html.erb |
| 2 | Make mobile swipe cycle circular with note pane | 2ac2779 | portal_mobile_tabs.js, _dashboard.html.erb |
| Fix | Update tests for circular behavior | 7747f8b | portal_mobile_tabs_js_contract_test.rb, 03.モダンテーマ.feature |

## What Was Built

### Task 1: window.notePane module (notes_tabs.js)

Removed the `body.simple` early-return that locked note-reveal logic to the simple theme. The module now:

- Defines `window.notePane` unconditionally (so `portal_mobile_tabs.js` can call `notePane.available()` even when the note panel is absent).
- Early-returns only when `#notes-tab-panel` is absent (use_note disabled).
- Derives `hiddenClass` and `$homePanel` from the theme at init time: `simple-tab-panel--hidden` / `#simple-home-panel` for the simple theme; `welcome-tab-panel--hidden` / `#welcome-home-panel` for all others.
- `show()`: hides home panel, shows note panel, syncs `.head-note-btn--active` and dormant `.simple-tab--active` buttons, and lazily loads `/notes/gadget` once (shared `notesLoaded` flag, reset on failure so a later attempt can retry).
- `hide()`: reverses the above.
- `initFromQuery()` reads `?tab=notes` for ALL themes (not just simple) and calls `notePane.show()`.
- Dormant `button.simple-tab[data-simple-tab]` click bindings now route through `notePane.show()/hide()`.

Removed the redundant welcome-branch `<script>` block in `_dashboard.html.erb` that directly `$.get`'d the gadget when `notes_active` — this would have double-loaded the gadget against the shared `notesLoaded` flag.

### Task 2: Circular swipe cycle (portal_mobile_tabs.js)

Replaced `Math.min(Math.max(...))` clamping with modular arithmetic:

```javascript
const noteInCycle = typeof window.notePane !== 'undefined' && window.notePane.available();
const cycleLength = colCount + (noteInCycle ? 1 : 0);
if (cycleLength < 2) return;
// ...
const newIndex = ((currentIndex + direction) % cycleLength + cycleLength) % cycleLength;
```

Cycle model:
- Indices 0 through colCount-1 are portal columns.
- Index colCount is the note sentinel (only when `noteInCycle` is true).
- Swipe left (direction=+1): advances forward through the cycle.
- Swipe right (direction=-1): retreats, wrapping from 0 to the last slot.

Activation dispatch:
- `newIndex === colCount` (note sentinel): calls `notePane.show()`, deactivates all column tabs, persists `'note'` to localStorage.
- Otherwise (column): calls `notePane.hide()` then `activateColumn($portal, $tabs, newIndex)`.

Column tab-click handler also calls `notePane.hide()` before `activateColumn` so clicking a number tab always dismisses the note pane.

Restore on mobile page load handles `raw === 'note'`: calls `notePane.show()` and deactivates column tabs, then returns before the int-parse path.

### Prehydrate comment (_dashboard.html.erb)

Added a comment to the prehydrate IIFE noting that `'note'` is a valid sentinel value and that `Number.parseInt('note', 10)` is NaN — the existing NaN guard already handles it with no code change needed.

## Note-Sentinel Persistence Approach

`localStorage.portalMobileActiveColumn` stores either:
- A numeric string (`"0"`, `"1"`, ...) for column indices
- The literal string `"note"` for the note pane

The prehydrate IIFE (run before JS to set `--portal-initial-active-index`) calls `Number.parseInt(raw, 10)`. When `raw === 'note'`, this is NaN; the guard `Number.isNaN(restored) || restored < 0` no-ops, so no bogus column index is forced into the CSS variable. A brief flash of the home panel before JS shows the note pane on reload is acceptable (noted in the plan).

The portal_mobile_tabs.js restore block checks `raw === 'note' && noteInCycle` explicitly BEFORE the int-parse path, to avoid falling back to column 0 when the user reloads with the note pane active.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Contract test assertions encoded old clamping behavior**
- **Found during:** Task 2 green-bar gate (bin/rails test)
- **Issue:** `portal_mobile_tabs_js_contract_test.rb` contained 3 assertions tied to the old implementation: `function($portal` (no space), `if (colCount < 2) return;`, and an `if (newIndex !== currentIndex)` guard that the circular model no longer uses.
- **Fix:** Updated assertions to match the new style (`function ($portal`), new guard (`cycleLength < 2`), and replaced the obsolete newIndex guard check with a simple `activateColumn($portal, $tabs, newIndex)` pattern match.
- **Files modified:** `test/assets/portal_mobile_tabs_js_contract_test.rb`
- **Commit:** 7747f8b

**2. [Rule 1 - Bug] Cucumber scenario tested old clamping boundary behavior**
- **Found during:** Task 2 green-bar gate (bundle exec rake dad:test)
- **Issue:** Scenario `先頭列で右スワイプしても列が変わらない` (line 59) expected column 1 to remain active after right-swipe from col 0. With circular wrap, right-swipe from col 0 with 3 columns and use_note=OFF wraps to col 2 (last column).
- **Fix:** Renamed scenario to `先頭列で右スワイプすると最終列へ循環する`; changed assertion to `3列目のポータル列がアクティブです。`. Determinism confirmed: the `Before` hook calls `Capybara.reset_sessions!` and resets `@_preferences_reset_for` before every scenario, so the modern theme background `sign_in` always triggers `reset_preferences_via_browser!` which unchecks `use_note`.
- **Files modified:** `features/03.モダンテーマ.feature`
- **Commit:** 7747f8b

## Green-Bar Gate Results

| Suite | Command | Result |
|-------|---------|--------|
| Lint | `yarn run lint` | green |
| Minitest | `bin/rails test` | 644/644 green |
| Cucumber | `bundle exec rake dad:test` | 38/38 green |

Note: MySQL connection required `MYSQL_HOST=172.17.0.2` (Docker bridge IP) because port forwarding via 127.0.0.1:3306 returned "Lost connection to MySQL server at reading initial communication packet" from the host environment.

## Pending Human Verification (Checkpoint Task 3)

The following must be verified manually on a mobile viewport (browser devtools at <=767px or a real phone), with `use_note` ENABLED and a multi-column portal, for at least the **simple theme** AND one **drawer theme** (welcome or modern):

1. **Forward swipe (left):** Panes advance col-1 -> col-2 -> ... -> col-N -> note -> col-1 (wraps). Note appears WITHOUT full page reload; gadget content loads.
2. **Reverse swipe (right) from col-1:** Wraps backward to note pane, then col-N, etc.
3. **Swipe note -> column:** Portal/home panel reappears; correct column + its number tab are active.
4. **Gadget loads only once:** No duplicate content or repeated network calls to `/notes/gadget` when swiping back to it.
5. **Reload on note pane:** Note pane is restored. Reload on column: that column is restored.
6. **Disable use_note in /preferences, reload:** Columns wrap circularly (col-N -> col-1 and col-1 -> col-N) with NO note pane in the cycle.
7. **Vertical scroll within a column:** Not hijacked. Gadget drag-to-reorder does NOT trigger a swipe.

## Known Stubs

None. All data flows are wired; no placeholder text introduced.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes introduced. The `/notes/gadget` lazy-load endpoint is existing and authenticated; only the client-side trigger mechanism (swipe vs reload) changed.

## Self-Check: PASSED

All files exist. All commits found in git log. `window.notePane` defined in notes_tabs.js. `% cycleLength` modular arithmetic present in portal_mobile_tabs.js. `Math.min/Max` appears only in a comment (no functional clamping). Duplicate `gadget_notes_path` loader removed from _dashboard.html.erb.
