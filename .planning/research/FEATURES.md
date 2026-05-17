# Features Research — v1.24 Mobile Column Lazy Loading

**Project:** Bookmarks v1.24
**Researched:** 2026-05-17
**Confidence:** HIGH (existing code read directly; no external APIs or new libraries involved; feature is pure client-side JavaScript against an already-built server)

---

## Summary

v1.24 adds deferred gadget loading on mobile: instead of firing all AJAX gadget requests at page load (the current behavior), only the initially active column's gadgets load immediately; each non-active column defers its gadgets until the first time a user visits that column within the page session. Once a column has loaded, switching back to it shows the already-loaded content — no re-fetch.

Desktop behavior is unchanged: all columns render immediately as they do today.

The scope is narrow: the feature lives entirely in `portal_mobile_tabs.js` and a new data attribute on each column's DOM element. No server changes, no new routes, no schema changes, no new JS dependencies.

---

## How the Existing System Works (Baseline)

Understanding what must change requires mapping the current load path precisely.

**Gadget types and their load patterns:**

| Gadget | Load mechanism | AJAX? |
|--------|---------------|-------|
| Bookmark | SSR — rendered fully by Rails on page load | No |
| Todo | SSR — rendered fully by Rails on page load, `todos.js` adds behavior | No |
| Calendar | DOM placeholder on SSR; `$(document).ready` fires `$.get(get_gadget_calendars_path)` | Yes |
| Feed | DOM placeholder on SSR; inline `<script>` fires `$.get(feed_path)` on `$(document).ready` | Yes |
| Mastodon account | DOM placeholder on SSR; inline `<script>` fires `$.get(mastodon_account_path)` on `$(document).ready` | Yes |
| X account | DOM placeholder on SSR; inline `<script>` fires `$.get(x_account_path)` on `$(document).ready` | Yes |

All AJAX gadgets fire their requests from `$(document).ready` callbacks embedded as inline `<script>` tags inside each gadget partial. Those scripts run immediately on DOM-ready regardless of which column the gadget sits in.

**Column visibility today:** CSS uses `transform: translateX(calc(-100% * var(--portal-active-index, 0)))` on `.portal-track` to slide the visible column into view. All columns are in the DOM and all gadgets load — only the visible one is in the user's viewport.

**The problem this milestone solves:** On mobile, a user on column 1 still triggers AJAX requests for every Mastodon, X, and feed gadget in columns 2, 3, and 4. These are wasted round-trips that slow page load on cellular connections and consume API rate-limit budget on feeds and X accounts.

---

## Table Stakes

Features the milestone is incomplete without. Missing any one means the requirement stated in PROJECT.md is not met.

| Feature | Why Required | Complexity | Dependency |
|---------|-------------|------------|------------|
| **Active-column-only load on page load (mobile)** | Core premise. Non-active column gadgets must not fire AJAX on `$(document).ready`. | Medium | Requires a signal per column indicating whether it has loaded; must intercept `$(document).ready` inline scripts — see implementation section |
| **Load-on-first-visit for non-active columns** | Core premise. First tab switch to an unloaded column triggers its gadget requests. | Medium | Depends on active-column-only load; requires `activateColumn` in `portal_mobile_tabs.js` to check loaded state and trigger deferred load |
| **Load-once guarantee: no re-fetch on revisit** | The spec is "exactly once" per page session. Switching back to a loaded column must show cached content without another AJAX round-trip. | Low | A per-column boolean (in-memory JS variable or DOM `data-loaded` attribute) is sufficient; `localStorage` is not needed — it would persist across page sessions, which is wrong |
| **Desktop unchanged** | All gadgets still load on `$(document).ready` at `>= 768px`. The lazy-load path is mobile-only. | Low | `isMobileViewport()` guard already exists in `portal_mobile_tabs.js` |
| **Works for all AJAX gadget types** | Feed, Mastodon, X, Calendar all use the `$(document).ready` pattern; the deferral mechanism must cover all of them | Medium | Single mechanism must apply uniformly, not per-gadget-type |
| **Works for SSR-only gadgets (Bookmark, Todo)** | These do not fire AJAX; they render their content at SSR time. On mobile they are visible in their column immediately after the CSS slide. No JS load trigger is needed for them. The mechanism must not break them. | Low | No change needed for SSR gadgets; they are already in the DOM |
| **Works across all 3 themes (modern, classic, simple)** | Portal column layout is shared across themes via `_portal_column_section.html.erb`. Tab switching works the same on all three. | Low | Same `portal--column-active-N` CSS class, same `.portal-column` DOM structure |
| **Works for 3-column and 4-column layouts** | `portal_column_count` is user-configurable (3 or 4). The lazy mechanism must handle N columns generically, not hardcode 3. | Low | `portalColumnCount($portal)` already counts columns dynamically |
| **Correct behavior when `localStorage`-restored column is non-zero** | If the user last left on column 2, page load restores column 2. Column 2 must load immediately; columns 1, 3 must defer. This is the "initially active column" regardless of index. | Medium | The restored-column path already calls `activateColumn()`; lazy logic must hook into that same call |

