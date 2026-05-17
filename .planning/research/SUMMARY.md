# Project Research Summary

**Project:** Bookmarks v1.24 — Mobile Column Lazy Loading
**Domain:** Client-side deferred AJAX loading within an existing Rails/jQuery portal
**Researched:** 2026-05-17
**Confidence:** HIGH

## Executive Summary

v1.24 is a targeted mobile performance improvement to the existing portal column system. Currently, every AJAX gadget (Feed, MastodonAccount, XAccount, CalendarGadget) fires its `$.get` call unconditionally on `$(document).ready`, regardless of which column is visible on mobile. This wastes bandwidth and API rate-limit budget on cellular connections. The fix: on mobile, defer non-active column gadgets until the first time a user switches to that column, then cache the loaded state for the remainder of the page session. Desktop behavior is completely unchanged.

The recommended implementation introduces one new JavaScript file (`portal_lazy.js`) that acts as a coordinator. Each AJAX gadget partial registers a loader function into this coordinator instead of firing directly in `$(document).ready`. The coordinator fires loaders immediately for the active column and queues them for inactive columns. `portal_mobile_tabs.js` drains each column's queue when `activateColumn` is called — the single convergence point that already handles tab clicks, swipe gestures, and localStorage restore. This covers all activation paths without duplication. Zero server changes, zero new routes, zero new npm dependencies.

The primary risks are timing and scope. The most dangerous pitfall is forgetting the localStorage restore path: if column 2 was active on the user's last visit and is restored on page reload, lazy loading must trigger for column 2 immediately — not wait for a tab click that never comes. All loaded-state tracking must be synchronous (mark before AJAX starts, not inside the success callback) to prevent duplicate in-flight requests from rapid swiping. A secondary concern is keeping desktop behavior fully intact — the coordinator must fire all loaders immediately when `isMobileViewport()` is false.

## Key Findings

### Recommended Stack

The entire feature is implementable with no new dependencies. jQuery 4.6.1 is already locked via `jquery-rails` and provides all required APIs (`.data()`, `$.get()`, `.find()`, `.each()`). Sprockets alphabetical file ordering means a new `portal_lazy.js` file loads before `portal_mobile_tabs.js` automatically — no explicit `//= require` changes needed.

Libraries evaluated and rejected include IntersectionObserver (wrong trigger — portal columns are hidden by CSS `translateX`, not scroll position), `lazysizes` (designed for `<img>` tags, requires npm), and pub-sub EventEmitter (unnecessary indirection for 3–4 columns). The "lazy load once on tab switch" problem is simpler than scroll-based lazy loading; five lines of jQuery is the correct solution.

**Core technologies:**
- jQuery 4.6.1 (already in project): `.data()` sentinel, `$.get()`, `$(fn)` — all stable APIs unchanged from jQuery 1.x, no breaking changes in jQuery 4 for these APIs
- Vanilla `data-*` attributes (HTML5): column index passed via `column_index: i` ERB local to each gadget partial render call
- `portal_mobile_tabs.js` (existing): `activateColumn` function as the single integration hook point
- `portal_lazy.js` (new file): `window.portalLazy` coordinator with `register` and `loadColumn` methods

### Expected Features

**Must have (table stakes — milestone is incomplete without these):**
- Active-column-only AJAX load on mobile page load — non-active column gadgets must not fire on `$(document).ready`
- Load-on-first-visit for non-active columns — first tab switch triggers deferred gadgets
- Load-once guarantee per page session — switching back to a loaded column shows cached content, no re-fetch
- Desktop behavior unchanged — all gadgets fire on `$(document).ready` at viewport >= 768px
- All AJAX gadget types covered — Feed, MastodonAccount, XAccount, CalendarGadget
- SSR gadgets (Bookmark, Todo) unaffected — no AJAX to defer; already in DOM at page load
- Works across all themes (modern, classic, simple) — shared `_portal_column_section.html.erb` partial
- Works for 3-column and 4-column layouts — coordinator is index-based, not hardcoded
- localStorage-restored non-zero column loads immediately — init path calls `activateColumn` which triggers load

**Should have (differentiators — do not block milestone on these):**
- Loading placeholder already present in each AJAX gadget — free UX indicator with no extra work

**Defer to v2+:**
- Abort in-flight requests when switching column mid-load — low value, high complexity
- Adjacent-column preload on idle (`requestIdleCallback`) — actively conflicts with bandwidth-saving goal
- Full DOM virtualization of off-screen columns — breaks CSS slide animation, unnecessary overhead

### Architecture Approach

