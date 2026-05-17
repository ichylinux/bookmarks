# Stack Research — v1.24 Mobile Column Lazy Loading

**Project:** Bookmarks v1.24
**Researched:** 2026-05-17
**Confidence:** HIGH (all patterns verified against existing codebase; jQuery 4 API
confirmed from jquery-rails gem already locked; no new dependencies required)

---

## Summary

v1.24 needs "lazy load once" deferred AJAX loading of portal column gadgets on
mobile. The entire feature is implementable with zero new dependencies using
jQuery 4 patterns already in the project and the `data-*` attribute tracking
technique. No npm package, no Sprockets gem addition, no new controller endpoint.

The key insight from reading the codebase: **gadget AJAX loading already fires on
`$(document).ready` unconditionally in every gadget partial** (`_feed.html.erb`,
`_mastodon_account.html.erb`, `_x_account.html.erb`, `_calendar_gadget.html.erb`).
For v1.24 the mobile path must defer non-active-column gadgets and fire them
exactly once when their column first becomes visible.

---

## Current AJAX Loading Pattern (Existing Baseline)

Every AJAX gadget partial has this shape:

```javascript
// In each _<gadget>.html.erb, inlined <script> tag:
$(document).ready(function() {
  $.get('<%= url_for ... %>', {format: 'html'}, function(html) {
    $('#<%= gadget.gadget_id %>').html(html);
  }).fail(function(xhr) {
    // error state
  });
});
```

This fires for ALL gadgets on page load, regardless of whether the gadget's
column is visible on mobile. v1.24 must gate this for non-active mobile columns.

---

## Recommended Approach: Data Attribute Sentinel + Column Activation Hook

### Core Pattern: `data-loaded` Sentinel

Use a `data-loaded` attribute on each portal column `<div>` as the "already loaded"
flag. No JavaScript state object is needed — the DOM itself is the record.

```javascript
// Reading the flag:
const $column = $('#column_1');
if ($column.data('loaded')) return; // already loaded, skip

// Setting the flag after load completes:
$column.data('loaded', true);
```

**Why `$.data()` not `$().attr('data-loaded')`:**
jQuery's `.data()` stores values in jQuery's internal cache, not as DOM attributes.
This means:
- Write once, no DOM mutation on every load check.
- Read is a hash lookup, not an attribute parse.
- Survives content replacement inside the column (`$column.html(html)` won't clear it
  because `.data()` is keyed on the element reference, not inner HTML).
- jQuery 4 compatible — this is the same `.data()` API since jQuery 1.2.

**Why NOT `$().attr('data-loaded', 'true')`:**
Attribute writes trigger layout reflows. `.data()` does not. At this scale
(3–4 columns, 1–8 gadgets) the difference is negligible, but `.data()` is the
jQuery idiom for transient page-session state.

### Column-Level Load Gate Function

```javascript
const loadColumn = function($column) {
  if ($column.data('portal-loaded')) return; // "load once" guard
  $column.data('portal-loaded', true);       // mark before AJAX starts

  // Trigger each gadget's deferred loader in this column.
  // Each gadget registers itself via a data attribute (see below).
  $column.find('[data-gadget-loader]').each(function() {
    const loader = $(this).data('gadget-loader');
    if (typeof loader === 'function') loader();
  });
};
```

**Why mark before AJAX starts, not after completion:**
If the user switches tabs rapidly, a second tab-switch could trigger a second load
for a column whose first load is still in-flight. Marking the column loaded
synchronously on first call prevents duplicate in-flight requests — a "fire once"
guarantee even under fast switching.

### Gadget Self-Registration via `data-gadget-loader`

Instead of each gadget partial inlining a `$(document).ready` that fires
unconditionally, gadget partials register a loader function on their container:

```javascript
// In _feed.html.erb (replacing the current $(document).ready block):
$(function() {
  const $gadget = $('#feed_<%= gadget.id %>');
  const doLoad = function() {
    $.get('<%= feed_path(gadget) %>', {format: 'html'}, function(html) {
      $gadget.html(html);
    }).fail(function(xhr) {
      $gadget.find('ol li span').first()
        .text($gadget.data('fetchFailedMessage') + '(' + xhr.status + ')');
    });
  };
  $gadget.data('gadget-loader', doLoad);
  // Signal to the column coordinator that a loader is registered.
  $gadget.attr('data-gadget-loader', '');
});
```

**Why this pattern:**
- Zero changes to routing, controller, or partial HTML structure.
- The gadget partial remains the single authoritative source of its own URL,
  error handling, and DOM target.
- Desktop path: fire all loaders on page load (same as today, just via the
  coordinator instead of ad-hoc `$(document).ready`).
- Mobile path: only fire loaders for the active column on page load; defer others
  until their column is activated.

### Integration with `portal_mobile_tabs.js`

The `activateColumn` function in the existing tab switcher is the correct
integration point. Add a `loadColumn($portal.find('#column_' + index))` call
inside `activateColumn`:

```javascript
// Modified activateColumn in portal_mobile_tabs.js:
const activateColumn = function($portal, $tabs, index) {
  // ... existing class/aria/localStorage logic unchanged ...

  if (isMobileViewport()) {
    const $column = $portal.find('#column_' + index);
    loadColumn($column); // new: trigger deferred loaders for this column
  }
};
```

**Why inside `activateColumn` and not on the click handler:**
`activateColumn` is already called from three code paths:
1. Tab click handler
2. Touch-swipe `touchend` handler
3. localStorage restore on mobile viewport detection

Putting `loadColumn` here means all three activation paths trigger deferred
loading automatically. No duplication. No missed path.

### Desktop Path (Unchanged)

On desktop, all gadgets fire on `$(document).ready` as today. The coordinator
calls `loadColumn` for all columns during page-init on non-mobile viewports,
which immediately invokes all registered loaders:

```javascript
$(function() {
  if (!isMobileViewport()) {
    $('.portal-column').each(function() {
      loadColumn($(this));
    });
  }
  // Mobile: only the initially-active column is loaded; others wait for activation.
  // (The localStorage-restore path in the existing code already calls activateColumn
  //  for the restored column, which will trigger loadColumn via the hook above.)
});
```

---

## Recommended Stack (No New Dependencies)

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| jQuery 4.6.1 | Already locked (`jquery-rails`) | DOM, `.data()` sentinel, `$.get()` AJAX | All patterns below use only the `.data()` / `$.get()` / `.find()` / `.each()` APIs already exercised throughout the project. No API gaps. |
| Vanilla `data-*` attributes | N/A (HTML5) | Column-level load flag, gadget registration signal | ERB renders static attributes that JavaScript reads; no new tooling. |
| `portal_mobile_tabs.js` | In-repo (existing) | Hook point for deferred loading | `activateColumn` is already the single function that handles all column-activation paths. Inserting `loadColumn` call here covers all three activation triggers. |

### Supporting Libraries

None required. The "lazy load once" pattern for tab-switcher UIs is a
five-line jQuery idiom. No micro-library adds value here.

**Libraries evaluated and rejected:**

| Library | Verdict | Reason |
|---------|---------|--------|
| Intersection Observer (native browser API) | Reject for this use case | Designed for viewport-scroll visibility. Portal columns are hidden by CSS transform/clipping, not scroll position — IntersectionObserver may report "visible" for a column that is offscreen due to the `portal-track` translation. The tab-switch event is the correct trigger, not viewport intersection. |
| `lazysizes` (JS lazy loading lib) | Reject | npm dependency; not Sprockets-compatible without a gem wrapper; designed for `<img>` lazy loading, not arbitrary AJAX content. Overkill. |
| `jquery-lazy` or similar jQuery plugins | Reject | Not in `jquery-rails` gem; would require vendoring. Solves a more complex problem (scroll-based lazy loading) than we need. Our trigger is explicit (tab switch), not scroll-based. |
| Custom `EventEmitter` / pub-sub | Reject | Column-column communication is not needed. Each column independently tracks its own load state via `.data()`. Pub-sub adds indirection without benefit for 3–4 columns. |
| `Promise`-based deferred chain | Avoid as primary pattern | jQuery 4 ships with jQuery Deferred (`.Deferred()`, `.when()`). These work but add complexity. The sentinel + function-registration approach is simpler and sufficient. Use `$.when()` only if a gadget has a multi-step load dependency, which none currently do. |

---

## Data Attribute Contract

The following `data-*` keys are used for load coordination. None conflict with
existing attributes in the codebase (verified: existing gadget partials use only
`data-fetch-failed-message`).

| Attribute | Set By | Read By | Meaning |
|-----------|--------|---------|---------|
| `data-portal-loaded` (jQuery `.data()`) | `loadColumn()` coordinator | `loadColumn()` guard check | Column has been loaded at least once this session. Set synchronously before AJAX starts. |
| `data-gadget-loader` (HTML attribute, empty string) | Each gadget partial's `$(function)` block | `loadColumn()` selector `[data-gadget-loader]` | Signals that a `data('gadget-loader')` function is registered on this element. |
| `data('gadget-loader')` (jQuery `.data()`) | Each gadget partial's `$(function)` block | `loadColumn()` invoker | The loader function itself. Stored in jQuery cache, not DOM. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New npm package for lazy loading | Breaks Sprockets-only asset pipeline constraint; no npm runtime deps | jQuery `.data()` sentinel pattern |
| `localStorage` for per-column load state | localStorage survives page reload; "loaded" state must reset on page refresh to re-fetch fresh gadget data | In-memory jQuery `.data()` (page-session scope only) |
| Polling / `setInterval` to detect column visibility | Wrong trigger; tab switch is explicit, not time-based | `activateColumn` hook in `portal_mobile_tabs.js` |
| Modifying individual gadget partial `$(document).ready` to be mobile-aware | Would scatter mobile detection logic across every partial; violates single-responsibility | Central `loadColumn` coordinator called from `portal_mobile_tabs.js` |
| Adding a new Rails controller endpoint for "load column N" | Unnecessary; existing per-gadget endpoints already serve HTML fragments | Reuse existing gadget AJAX endpoints; just defer when they fire |
| `MutationObserver` on the portal to detect class changes | Fragile; depends on CSS class naming; more complex than hooking `activateColumn` directly | Hook inside `activateColumn` in `portal_mobile_tabs.js` |