---

## Differentiators

Features that improve the experience beyond the core spec but are not required for the milestone to be complete.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Loading indicator per deferred column** | When the user first switches to an unloaded column, gadgets may briefly show their SSR placeholder ("Loading…") while AJAX completes. This is already the behavior on first page load, so it is not new UI — but a brief delay feels intentional if the indicator is already present. No extra work needed; it is free from the existing placeholder pattern. | None (already built) | The `t('.loading')` span in each AJAX partial already handles this |
| **Abort in-flight requests when switching away mid-load** | If a user switches to column 2, then immediately switches to column 3 before column 2's AJAX completes, column 2's requests continue in the background and fill in when they arrive. This is harmless (the column loads correctly on next visit) but wastes bandwidth. Aborting with `jqXHR.abort()` would cancel them. | Medium | The inline `<script>` pattern makes tracking jqXHR handles awkward. Given mobile users on fast connections rarely care, this is a deferred nice-to-have. Do not block the milestone on it. |
| **Preload adjacent column on idle** | After the active column loads, silently kick off the next column's load using `requestIdleCallback` or a short `setTimeout`. This would make switching feel instant. | High | Adds speculative loading complexity and may defeat the bandwidth-saving goal if the user never visits the adjacent column. Explicitly out of scope for v1.24. |

---

## Anti-Features

Features to explicitly not build in this milestone.

| Anti-Feature | Why Exclude |
|--------------|------------|
| **Server-side column-scoped endpoint** | Adding a `GET /portal/column/:n/gadgets` route that returns only one column's gadgets would be a cleaner architecture but requires server changes, a new controller action, and redesigning how gadget partials are assembled. The inline-script approach works within the existing SSR partial structure with zero server changes. Do not introduce server complexity for a client-side optimization. |
| **Per-session or persistent lazy-load state via `localStorage`** | Loaded-column state must reset on every page load. Using `localStorage` would mean column 2 never reloads after the first visit, even after a full page refresh — which is wrong if feed content has changed. In-memory JS state (or `data-loaded` on the DOM element) is the correct scope. |
| **Replacing `$(document).ready` inline scripts with a data-driven loader** | Refactoring all gadget partials to move JS out of inline `<script>` tags and into a centralized loader would be cleaner but touches every gadget partial and potentially breaks the SSR partial rendering contract used by controller tests. The existing `$(document).ready` pattern is the constraint to work within. |
| **Virtualization or DOM removal of off-screen columns** | Removing non-visible column DOM nodes after loading (to reduce memory) would break the CSS slide animation and require re-rendering columns on every revisit. The DOM is small; leave all columns in the tree. |
| **Lazy loading on desktop** | Desktop shows all columns simultaneously. There is no "active column" concept there. Applying lazy loading on desktop would defer gadgets that the user can see immediately, which degrades the experience. Mobile-only. |
| **Intersection Observer for load triggering** | An Intersection Observer on each `.portal-column` element would be semantically correct for "trigger when column enters viewport." However, the portal uses a CSS `translateX` slide, which means all columns have a non-zero `getBoundingClientRect` in the scrollable container — `IntersectionObserver` may report all of them as intersecting. The tab-click and swipe events are the explicit user signals and are the correct trigger points. |
| **Lazy loading the Note gadget (simple/modern/classic themes)** | The Note gadget is not an AJAX gadget — it renders SSR content and uses a POST form. It is not affected by this milestone and must not be touched. |
| **New JavaScript dependencies** | The constraint from PROJECT.md: no new npm packages, no new bundler, no changes to Sprockets pipeline. All logic must work with jQuery 4 and vanilla JS already in the bundle. |

