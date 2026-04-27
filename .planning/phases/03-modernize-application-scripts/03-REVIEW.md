---
phase: 03-modernize-application-scripts
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - app/assets/javascripts/bookmark_gadget.js
  - app/assets/javascripts/bookmarks.js
  - app/assets/javascripts/calendars.js
  - app/assets/javascripts/feeds.js
  - app/assets/javascripts/todos.js
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five Sprockets-bundled JavaScript files were reviewed after a modernization pass that replaced `var` with `const`/`let`, migrated `$(document).ready` wrappers to arrow functions, and added `window.*` namespace comments. The `var`-to-`const/let` conversion is complete with no regressions on that front. Arrow-vs-`function` decisions for jQuery `this`-using handlers are correct throughout.

Four issues pre-date this phase but remain unfixed and are reported here because they represent real defects in the submitted state of the files. One new bug was introduced by the phase itself: the `const` alias pattern for `window.*` globals creates a module-level `const` that shadows the global in the same file, which is fine by itself, but the pattern is inconsistently applied — `calendars.js`, `feeds.js`, and `todos.js` use it, while `bookmark_gadget.js` and `bookmarks.js` do not. More critically, the `const` aliases are file-local; any other file that writes to `window.feeds` after `feeds.js` runs will not be seen through the alias, which is a latent correctness risk as the codebase grows.

---

## Critical Issues

### CR-01: `JSON.parse` on untrusted `localStorage` value throws uncaught exception

**File:** `app/assets/javascripts/bookmark_gadget.js:8`

**Issue:** `getExpandedFolders()` calls `JSON.parse(stored)` with no `try/catch`. `localStorage` is writable by any script running on the same origin (extensions, injected scripts, prior bugs). If the stored string is not valid JSON, `JSON.parse` throws a `SyntaxError` that propagates uncaught through the `$(document).ready` callback, aborting execution of every subsequent line in the ready block — including all `$('.folder-header').on('click', ...)` registration. The result is a silently broken page with no folder toggle functionality.

**Fix:**
```javascript
function getExpandedFolders() {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) return [];
  try {
    const parsed = JSON.parse(stored);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_e) {
    return [];
  }
}
```

---

## Warnings

### WR-01: `$.delegate()` is removed in jQuery 3 — runtime error on upgrade

**File:** `app/assets/javascripts/todos.js:6`, `app/assets/javascripts/todos.js:22`

**Issue:** `$(selector).delegate(childSelector, event, handler)` was deprecated in jQuery 1.7 and **removed entirely in jQuery 3.0**. If the application ever moves from jQuery 1.x/2.x to 3.x, both `todos.init` calls will throw `TypeError: $(…).delegate is not a function`, silently breaking all todo interaction. The phase replaced `var` throughout `todos.js` but left the deprecated API intact. The preferred replacement has been available since jQuery 1.7.

**Fix:** Replace both `.delegate()` calls with `.on()`:
```javascript
// Line 6: was $(selector).delegate('li', 'dblclick', function() {
$(selector).on('dblclick', 'li', function() {

// Line 22: was $(selector).delegate('li span:first-child', 'click', function() {
$(selector).on('click', 'li span:first-child', function() {
```

---

### WR-02: `feeds.js` sets `params[i].value = null` — sends literal string `"null"` in POST body

**File:** `app/assets/javascripts/feeds.js:17`

**Issue:** `serializeArray()` returns an array of `{name, value}` objects where `value` is always a string. Setting `params[i].value = null` and then passing the array to `$.post()` causes jQuery's `$.param()` to serialize the entry as `id=` (an empty string), not to omit the key. This is fragile: the intent appears to be "send this as a new-record POST without an id," but the behavior depends on undocumented jQuery internals for `null` coercion. A future jQuery version could change this to the string `"null"` or omit the key entirely. The server-side `get_feed_title` action builds `Feed.new(feed_params)` and does not use `id` directly, so there is no immediate crash, but the intent is unclear and the behavior is not guaranteed.