---

## Integration Map: Existing Code Touch Points

| File | Change Required | Nature |
|------|----------------|--------|
| `app/assets/javascripts/portal_mobile_tabs.js` | Add `loadColumn` function; call it from `activateColumn` and page-init | New function + 2 call sites |
| `app/views/welcome/_feed.html.erb` | Replace `$(document).ready($.get(...))` with function-registration pattern | Refactor |
| `app/views/welcome/_mastodon_account.html.erb` | Same | Refactor |
| `app/views/welcome/_x_account.html.erb` | Same | Refactor |
| `app/views/welcome/_calendar_gadget.html.erb` | Same | Refactor |
| `app/views/welcome/_bookmark_gadget.html.erb` | No change — bookmark gadget is SSR, no AJAX | None |
| `app/views/welcome/_todo_gadget.html.erb` | No change — check for AJAX; likely SSR | Verify |
| `app/views/welcome/_note_gadget.html.erb` | No change — SSR only | None |

**SSR gadgets (bookmark, todo, note) need no lazy-loading treatment** — their
content is rendered inline by ERB at page load. Only the AJAX-fetching gadgets
(feed, mastodon_account, x_account, calendar) need the deferred-loader pattern.

---

## jQuery 4 Compatibility Verification

All APIs used in this pattern are jQuery core:

| API Used | Since jQuery | Status in jQuery 4 |
|----------|-------------|---------------------|
| `$.data(element, key, value)` | 1.2 | Stable; unchanged |
| `$(el).data(key)` / `.data(key, val)` | 1.2 | Stable; unchanged |
| `$(el).find(selector)` | 1.0 | Stable; unchanged |
| `$(el).each(fn)` | 1.0 | Stable; unchanged |
| `$.get(url, data, callback)` | 1.0 | Stable; unchanged |
| `$(fn)` shorthand for `$(document).ready` | 1.0 | Stable; unchanged |
| `.attr(name)` / `.attr(name, val)` | 1.0 | Stable; unchanged |
| `.toggleClass(cls, bool)` | 1.3 | Stable; unchanged |

**jQuery 4 breaking changes relevant here:** None. jQuery 4's primary breaks are
around `$.ajax` promise compatibility (Thenables vs jQuery Deferreds) and removal
of legacy methods (`$.fn.size`, `$.isFunction`, etc.). None of those APIs are
used in the lazy-loader pattern. The `$.get()` shorthand is unaffected.

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| jQuery `.data()` sentinel as "loaded" flag | HIGH | Verified jQuery docs; this is the canonical jQuery pattern for page-session state. jQuery-rails 4.6.1 is already locked. |
| `activateColumn` as integration point | HIGH | Read `portal_mobile_tabs.js` in full — `activateColumn` is already called from all three activation paths (click, swipe, localStorage restore). Adding one line there covers all paths. |
| Function-registration via `data('gadget-loader')` | HIGH | Standard jQuery data cache pattern; used throughout the ecosystem for deferred initialization. |
| No new library needed | HIGH | The "lazy load once on tab switch" problem is simpler than scroll-based lazy loading. The trigger is an explicit function call, not an observer. Five lines of jQuery is the right solution. |
| Desktop behavior unchanged | HIGH | The coordinator fires `loadColumn` for all columns on non-mobile viewport. This is functionally identical to today's per-gadget `$(document).ready` firing. |
| SSR gadgets (bookmark, todo, note) exempt | HIGH | Confirmed by reading all gadget partials — these three have no `$.get()` calls. No lazy-loading concern. |

---

## Sources

- In-repo source read directly:
  - `app/assets/javascripts/portal_mobile_tabs.js` — full read; `activateColumn` integration point confirmed
  - `app/views/welcome/_feed.html.erb` — current `$(document).ready` AJAX pattern confirmed
  - `app/views/welcome/_mastodon_account.html.erb` — same pattern confirmed
  - `app/views/welcome/_x_account.html.erb` — same pattern confirmed
  - `app/views/welcome/_calendar_gadget.html.erb` — same pattern confirmed
  - `app/views/welcome/_bookmark_gadget.html.erb` — SSR confirmed (no AJAX)
  - `app/views/welcome/_portal_column_section.html.erb` — column structure confirmed (`#column_N` IDs)
  - `app/assets/javascripts/application.js` — Sprockets manifest; `require jquery` confirmed
  - `.planning/PROJECT.md` — constraint "no new npm deps" confirmed; jQuery 4.6.1 confirmed
- jQuery API documentation (api.jquery.com) — `.data()`, `$.get()`, `$(fn)` APIs confirmed stable since jQuery 1.x, unchanged in jQuery 4

---

*Stack research for: v1.24 Mobile Column Lazy Loading*
*Researched: 2026-05-17*
