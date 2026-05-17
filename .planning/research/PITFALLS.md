# Pitfalls Research — v1.24 Mobile Column Lazy Loading

**Project:** Bookmarks v1.24
**Researched:** 2026-05-17
**Confidence:** HIGH (all findings derived from direct codebase inspection; patterns cross-checked against jQuery AJAX docs and Sprockets behaviour)

---

## Context

v1.24 adds "load once" deferred AJAX loading to mobile column tabs. The existing system already loads all gadget content on page load via inline `<script>` blocks (one `$(document).ready(function() { $.get(…) })` per AJAX gadget). The mobile tab strip (`portal_mobile_tabs.js`) switches visible columns via CSS `translateX` and class assignment with no knowledge of loading state. The goal is: on mobile, defer loading of non-active columns until first switch to them, then cache forever within the session.

---

## Critical Pitfalls

### PITFALL-1: `$(document).ready` fires unconditionally for all gadgets

**What goes wrong:**
Every AJAX gadget partial (`_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`) contains an inline `<script>` block that calls `$(document).ready(function() { $.get(…) })`. This fires immediately on page load regardless of which column the gadget is in, and regardless of whether the viewport is mobile. Adding a "load only when column is active" guard requires intercepting or deferring these scripts — you cannot simply skip them via a CSS-only approach.

**Why it happens:**
The existing pattern was designed for a "load all on page load" desktop model. The partials are rendered by Rails ERB into the full column HTML — the JavaScript is baked into the partial, not wired centrally. There is no separation between "render placeholder HTML" and "fire AJAX request."

**How to avoid:**
Two viable approaches — pick one and commit:

Option A (data-driven deferral): Keep the existing partials but add a `data-lazy-src` attribute to each gadget container. A new central JS function reads that attribute and fires the `$.get` when triggered. The inline `<script>` block is either removed from the partial or guarded by `if (window.__mobilePortalLazy !== true)` (set by `portal_mobile_tabs.js` on mobile).

Option B (server-side branching): Pass an ERB local `lazy: true` to the partial. When `lazy: true`, the inline `<script>` is suppressed and only the placeholder HTML is rendered. On mobile, the column activation handler calls a central `loadColumnGadgets(index)` function that issues the AJAX calls. This keeps JS logic centralised in `portal_mobile_tabs.js` but requires changing every AJAX gadget partial signature.

Option A is lower-risk because it touches fewer files. Option B is cleaner long-term. In either case, the pattern must be applied consistently to all three AJAX gadget types.

**Warning signs:**
- Running `grep -r "document.ready" app/views/welcome/` after the change still shows AJAX calls firing for non-active column gadgets on mobile.
- Network tab in DevTools shows requests for feed, mastodon, and x_account gadgets in columns 2 and 3 on initial mobile page load.

**Phase to address:** The phase that modifies gadget partials for lazy loading (Phase 1 of the roadmap).

---

### PITFALL-2: "Load once" state stored in the wrong scope — per-gadget vs per-column

**What goes wrong:**
Tracking loaded state per gadget ID (e.g., `const loadedGadgets = new Set()`) requires knowing each gadget's ID at column-activation time. The tab click handler in `portal_mobile_tabs.js` currently only knows the column index — it has no reference to individual gadgets inside that column. If the state is tracked per-column instead (e.g., `const loadedColumns = new Set()`), the semantics match exactly: "has column N been loaded?" A gadget-level tracker requires scanning DOM children of the column, which works but adds fragility if gadget IDs change or are absent.

**Why it happens:**
Naive implementations follow the pattern from other "load once" systems (tabs that fetch a single resource per tab) and track by gadget URL or gadget ID. The portal has N gadgets per column, not one. The correct unit is the column, not the gadget.

**How to avoid:**
Track `loadedColumns` as a `Set` (or plain object) keyed by column index. In `activateColumn`, after confirming it is a mobile viewport and a new column: call `loadColumn(index)` only if `loadedColumns.has(index)` is false, then `loadedColumns.add(index)`. The initial active column is pre-loaded server-side (full render) or loaded immediately — mark column 0 (or the restored localStorage column) as already in `loadedColumns` during init.

**Warning signs:**
- Switching to column 2 fires AJAX requests; switching back to column 2 fires them again.
- Gadgets in a column fire some-but-not-all requests on second visit (gadget-level partial tracking rather than column-level tracking).