**Fix:** Set the value to an empty string to make the intent explicit and unambiguous:
```javascript
if (params[i].name == 'id') {
  params[i].value = '';  // omit id so server treats this as a new record
}
```

---

### WR-03: Loose equality `==` used for string comparisons throughout `feeds.js`

**File:** `app/assets/javascripts/feeds.js:9`, `16`, `18`, `24`

**Issue:** Four comparisons use `==` instead of `===`. While all comparands are strings in practice (`.val()` returns a string, `serializeArray` name/value are strings, `$.trim()` returns a string), `==` performs type coercion and is flagged as an error by most linters. The same file introduced `const`/`let` in this phase but did not apply strict equality. `bookmarks.js`, `bookmark_gadget.js`, and `calendars.js` all use `===` consistently, making `feeds.js` an outlier that will fail any future ESLint `eqeqeq` rule enforcement.

**Fix:** Replace all four `==` comparisons with `===`:
```javascript
if (url === '') {                      // line 9
if (params[i].name === 'id') {        // line 16
} else if (params[i].name === '_method') {  // line 18
if ($.trim(title) === '') {           // line 24
```

---

### WR-04: `const` alias of `window.*` namespace severs live reference

**File:** `app/assets/javascripts/calendars.js:3`, `app/assets/javascripts/feeds.js:3`, `app/assets/javascripts/todos.js:3`

**Issue:** Each namespace file does:
```javascript
window.feeds = window.feeds || {};
const feeds = window.feeds;
```
The local `const feeds` is a snapshot of the object reference at file-parse time. If any code later **replaces** `window.feeds` with a new object (e.g., `window.feeds = { … }` in another file or a hot-reload scenario), the local `const` continues pointing to the old stale object, while external callers using `window.feeds` see the new one. Methods added via the local alias after that reassignment are lost from the global. This pattern is safe today because no other file replaces these globals, but it is a structural trap. The comment says "no new globals" but the `const` aliases are undocumented and may confuse future maintainers into thinking the aliases and `window.*` are always in sync.

**Fix:** Either use `window.feeds.get_feed_title = function(…)` directly (no local alias), or document the alias explicitly and add a linter rule that prohibits `window.feeds = …` reassignment elsewhere.

---

## Info

### IN-01: `bookmark_gadget.js` `expandFolder` does not update the collapse indicator on cold-restore

**File:** `app/assets/javascripts/bookmark_gadget.js:17-26`

**Issue:** `expandFolder()` sets `$toggle.text('▼')` only when `!$bookmarks.is(':visible')`. On a fresh page load, all folders start hidden, so the toggle text update fires correctly. However, if the initial HTML renders a folder as visible (e.g., a server-side default state), `expandFolder` will skip the `▼` update, leaving the toggle icon in whatever state the HTML has. This is a minor edge case dependent on initial HTML state, not a regression from this phase.

**Fix:** Unconditionally set the toggle text in `expandFolder` regardless of current visibility:
```javascript
function expandFolder(folderId) {
  const $bookmarks = $('#folder-' + folderId);
  const $header = $('.folder-header[data-folder-id="' + folderId + '"]');
  const $toggle = $header.find('.folder-toggle');

  $bookmarks.show();
  $toggle.text('▼');
}
```

---

### IN-02: `forEach` with named `function` expression at line 30 of `bookmark_gadget.js` is inconsistent with the phase's arrow-function migration

**File:** `app/assets/javascripts/bookmark_gadget.js:30`

**Issue:**
```javascript
expandedFolders.forEach(function(folderId) {
  expandFolder(folderId);
});
```
This callback does not use `this` and is a pure iteration callback — exactly the case the phase targeted for arrow conversion. All other non-`this` callbacks in the file and in `bookmarks.js` were converted. This one was missed.

**Fix:**
```javascript
expandedFolders.forEach((folderId) => {
  expandFolder(folderId);
});
```
Or more concisely: `expandedFolders.forEach(expandFolder);`

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