---

## Feature Dependencies on Existing Portal System

These are the concrete integration points that the implementation must hook into. Each is a coupling risk if misunderstood.

| Dependency | How It Affects Lazy Loading |
|------------|---------------------------|
| **Inline `<script>` inside each AJAX gadget partial** | Each partial (`_feed.html.erb`, `_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb`) contains a `$(document).ready(function() { $.get(...) })` that fires unconditionally. The lazy mechanism must prevent these from firing in non-active columns, or trigger them on-demand after the column becomes active. The most practical approach: replace `$(document).ready` with a custom trigger (e.g., `$(document).on('portal:column-loaded', '#column_N', ...)`) and fire that event from `activateColumn` on first visit. |
| **`activateColumn` in `portal_mobile_tabs.js`** | All column switches go through this function: tab clicks and swipe gestures both call it. This is the correct single hook point for triggering deferred loads. The function must gain a "load this column if not yet loaded" step. |
| **`$(document).ready` initialization block** | The initialization block at the bottom of `portal_mobile_tabs.js` calls `activateColumn` for the restored/initial column. The lazy-load logic must apply here too — the initially active column must load immediately via the same trigger. |
| **`isMobileViewport()`** | Already exists as a guard. All lazy-load logic must be wrapped in this same check so desktop is unaffected. |
| **`data-portal-column-index` attribute** | Each `.portal-column-tab` button already carries this attribute; each `.portal-column` div has `id="column_N"`. The loaded-state tracking can use `id` as the key (`Set` of loaded column indices in JS, or `data-loaded="true"` on each `.portal-column` div). |
| **`portal--column-active-N` CSS class on `.portal`** | This is the CSS hook for the slide position. The lazy-load mechanism should not depend on reading this class to determine what to load — it should track load state independently (a JS `Set` or DOM attribute) to avoid ambiguity if the class update and the load trigger race. |
| **SSR gadgets (Bookmark, Todo) inside non-active columns** | These have no AJAX; they are fully rendered at SSR time. On mobile, their DOM is already in the non-active column. The lazy mechanism must not attempt to "load" them — they are already loaded. Only columns containing at least one AJAX gadget benefit from deferral. In practice, the mechanism should fire a generic "column is now active" event and let AJAX gadgets self-register for it; SSR gadgets simply do not register. |
| **Drag-and-drop sort (`$('.gadgets').sortable()`)** | The `sortable()` initialization runs on `$(document).ready` for all `.gadgets` containers across all columns. This must remain unconditional — do not defer sortable initialization. It does not make network requests and must be active for any column the user switches to. |

---

## Edge Cases and UX Considerations

These must be explicitly handled or consciously accepted in the implementation.

### Fast Tab Switching

**Scenario:** User clicks column 2, then immediately clicks column 3 before column 2's AJAX completes.

