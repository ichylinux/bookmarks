---
phase: 76-portal-lazy-js-coordinator
plan: "01"
subsystem: javascript-coordinator
tags:
  - sprockets
  - javascript
  - coordinator
  - mobile
  - lazy-loading
dependency_graph:
  requires: []
  provides:
    - window.portalLazy.register(columnIndex, loadFn)
    - window.portalLazy.loadColumn(index)
  affects:
    - app/assets/javascripts/portal_mobile_tabs.js (Phase 77 will call loadColumn here)
    - gadget partials (Phase 77 will call register here)
tech_stack:
  added: []
  patterns:
    - window.name = window.name || {} namespace (from todos.js)
    - IIFE parse-time initialization (no $(document).ready wrapper)
    - isMobileViewport() via window.matchMedia (from portal_mobile_tabs.js)
    - NaN-and-negative guard on parseInt (from portal_mobile_tabs.js)
    - synchronous mark-before-fire (IMPL-04)
key_files:
  created:
    - app/assets/javascripts/portal_lazy.js
  modified: []
decisions:
  - IIFE at parse time (not in $(document).ready) so window.portalLazy exists before any gadget partial ready-handler fires
  - loadedColumns[index] = true set before the fns loop (IMPL-04 synchronous mark-before-fire contract)
  - initialColumnIndex kept internal — not exposed on window.portalLazy (CONTEXT.md locked decision)
  - isMobileViewport helper duplicated verbatim from portal_mobile_tabs.js (no module system; must match 767px exactly)
metrics:
  duration: "~3 minutes (Task 1: file creation; Task 2: tri-suite verification)"
  completed: "2026-05-17T07:15:02Z"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
requirements:
  - LAZY-01
  - LAZY-02
  - LAZY-03
  - LAZY-04
  - DESKTP-01
  - DESKTP-02
  - IMPL-01
---

# Phase 76 Plan 01: portal_lazy.js Coordinator Module Summary

**One-liner:** Parse-time `window.portalLazy` coordinator with `register`/`loadColumn` API — desktop pass-through, mobile queue-and-drain, synchronous mark-before-fire, zero visible behavior change.

## What Was Built

Created one new file: `app/assets/javascripts/portal_lazy.js` (41 lines).

The file exposes `window.portalLazy` with two public methods via a top-level IIFE that executes at Sprockets bundle parse time, before any `$(document).ready` callback fires:

- `portalLazy.register(columnIndex, loadFn)` — on desktop calls `loadFn()` immediately (pass-through); on mobile enqueues `loadFn` by `columnIndex` and auto-drains the initial column's queue
- `portalLazy.loadColumn(index)` — marks column loaded synchronously before invoking queued functions; no-op for already-loaded columns

Internal state (`queues`, `loadedColumns`, `initialColumnIndex`, `isMobileViewport`) is closed over inside the IIFE and not exposed on `window.portalLazy`.

The initial column index is read at parse time from `document.documentElement.style.getPropertyValue('--portal-initial-active-index')` — written by the prehydration inline script in `_dashboard.html.erb` — with NaN-and-negative fallback to 0.

## Requirements Addressed

| ID | Description | Status |
|----|-------------|--------|
| LAZY-01 | On mobile, only initially active column gadgets load on page load | Addressed — register() for initial column drains immediately; others queue |
| LAZY-02 | Tab switch to new column loads gadgets on first visit | Addressed — loadColumn(index) drains queue; Phase 77 wires activateColumn() |
| LAZY-03 | Revisiting already-loaded column is no-op | Addressed — loadedColumns[index] early return |
| LAZY-04 | Load state resets on page reload | Addressed — loadedColumns is in-memory JS object |
| DESKTP-01 | Desktop behavior unchanged | Addressed — register() calls loadFn() immediately on desktop |
| DESKTP-02 | Works across all themes and column counts | Addressed — coordinator is theme-agnostic; uses only matchMedia and CSS custom property |
| IMPL-01 | window.portalLazy coordinator module exposed | Addressed — this is the entire scope of Phase 76 |

