# Pattern map — Phase 3 (modernize-application-scripts)

**Purpose:** For each file touched, the closest in-repo pattern and what to copy.

| Target file (create/modify) | Role | Closest analog | Pattern to follow |
|----------------------------|------|--------------|-------------------|
| `app/assets/javascripts/todos.js` | Namespace + UJS / delegate | `app/assets/javascripts/feeds.js` | jQuery `$.get`/`$.post` with `function` callbacks; local `const` for DOM refs |
| `app/assets/javascripts/feeds.js` | Namespace + `serializeArray` loop | `app/assets/javascripts/calendars.js` | Top-level object + methods; replace `var` with `const`/`let` |
| `app/assets/javascripts/calendars.js` | Simple GET + DOM replace | `app/assets/javascripts/bookmarks.js` (AJAX) | `$.get` + `function(html)` — no `this` in callback → arrow allowed |
| `app/assets/javascripts/bookmark_gadget.js` | `$(document).ready` + `localStorage` | `app/assets/javascripts/bookmarks.js` | Ready wrapper; **handlers using `this`** stay `function` not `=>` |
| `app/assets/javascripts/bookmarks.js` | Delegated `blur` + `$.get` | Phase 2 style in same file | Outer handler `function` for `$(this)`; `.done` can use arrow |
| `app/assets/javascripts/cable.js` | IIFE + `ActionCable` | Official Rails `rails new` cable stub | **Do not** swap IIFE to arrow (preserves `this` binding) |
| `.planning/codebase/CONVENTIONS.md` | Document STYL-02 | `.planning/phases/03-modernize-application-scripts/03-CONTEXT.md` D-04–D-07 | Short standalone subsection, link from Overview |

**Code excerpt (jQuery + `this` — must not use arrow for handler):**

```5:7:app/assets/javascripts/bookmark_gadget.js
  $('.folder-header').on('click', function() {
    var $header = $(this);
```

**Code excerpt (arrow OK — no jQuery `this` in body):**

```8:10:app/assets/javascripts/bookmarks.js
    $.get('/bookmarks/fetch_title', { url: urlValue })
      .done(function(title) {
        title = $.trim(title);
```

(Inner could be `((title) => { ... })` per `03-CONTEXT` D-06; executor choice as long as lint passes.)

## PATTERN MAPPING COMPLETE