**Phase to address:** Phase 1 (state tracking design).

---

### PITFALL-3: Race condition between localStorage column restoration and deferred load

**What goes wrong:**
`portal_mobile_tabs.js` already restores the last-visited column from `localStorage` on page load (lines 121–136). If column 2 was active last visit and is restored, the lazy-load logic must also trigger loading for column 2 immediately — not wait for a tab click that never comes. If the init path only marks column 0 as "loaded" and then switches to column 2 visually without loading it, column 2 displays blank gadgets.

**Why it happens:**
The init code and the tab-click handler are two separate paths that both call `activateColumn`. The lazy load trigger is easy to wire into the click path but missed in the init/restore path.

**How to avoid:**
The `activateColumn` function is the single convergence point for both tab click and swipe and init. Add the lazy-load trigger inside `activateColumn` itself, not inside the click handler. The condition: `if (isMobileViewport() && !loadedColumns.has(index)) { loadColumn(index); loadedColumns.add(index); }`. This fires correctly on init/restore and on every tab switch, without duplicating the condition.

**Warning signs:**
- Page restored to column 2 on mobile; gadgets show "Loading…" indefinitely because no AJAX was fired.
- Column 2 gadgets load correctly on tab click but not on page reload with localStorage set to column 2.

**Phase to address:** Phase 1 (init path wiring, same commit as `activateColumn` changes).

---

### PITFALL-4: Desktop behavior broken by mobile-only guard that fires on all viewports

**What goes wrong:**
The `isMobileViewport()` check at line 6 of `portal_mobile_tabs.js` reads `window.matchMedia('(max-width: 767px)')` at call time. On desktop, this returns false, so the localStorage restore block (lines 121–136) is correctly skipped. But if the lazy-load logic is added without the same guard, it can suppress desktop AJAX loading — all gadgets would appear as "Loading…" on desktop permanently if the "skip inline script" path fires unconditionally.

**Why it happens:**
The new lazy-load branch touches gadget partials that render on both desktop and mobile. A guard added in the ERB partial that suppresses `$(document).ready` globally (without checking viewport) breaks desktop. A guard added in JS that checks `isMobileViewport()` only in the click path misses the fact that on desktop there is no tab click — gadgets must still fire on `document.ready`.

**How to avoid:**
The desktop path must remain unchanged. The server-side branch (`lazy: true` local) must only be rendered when the page is served to a mobile client — which is not detectable at SSR time reliably (no `matchMedia` on the server). Therefore: always render the placeholder HTML (no inline `$.get` in partials for AJAX gadgets), but emit a `data-ajax-url` attribute on the container. On desktop, a separate initializer fires `$.get` for every `[data-ajax-url]` element immediately on `document.ready`. On mobile, the column activation handler fires `$.get` for elements within the activated column only. Both paths use the same attribute; only the trigger differs.

Alternatively: keep the existing inline `<script>` partials for desktop (default behaviour unchanged) and have `portal_mobile_tabs.js` cancel or suppress the ready-queue requests — this is complex and fragile. Prefer the data-attribute approach.

**Warning signs:**
- Feed gadgets show "Loading…" on desktop after the change.
- Toggling browser to desktop viewport triggers gadget loads; refreshing desktop page does not.

**Phase to address:** Phase 1 (desktop vs mobile branching design decision — must be locked before any partial is modified).

---

### PITFALL-5: `collect_portal_layout_params` queries `#column_<i> > div` — fails if column has no rendered children yet

**What goes wrong:**
`_dashboard.html.erb` contains a `collect_portal_layout_params()` function that iterates `$('#column_<%= i %> > div').each(…)` to collect gadget IDs for drag-drop layout save. If lazy loading defers rendering the gadget `<div>` elements into a column until first visit, `#column_1 > div` returns an empty set. When the user saves layout (by dragging on desktop) before visiting column 1 on mobile, those gadgets are silently omitted from the layout save POST — effectively deleted from the user's layout.

**Why it happens:**
Layout save was designed assuming all column `<div>` children are present in the DOM at page load. Lazy loading breaks this assumption by deferring injection of gadget HTML into non-active columns.

**How to avoid:**
Two constraints that shape the solution:

1. On desktop, lazy loading is not active — all columns render as today. `collect_portal_layout_params` continues to work unchanged on desktop. This is acceptable because layout drag-drop (`$.sortable`) is desktop-only UX (touch drag is not enabled on mobile).

2. On mobile, lazy loading defers columns but `$.sortable` is not initialised for mobile (the CSS `portal-track` / translateX layout does not support drag-drop). Therefore the `collect_portal_layout_params` code path is never triggered on mobile.

Verify this assumption explicitly: confirm in the sortable initializer (`$('.gadgets').sortable(…)`) that it runs on all viewports. If it does, add a `if (!isMobileViewport())` guard to the sortable init. This protects against the layout-save ghost-deletion edge case and is a defensive, low-risk change.

**Warning signs:**
- After dragging gadgets on desktop and saving layout, some gadgets from non-visited columns disappear from the portal.
- `PortalLayout` records for columns 1 and 2 are deleted after a save triggered before those columns were visited on mobile.

**Phase to address:** Phase 1 (verify sortable/layout-save interaction; add guard if sortable is unconditionally initialised).

---

### PITFALL-6: `$(document).ready` callbacks accumulate multiple times per gadget if `loadColumn` is called without the "loaded" guard on swipe

**What goes wrong:**
The swipe handler (touchend, lines 96–118 of `portal_mobile_tabs.js`) calls `activateColumn`. If `activateColumn` triggers gadget loading and the loaded-state check is not atomic with the call, rapid left-right swiping can call `loadColumn(index)` twice before the first AJAX completes. Each call issues a `$.get`. If the success callback does `$('#container').html(html)`, the second response overwrites the first (harmless but wasteful) or arrives out of order (shows stale data briefly).

**Why it happens:**
JavaScript callbacks from `$.get` are async. `loadedColumns.add(index)` must happen synchronously before the AJAX completes, not inside the success callback. A common mistake is: `loadColumn(index).then(() => loadedColumns.add(index))` — this leaves a window where a second swipe triggers a duplicate request.

**How to avoid:**
Mark the column as loaded immediately (synchronously) before issuing any `$.get` calls. The sequence inside `loadColumn`:
```js
loadedColumns.add(index); // mark FIRST, before any async
$('#column_' + index).find('[data-ajax-url]').each(function() {
  const url = $(this).data('ajax-url');
  $.get(url, function(html) { /* … */ });
});
```
This is idempotent: even if `activateColumn` fires twice rapidly, the second call sees `loadedColumns.has(index)` as true and does nothing.

**Warning signs:**
- DevTools Network shows duplicate requests for the same gadget URL when swiping back and forth quickly.
- Gadget briefly shows wrong content when swiping rapidly between column 1 and column 2.

**Phase to address:** Phase 1 (state tracking must be synchronous, confirmed by Minitest or Cucumber swipe-test).

---

### PITFALL-7: `isMobileViewport()` snapshot at page load — resize does not re-trigger loading

**What goes wrong:**
`isMobileViewport()` reads `window.matchMedia('(max-width: 767px)').matches` at call time. If a user loads the page in a narrow desktop window (mobile breakpoint), lazy loading activates. They then resize to full width — gadgets in non-visited columns never load, because there is no `resize` listener that detects the viewport change and triggers desktop-style loading for previously-skipped columns.

**Why it happens:**
`matchMedia` is a snapshot, not a subscription. This is fine for the existing column-restore logic (it only runs once on init) but creates a gap when lazy loading is involved.

**How to avoid:**
Document the known limitation explicitly: "viewport resize during a page session may leave non-visited columns unloaded." This is acceptable for a personal mobile-first app where resize scenarios are rare. Do NOT attempt to wire a `resize` or `matchMedia.addListener` handler for v1.24 — it introduces complexity disproportionate to the risk. Instead, ensure that a desktop page load (via the data-attribute pattern from PITFALL-4) always fires all `$.get` calls unconditionally on `document.ready`, so the resize-to-desktop case is automatically covered.

**Warning signs:**
- Loading on narrow desktop → widening → non-visited columns are blank.
- If this scenario appears in Cucumber (unlikely), it will be flagged by the viewport-resize helper already in `features/support/window_resize.rb`.