## Tri-Suite Results

| Suite | Command | Result |
|-------|---------|--------|
| Lint | `yarn run lint` | Green (0 warnings, 0 errors) |
| Minitest | `bin/rails test` | 397 runs, 0 failures, 0 errors, 0 skips |
| Cucumber | `bundle exec rake dad:test` | 25 scenarios, 0 failed (re-run required — see note) |

**Cucumber re-run note:** First run: 1 failed (`features/04.ノート.feature:17` — scenario-order-dependent DB state leak, pre-existing flake per CLAUDE.md). Second run: 25 passed, 0 failed. The failure is consistent with known flakiness (preference state leaking between scenarios); it is not attributable to this phase's change (zero Ruby code changed, zero existing JS modified).

**Browser console smoke check:** Not performed in automated context. The API surface (`window.portalLazy.register` as `function`, `window.portalLazy.loadColumn` as `function`) is verifiable by inspecting the file structure — both are assigned inside the IIFE on `portalLazy` before the IIFE closes, and the namespace (`window.portalLazy = window.portalLazy || {}`) is at the top level outside any `$(document).ready` wrapper.

## Files Created / Modified

| File | Action | Lines |
|------|--------|-------|
| `app/assets/javascripts/portal_lazy.js` | Created | 41 |

No other file was modified. No gadget partial (`_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb`) was touched. No `portal_mobile_tabs.js` modification. No `_dashboard.html.erb` modification. No `application.js` modification (file is picked up automatically via `require_tree .`).

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: Create portal_lazy.js | 5510030 | feat(76-01): create portal_lazy.js coordinator module |
| Task 2: Tri-suite verification | (verification only, no file changes) | — |

## Hand-off Note for Phase 77

Phase 77 will wire gadget partials into the coordinator. Targets:

- `app/views/welcome/_feed.html.erb` — wrap `$.get(feed_path(gadget))` call in `portalLazy.register(columnIndex, function() { ... })`
- `app/views/welcome/_mastodon_account.html.erb` — same pattern
- `app/views/welcome/_x_account.html.erb` — same pattern
- `app/views/welcome/_calendar_gadget.html.erb` — same pattern
- `app/assets/javascripts/portal_mobile_tabs.js` — add `window.portalLazy.loadColumn(index)` call inside `activateColumn()`

**NOT a Phase 77 target:** `app/views/welcome/_todo_gadget.html.erb` — `todos.init()` is DOM-event binding only (no AJAX fetch on initialization); wrapping it in `register` would be incorrect. See RESEARCH.md Pitfall 5.

**Column index availability:** Gadget partials currently receive only a `gadget:` local from `render g.class.name.underscore, gadget: g` in `_portal_column_section.html.erb`. Phase 77 must add a `column_index:` local to that render call, or derive the index from `id="column_<%= i %>"` on the column container DOM element.

## Known Stubs

None — this plan creates a coordinator module with no placeholder data or hardcoded stub values.

## Threat Flags

No new security-relevant surface beyond what is documented in the plan's threat model. No new network endpoints, no auth paths, no file access patterns, no schema changes introduced.

## Self-Check

- [x] `app/assets/javascripts/portal_lazy.js` exists (verified: `test -f` passes)
- [x] All grep assertions pass (namespace, register, loadColumn, matchMedia, getPropertyValue, NaN guard, no-var, no jQuery wrapper)
- [x] mark-before-fire ordering verified (`loadedColumns[index] = true` before `const fns` — regex PASS)
- [x] No forbidden exposures on window.portalLazy (no initialColumnIndex, queues, loadedColumns, isMobileViewport)
- [x] Commit 5510030 exists in git log
- [x] Lint: green
- [x] Minitest: 397 runs, 0 failures
- [x] Cucumber: 25 scenarios, 0 failed (second run authoritative per flake policy)

## Self-Check: PASSED