The architecture separates concerns into three layers. First, `portal_lazy.js` runs synchronously at parse time to establish `window.portalLazy` before any `$(document).ready` fires — it reads the initial active column index from `localStorage` and knows mobile status immediately. Second, each AJAX gadget partial wraps its load call in `window.portalLazy.register(column_index, fn)` inside `$(document).ready`; the coordinator either calls `fn()` immediately (desktop or active column) or queues it. Third, `portal_mobile_tabs.js` calls `window.portalLazy.loadColumn(index)` inside `activateColumn`, draining the queue for that column once and marking it loaded.

The column index is passed to gadget partials via a new `column_index: i` ERB local in the `_portal_column_section.html.erb` render loop — a one-line change that is cleaner and more reliable than runtime DOM traversal via `document.currentScript` (which is null inside `$(document).ready` callbacks).

**Major components:**
1. `portal_lazy.js` (new) — `window.portalLazy` coordinator; synchronous init; per-column queue and loaded-set; mobile/desktop branching
2. `portal_mobile_tabs.js` (modified) — add `window.portalLazy.loadColumn(index)` call at end of `activateColumn`
3. `_portal_column_section.html.erb` (modified) — pass `column_index: i` to each gadget render call
4. AJAX gadget partials (modified, 4–5 files) — wrap `$.get` / `todos.init` in `portalLazy.register(column_index, fn)`
5. `portal_lazy_js_contract_test.rb` (new) — Minitest contract asserting module shape and key string patterns

### Critical Pitfalls

1. **`$(document).ready` fires unconditionally for all gadgets** — the inline `<script>` pattern has no mobile awareness; must intercept via the `portalLazy.register` wrapper in each partial. All AJAX partials must be changed in one cohesive commit.

2. **Race condition: localStorage restore path misses the load trigger** — the localStorage restore code already calls `activateColumn`, so wiring the lazy trigger inside `activateColumn` (not the click handler) makes the restore path automatic. Missing this causes restored non-zero columns to show "Loading…" indefinitely.

3. **Async state race on rapid swipe** — `loaded[idx] = true` must be set synchronously before any `$.get` call, not inside the success callback. A second swipe to the same column during an in-flight load must find the column already marked loaded and be a no-op.

4. **Desktop broken by mobile-only guard applied to all viewports** — the coordinator's `register` method must call `fn()` immediately when `!isMobile`. Verify desktop gadget loading with smoke test after each partial is modified.

5. **Layout save data loss** — `collect_portal_layout_params` in `_dashboard.html.erb` iterates `#column_N > div` children to collect gadget IDs for drag-drop layout save. On mobile, non-visited columns have no AJAX content yet. Verify that `$.sortable` is not initialized on mobile; add `isMobileViewport()` guard to sortable init if it is unconditional.

## Implications for Roadmap

Based on research, the dependency chain is clear: coordinator JS must exist before gadget partials can call `register`, and both must be in place before meaningful tests can be written.

### Phase A: `portal_lazy.js` Coordinator

**Rationale:** All subsequent work depends on `window.portalLazy` existing. Creating it first as a standalone file means gadget partials can be migrated in the next phase with zero visible behavior change — on desktop, `register` is a pass-through that calls `fn()` immediately.

**Delivers:** New `portal_lazy.js` with `window.portalLazy.register` and `window.portalLazy.loadColumn`; synchronous init reading mobile status and initial column index from `localStorage`; per-column queue and loaded-set; `isMobile` branch (desktop: immediate call, mobile: queue or immediate based on active index).

**Avoids:** PITFALL-3 (init timing) by reading column state synchronously at file parse time rather than inside `$(document).ready`.

**Verification gate:** `yarn run lint` + `bin/rails test` green. `bundle exec rake dad:test` green (no desktop behavior change — `register` calls `fn()` immediately on non-mobile).

### Phase B: Gadget Partial Wiring + Tab Hook

**Rationale:** With the coordinator in place, gadget partials and `portal_mobile_tabs.js` can be updated in one cohesive commit. Changing all AJAX partials together prevents a split-brain state where some gadgets are deferred and others still fire unconditionally.

**Delivers:** `_portal_column_section.html.erb` passes `column_index: i` to each render call. AJAX partials (`_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb`, `_todo_gadget.html.erb`) wrap their calls in `portalLazy.register`. `portal_mobile_tabs.js` adds `window.portalLazy.loadColumn(index)` inside `activateColumn`.

**Avoids:** PITFALL-1 (unconditional `$(document).ready`) by replacing direct calls with `register`. PITFALL-3 (restore path) by wiring into `activateColumn`, not the click handler. PITFALL-6 (async race) by marking column loaded synchronously before any `$.get` fires.