**Expected behavior:** Column 2 is marked as "load started" (or "loaded") on first click and is not re-fetched. Column 3's load begins on first click to column 3. Both loads proceed concurrently. When column 2's AJAX resolves, its gadget content fills in even though the column is not currently visible; next time the user visits column 2, the content is already there.

**Implementation note:** Mark a column as "triggered" the moment `activateColumn` fires for it, not when AJAX completes. This prevents a second click on the same column tab during load from firing a duplicate AJAX batch.

### AJAX Failure on First Column Visit

**Scenario:** A feed or X gadget fails (network error, API timeout) on the first load of a non-active column.

**Expected behavior:** The existing `.fail()` handler on each gadget's `$.get` call displays the localized error message in the gadget placeholder. The column should still be marked as "loaded" (attempted) — do not allow a failure to leave the column in a perpetually unloaded state, which would re-fire the failed request on every subsequent tab visit and produce error flicker.

**Alternative to consider:** Mark as loaded unconditionally on first trigger. Individual gadget error states handle their own messaging; the column-level concern is only "did we try?", not "did all gadgets succeed?".

### LocalStorage-Restored Column is Non-Zero

**Scenario:** User previously left on column 3. On page reload, `localStorage` restores index 2 (0-based). The initialization block calls `activateColumn($portal, $tabs, 2)`.

**Expected behavior:** Column 3 (index 2) loads immediately as the initially active column. Columns 1 and 2 (indices 0 and 1) defer until first switch.

**Key point:** The "initially active" column is determined by `activateColumn` call during initialization, not by which column is index 0. The lazy logic must treat whichever column is activated at initialization time as the first-loaded column.

### Desktop Viewport Resize (Mobile → Desktop)

**Scenario:** User opens portal on mobile, switches to column 2 (column 2 loads), then rotates to landscape or resizes browser to > 768px.

**Expected behavior:** Desktop layout shows all columns. Columns that had not loaded on mobile (e.g., column 3) are missing their AJAX content. This is an edge case and is acceptable for v1.24 — full-page reload resets to desktop behavior. Do not attempt to trigger deferred loads on viewport resize; it adds significant complexity for a marginal case. Document the behavior.

### Swipe Navigation During Partial Load

**Scenario:** User swipes left to column 2 while column 2's load is in progress.

**Expected behavior:** The swipe also calls `activateColumn`; since the column is already marked as triggered, no duplicate load is fired. The column content fills in as AJAX completes. No change needed beyond the fast-tab-switching handling.

### Zero AJAX Gadgets in a Column

**Scenario:** A column contains only Bookmark and Todo gadgets (SSR-only). The user never switches to it.

**Expected behavior:** Nothing happens — no AJAX was ever deferred for this column. The column is "loaded" from SSR; no lazy trigger is needed. The implementation should not attempt to trigger a load event for columns that have no AJAX gadgets, or if it does, the event handler is simply not registered, so nothing fires. Both approaches work.

### Single-Column Portal

**Scenario:** User has only one column (or column count is 1 for some reason). `portalColumnCount($portal)` returns 1.

**Expected behavior:** The existing code already guards `if (colCount < 1) return`. With one column, there are no non-active columns to defer. The lazy mechanism should short-circuit cleanly: the single column loads immediately, no deferred state is tracked.

---

## Implementation Approach (Recommended)

This section is a research finding, not a binding spec. The roadmap will refine it.

The lowest-risk approach given the constraints:

1. **Change inline `<script>` in each AJAX gadget partial** to listen for a custom DOM event on the column container instead of `$(document).ready`:

   ```javascript
   // Before (current):
   $(document).ready(function() {
     $.get(url, ...).fail(...);
   });

   // After (proposed):
   $(document).on('portal:column-activate', '#column_N', function() {
     $.get(url, ...).fail(...);
   });
   ```

   Where `#column_N` matches the column's `id="column_N"` attribute.

