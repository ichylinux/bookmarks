# Phase 5: Theme Foundation - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 3 (1 modified, 2 new)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `app/views/preferences/index.html.erb` | view (form) | request-response | `app/views/preferences/index.html.erb` itself (one-line edit) | exact |
| `app/assets/stylesheets/themes/modern.css.scss` | stylesheet (theme) | transform | `app/assets/stylesheets/themes/simple.css.scss` | exact |
| `app/assets/javascripts/menu.js` | javascript (feature stub) | event-driven | `app/assets/javascripts/bookmarks.js` | role-match |

---

## Pattern Assignments

### `app/views/preferences/index.html.erb` (view, request-response)

**Change type:** One-line edit — add `'モダン' => 'modern'` to the existing `f.select :theme` hash.

**Analog:** `app/views/preferences/index.html.erb` line 15 (the line being edited)

**Existing line** (`app/views/preferences/index.html.erb`, line 15):
```erb
<%= f.select :theme, {'シンプル' => 'simple'}, include_blank: 'デフォルト' %>
```

**Target line after edit:**
```erb
<%= f.select :theme, {'シンプル' => 'simple', 'モダン' => 'modern'}, include_blank: 'デフォルト' %>
```

**Pattern rules:**
- Hash key is the Japanese display label (string), hash value is the CSS body-class string.
- `include_blank:` value `'デフォルト'` is unchanged — it is the existing blank/default option.
- No other lines in this file change.

---

### `app/assets/stylesheets/themes/modern.css.scss` (stylesheet, transform)

**Analog:** `app/assets/stylesheets/themes/simple.css.scss` (entire file, 23 lines)

**Analog file content** (`app/assets/stylesheets/themes/simple.css.scss`, lines 1-23):
```scss
.simple {
  #header {
    display: none;
  }
}

.simple {
  .wrapper {
    padding: 0 10px 10px 10px;
  }
}
@media (max-width: 480px) {
.wrapper {
  padding: 0 10px 10px 10px;
}
}

@media (min-width: 481px) and (max-width: 768px) {
.wrapper {
  padding: 0 10px 10px 10px;
}
}
```

**Pattern rules for `modern.css.scss`:**
- Root scope is `.modern {}`, mirroring `.simple {}` in the analog.
- Phase 5 contains only CSS custom property tokens as direct children of `.modern {}` — no nested selectors, no media queries in this stub.
- All token values are plain CSS hex strings. No `$variable` references (libsass does not compile SCSS variable references inside CSS custom property values correctly).
- CSS custom property prefix is `--modern-` per D-01, even though the properties are already scoped inside `.modern {}`.

**Target file content:**
```scss
.modern {
  --modern-color-primary: #3b82f6;
  --modern-bg:            #ffffff;
  --modern-text:          #1a1a1a;
  --modern-header-bg:     #1e40af;
}
```

**Asset pipeline note:** `app/assets/stylesheets/application.css` uses `*= require_tree .` (line 14). Any `.scss` file placed under `stylesheets/` (including the `themes/` subdirectory) is auto-compiled and included. No manifest change is needed.

---

### `app/assets/javascripts/menu.js` (javascript stub, event-driven)

**Analog:** `app/assets/javascripts/bookmarks.js` (entire file, 23 lines) — best match for the `$(function() {...})` / `$(document).ready(...)` DOM-ready wrapper pattern used when there is no shared window namespace needed.

**Secondary analog for `$(function(){})` style reference:** `app/assets/javascripts/todos.js` and `feeds.js` use a namespace object pattern (`window.X = window.X || {}`) which is NOT appropriate for `menu.js` — the menu module does not expose a shared API to other files.

**Analog file content** (`app/assets/javascripts/bookmarks.js`, lines 1-23):
```js
$(document).ready(() => {
  $(document).on('blur', '#bookmark_url', function() {
    const urlValue = $.trim($(this).val());
    if (urlValue === '') {
      return;
    }
    // ... rest of handler
  });
});
```

**Pattern rules for `menu.js`:**
- Use `$(function() { ... })` — the shorthand for `$(document).ready(...)`. Both forms are present in the codebase; `$(function(){})` is the canonical shorthand per jQuery convention and is what the UI-SPEC.md contract specifies.
- Guard is the **first statement** inside the DOM-ready callback: `if (!$('body').hasClass('modern')) return;`
- When `body` does not have class `modern`, the function exits immediately with zero side effects.
- No `window.menu` namespace — this file will eventually hold drawer interaction logic that is local to the page, not a shared utility API.
- `const`/`let` only — `var` is forbidden per CONVENTIONS.md (ESLint `no-var` rule is enforced; violations require `eslint-disable-next-line` plus a justification comment).
- Arrow functions are permitted in short callbacks that do not reference `this`; `function` keyword is required where `$(this)` is used inside `.each` or event handlers.

**Target file content:**
```js
$(function() {
  if (!$('body').hasClass('modern')) return;
  // Drawer interaction logic added in Phase 8.
});
```

**Asset pipeline note:** `app/assets/javascripts/application.js` uses `//= require_tree .` (line 17). Any `.js` file placed under `javascripts/` is auto-compiled and included. No manifest change is needed.

---

## Shared Patterns

### Body-class theme activation
**Source:** `app/views/layouts/application.html.erb` — `<body class="<%= favorite_theme %>">` applies the `preference.theme` string as the body class.
**Source:** `app/helpers/welcome_helper.rb` — `favorite_theme` helper returns `preference.theme`.
**Apply to:** Both `modern.css.scss` (scoped under `.modern {}`) and `menu.js` (guard checks `$('body').hasClass('modern')`).
**No changes needed** to these files — `modern` activates automatically once it is stored as the user's preference value.

### Asset auto-inclusion via `require_tree .`
**Source (CSS):** `app/assets/stylesheets/application.css` line 14 — `*= require_tree .`
**Source (JS):** `app/assets/javascripts/application.js` line 17 — `//= require_tree .`
**Apply to:** Both new asset files. Drop into the correct directory; Sprockets picks them up with no manifest change.

### Select hash pattern (preferences form)
**Source:** `app/views/preferences/index.html.erb` line 15
**Apply to:** The one-line edit to `preferences/index.html.erb`. The hash `{'シンプル' => 'simple'}` is extended in-place — Japanese label as key, CSS body-class value as value, `include_blank: 'デフォルト'` remains.

---

## No Analog Found

None. All three files have clear analogs in the codebase.

---

## Metadata

**Analog search scope:** `app/assets/stylesheets/`, `app/assets/javascripts/`, `app/views/preferences/`
**Files scanned:** 10
**Pattern extraction date:** 2026-04-28