**Verification gate:** All three suites green. Manual mobile smoke via DevTools: page load shows only column-0 gadget requests; tab switch to column 1 triggers those gadgets; switching back to column 0 fires no new requests.

### Phase C: Contract Tests + Cucumber E2E

**Rationale:** Contract tests lock in the public shape of `window.portalLazy` and the integration point in `activateColumn`. Write them after Phase B confirms the final implementation shape to avoid locking in details that change during wiring.

**Delivers:** New `test/assets/portal_lazy_js_contract_test.rb` asserting `window.portalLazy`, `register`, `loadColumn`, mobile guard, and `STORAGE_KEY` are present. Extended `portal_mobile_tabs_js_contract_test.rb` asserting `portalLazy.loadColumn` appears inside `activateColumn`. Existing Cucumber `@mobile_portal` scenarios (tab switch, swipe, localStorage restore) must pass unchanged.

**Avoids:** PITFALL-5 (layout save data loss) — add explicit verification that `$.sortable` has a mobile guard; add guard if absent.

**Verification gate:** All three suites green with zero new failures. Re-run `bundle exec rake dad:test` twice to confirm stability against known flakiness.

### Phase Ordering Rationale

- Phase A before B because `window.portalLazy` must exist before any partial calls `register`. The coordinator is a pure addition with zero behavior change on desktop.
- Phase B combines partial wiring and the `activateColumn` hook in one commit because they form an atomic feature: partials register loaders, the hook drains them.
- Phase C after B because contract tests should assert the final shape, not a moving target. Existing Cucumber `@mobile_portal` scenarios provide E2E coverage without new scenarios required.

### Research Flags

Phases with well-documented patterns (skip additional research-phase):
- **Phase A:** `window.portalLazy` module pattern is standard jQuery/vanilla JS; no API unknowns.
- **Phase B:** All touch points were read directly during research; no surprises expected.
- **Phase C:** Existing contract test pattern (`test/assets/portal_mobile_tabs_js_contract_test.rb`) provides the template.

No phase requires `/gsd:plan-phase --research-phase` — all integration points were verified by direct codebase inspection during research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs verified; alphabetical Sprockets load order confirmed; zero new dependencies required |
| Features | HIGH | All gadget types inspected directly; AJAX vs SSR classification verified per partial; edge cases explicitly enumerated |
| Architecture | HIGH | All integration points read directly: `portal_mobile_tabs.js`, `_portal_column_section.html.erb`, all gadget partials, `_dashboard.html.erb` |
| Pitfalls | HIGH | All 7 pitfalls derived from direct codebase inspection with specific file/line references |

**Overall confidence:** HIGH

### Gaps to Address

- **`todos.init` AJAX classification:** Whether `todos.init` makes network requests was not confirmed. Verify at Phase B start: if DOM-only, skip wrapping; if it makes AJAX calls, wrap it the same as other AJAX gadgets.
- **Sortable init mobile guard:** Research identifies the risk (PITFALL-5) but does not confirm whether `$('.gadgets').sortable()` already has an `isMobileViewport()` guard. Verify at Phase C start; add guard if absent.
- **`--portal-initial-active-index` CSS property:** Architecture research proposes reading this CSS property for initial column detection. Verify this property is written by the inline prehydration script in `_dashboard.html.erb` before committing to it; fall back to `localStorage` if absent.

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `app/assets/javascripts/portal_mobile_tabs.js` — `activateColumn`, `isMobileViewport`, localStorage restore path, swipe handler
- `app/views/welcome/_portal_column_section.html.erb` — column render loop, `id="column_N"` structure
- `app/views/welcome/_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb` — inline `$(document).ready` AJAX pattern
- `app/views/welcome/_bookmark_gadget.html.erb`, `_todo_gadget.html.erb` — SSR/non-AJAX classification
- `app/views/welcome/_dashboard.html.erb` — `collect_portal_layout_params`, sortable init, prehydration script
- `app/assets/javascripts/application.js` — Sprockets manifest; alphabetical `require_tree` ordering
- `app/models/portal.rb` — column distribution; each gadget appears in exactly one column
- `.planning/PROJECT.md` — no new npm deps constraint; jQuery 4.6.1 confirmed
- `test/assets/portal_mobile_tabs_js_contract_test.rb` — existing contract test pattern as template
- `features/03.モダンテーマ.feature` — existing `@mobile_portal` Cucumber scenarios

### Secondary (HIGH confidence — external reference)
- jQuery API documentation (api.jquery.com) — `.data()`, `$.get()`, `$(fn)` confirmed stable since jQuery 1.x, no breaking changes in jQuery 4

---
*Research completed: 2026-05-17*
*Ready for roadmap: yes*