**Phase to address:** Phase 1 (document the limitation; ensure desktop path fires all gadgets unconditionally).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inline `<script>` per gadget partial with `document.ready` | Simple, self-contained per gadget | Cannot defer or conditionally suppress without touching every partial | Acceptable pre-v1.24; must be refactored for lazy loading |
| Tracking load state in a JS module-scope `Set` (not persisted) | Simple, no storage overhead | Column appears blank if page is hard-refreshed mid-session (expected; not a bug) | Always acceptable — "load once per page session" is the spec |
| Using `isMobileViewport()` snapshot rather than `matchMedia.addListener` | Simple, no resize handler | Resize mid-session can leave non-visited columns unloaded | Acceptable — personal app, low resize scenario risk |
| Suppressing `$.sortable` on mobile with an `isMobileViewport()` guard | Prevents layout-save data loss (PITFALL-5) | Drag-drop unavailable on mobile (already the case UX-wise) | Always acceptable |
| Keeping existing inline `<script>` for non-AJAX gadgets (bookmark, todo, calendar) | No changes to gadgets that don't use AJAX | Lazy loading only helps AJAX gadgets; static gadgets always render instantly anyway | Always acceptable — static gadgets have no load-deferral benefit |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `portal_mobile_tabs.js` + gadget partials | Adding lazy-load logic inside the tab click handler only — misses swipe and init/restore paths | Add trigger inside `activateColumn()` which is the single convergence point for all activation paths |
| Inline `<script>` in ERB partials + column deferral | Removing inline `<script>` breaks desktop because there is no other trigger for those gadgets | Use `data-ajax-url` attribute pattern: desktop fires all on `document.ready`, mobile fires per column |
| `collect_portal_layout_params` + lazy-loaded columns | Layout save silently loses gadgets from unvisited columns | Verify that `$.sortable` is not initialised on mobile; add guard if it is |
| `localStorage` column restore + lazy load | Restoring to column 2 on mobile but not triggering load for column 2 | Drive lazy load from `activateColumn()`, not from the tab click event — init calls `activateColumn` too |
| `$(document).ready` + async loaded state | Marking column as loaded inside `$.get` success callback leaves race window | `loadedColumns.add(index)` must be synchronous, before any `$.get` is issued |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| AJAX gadgets in all 3 columns fire on mobile page load | Mobile LCP delayed; Puma handles 3× more concurrent AJAX requests per page view | Lazy loading is the fix; don't add more AJAX gadgets to non-column-0 positions without implementing lazy loading first | Any mobile page load with AJAX gadgets in columns 1 and 2 |
| Loading entire column's gadgets simultaneously on first switch | Column switch triggers 3–5 parallel AJAX requests at once (existing pattern, not new) | Acceptable for personal single-user app; would need throttling at scale | Irrelevant at single-user scale |
| `window.localStorage` read on every `isMobileViewport` call | Not a perf issue; localStorage read is synchronous and fast | N/A | N/A |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Column 2 switches immediately but gadgets show "Loading…" for 1–2 seconds | User sees tab activate but content appears blank briefly — expected and acceptable | Preserve existing placeholder HTML ("Loading…" span) so users know content is incoming; do not show an empty column |
| Swipe to column 2 fires load; swipe back before load completes; second swipe to 2 shows stale content | Gadget shows partially-loaded or loading state on re-entry | `loadedColumns.add()` is idempotent; second `$.get` is suppressed; whatever state the gadget is in is preserved — acceptable |
| Desktop user navigates at mobile viewport width (DevTools responsive mode) — columns 1/2 never load | Developer confusion only; not a real user scenario for this personal app | Document the limitation; ensure full desktop path fires all gadgets unconditionally (PITFALL-4) |

---

## "Looks Done But Isn't" Checklist