2. **Fire `portal:column-activate` from `activateColumn`** in `portal_mobile_tabs.js`, but only on mobile and only on first visit:

   ```javascript
   // Track which column indices have been activated this page session
   const loadedColumns = new Set();

   const activateColumn = function($portal, $tabs, index) {
     // ... existing tab/class/CSS logic ...

     if (isMobileViewport() && !loadedColumns.has(index)) {
       loadedColumns.add(index);
       $('#column_' + index).trigger('portal:column-activate');
     }
   };
   ```

3. **On desktop**, keep `$(document).ready` behavior by also firing `portal:column-activate` on all columns during `$(document).ready` when not on mobile, or by keeping the existing `$(document).ready` pattern as a fallback for non-mobile contexts.

   Simpler alternative: fire `$(document).ready` AND `portal:column-activate` from each partial, but on desktop the `$(document).ready` fires first and does the work. On mobile, suppress `$(document).ready` by checking `isMobileViewport()` inside the ready callback:

   ```javascript
   $(document).ready(function() {
     if (isMobileViewport()) return; // defer to portal:column-activate
     $.get(url, ...).fail(...);
   });
   $(document).on('portal:column-activate', '#column_N', function() {
     if (!isMobileViewport()) return; // already loaded by ready
     $.get(url, ...).fail(...);
   });
   ```

   This pattern avoids any race between the two events and keeps desktop behavior entirely unchanged.

**Tradeoff of this approach:** Each AJAX gadget partial must be edited (4 partials: feed, mastodon\_account, x\_account, calendar\_gadget). This is a small set and the change is mechanical. The alternative — a centralized loader that scans column contents — would not require partial edits but adds a complex DOM-traversal mechanism with fragile gadget-type detection.

---

## Feature Dependencies Summary Table

| Feature | Depends on |
|---------|-----------|
| Active-column-only load | `isMobileViewport()` guard; `activateColumn()` hook; `loadedColumns` Set |
| Load-on-first-visit | `activateColumn()` calling `trigger('portal:column-activate')` on first visit |
| Load-once guarantee | `loadedColumns.has(index)` check in `activateColumn()` |
| Swipe navigation deferral | `activateColumn()` already called by swipe handler; load-once check handles deduplication |
| localStorage restore path | Initialization block calls `activateColumn()` for restored index; same path, same load-once check |
| Feed deferred load | `_feed.html.erb` partial updated to listen for `portal:column-activate` |
| Mastodon deferred load | `_mastodon_account.html.erb` partial updated |
| X account deferred load | `_x_account.html.erb` partial updated |
| Calendar deferred load | `_calendar_gadget.html.erb` partial updated |
| Bookmark / Todo unchanged | No change — SSR gadgets do not fire AJAX |
| Desktop unchanged | `isMobileViewport()` guard in `activateColumn()` and inside each partial's `$(document).ready` |
| 3-col / 4-col compatibility | `portalColumnCount()` already dynamic; `loadedColumns` Set works for any N |
| Theme compatibility | `_portal_column_section.html.erb` shared across themes; tab/swipe JS shared across themes |

---

## MVP Recommendation

Build exactly the Table Stakes list. Every item in it is required by the milestone definition. The only differentiator worth noting is that the existing loading placeholder is already present in every AJAX gadget — no extra UX work is needed for the "loading" state of a newly-visited column.

Do not build:

- Abort of in-flight requests on column switch — low value, high complexity
- Adjacent-column preload on idle — actively conflicts with the bandwidth-saving goal
- Any server-side changes

The implementation should land as:

- Phase A: Update `portal_mobile_tabs.js` — add `loadedColumns` Set, fire `portal:column-activate` from `activateColumn`, guard with `isMobileViewport()`
- Phase B: Update 4 AJAX gadget partials — add `portal:column-activate` listener, suppress `$(document).ready` on mobile
- Phase C: Minitest contracts for new behavior + Cucumber `@mobile_portal` scenario covering first-visit load and revisit cache
- Phase D: Verification gate (tri-suite green)