- [ ] **Column 0 lazy guard:** Verify that column 0 gadgets load on page load (not deferred). Column 0 is always active on first load; it must not be subject to the "wait for tab click" guard.
- [ ] **localStorage restore path:** Verify that when localStorage restores column 2, gadgets in column 2 load immediately (not waiting for a tab click).
- [ ] **Desktop unchanged:** Verify that on desktop viewport, all AJAX gadgets fire on page load with no behavior change from today.
- [ ] **Re-visit does not re-fetch:** Verify that switching away from column 2 and back to column 2 does NOT fire AJAX requests a second time.
- [ ] **Swipe + tab parity:** Verify that lazy loading is triggered by swipe navigation (touchend path) exactly the same as by tab click (click path) — both converge through `activateColumn()`.
- [ ] **All three AJAX gadget types covered:** Feed, MastodonAccount, and XAccount partials all deferred. Static gadgets (BookmarkGadget, TodoGadget, CalendarGadget) are not AJAX and require no changes.
- [ ] **Sortable guard on mobile:** Confirm that `$.sortable` is either not initialised on mobile, or that layout save is guarded from issuing requests with empty column sets.
- [ ] **Theme coverage:** Simple, classic, and modern themes all render `_portal_column_section` via the same partial — changes to the partial or JS affect all three. Cucumber `@mobile_portal` scenarios cover modern and classic; verify simple-theme column restoration still works.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Desktop gadgets not loading (PITFALL-4) | LOW | Revert the partial change that removed inline `<script>`; reintroduce data-attribute approach with desktop guard |
| Column 0 gadgets permanently blank (PITFALL-1 over-applied) | LOW | Remove the mobile guard from column 0 init; ensure column 0 is pre-loaded or immediately triggered |
| Layout save deletes gadgets (PITFALL-5) | MEDIUM | Add `isMobileViewport()` guard to sortable init; run `bin/rails test` to confirm no layout persistence regressions |
| Duplicate AJAX on rapid swipe (PITFALL-6) | LOW | Move `loadedColumns.add(index)` before `$.get` calls; verify with Minitest or manual swipe test |
| localStorage restore does not trigger load (PITFALL-3) | LOW | Move lazy-load trigger into `activateColumn()` body rather than the click handler; init path already calls `activateColumn` |

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Modifying AJAX gadget partials to support deferral | PITFALL-1: `document.ready` fires unconditionally | Lock the data-attribute approach before modifying any partial; change all three AJAX partials in one commit |
| Adding load-state tracking to `portal_mobile_tabs.js` | PITFALL-6: async state race | `loadedColumns.add(index)` synchronous, before all `$.get` calls; test rapid swipe |
| Wiring lazy load into `activateColumn()` | PITFALL-3: init/restore path misses trigger | Single trigger inside `activateColumn()` body; init already calls `activateColumn()` |
| Mobile vs desktop branching | PITFALL-4: desktop gadgets broken | Unconditional desktop `document.ready` path separate from mobile column-trigger path |
| Cucumber `@mobile_portal` scenarios for lazy loading | PITFALL-3 / PITFALL-6: flaky order-dependent scenarios | Use the existing `@mobile_portal` tag; add `Before('@mobile_portal')` state reset for `loadedColumns` if tracked in module scope (JS scope is reset per-page-load — not a concern) |
| Verifying sortable interaction | PITFALL-5: layout save data loss | Add an explicit Minitest for `collect_portal_layout_params` returning all columns even without lazy-loaded content; verify sortable is not enabled on mobile |

---

## Sources

- Codebase: `app/assets/javascripts/portal_mobile_tabs.js` (column activation, localStorage restore, swipe handler, isMobileViewport)
- Codebase: `app/views/welcome/_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb` (inline `$(document).ready` / `$.get` pattern)
- Codebase: `app/views/welcome/_portal_column_section.html.erb` (portal-column DOM structure, `data-portal-column-index`)
- Codebase: `app/views/welcome/_dashboard.html.erb` (collect_portal_layout_params, sortable init)
- Codebase: `app/models/portal.rb` (portal_columns, get_gadgets — all columns rendered server-side today)
- Codebase: `features/support/window_resize.rb` (390×844 mobile viewport for @mobile_portal tag)
- Codebase: `features/support/hooks.rb` (Before hook resets; @mobile_portal tag)
- Codebase: `features/03.モダンテーマ.feature` (existing @mobile_portal Cucumber scenarios — tab switch, swipe, localStorage restore)
- Project policy: `.planning/PROJECT.md` (desktop behaviour unchanged requirement, Sprockets/jQuery constraint)
- Project policy: `CLAUDE.md` (Cucumber flakiness and rerun policy)

---

*Pitfalls research for: jQuery/Rails AJAX lazy column loading (v1.24 Mobile Column Lazy Loading)*
*Researched: 2026-05-17*
