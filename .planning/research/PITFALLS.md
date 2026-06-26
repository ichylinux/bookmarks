# Pitfalls Research

**Domain:** Mobile-friendly inline form in jQuery + SCSS + Sprockets Rails app (v1.37.0)
**Researched:** 2026-06-26
**Confidence:** MEDIUM — web research cross-checked against direct codebase reading

---

## Critical Pitfalls

### Pitfall 1: Dart Sass Misparses Bare `min()` / `max()` / `clamp()` as Sass Functions

**What goes wrong:**
Writing `width: min(100%, 400px)` or `max(200px, 50%)` directly in a `.scss` file causes a `SassError: 200px and 50% are incompatible` compile error during Sprockets asset bundling. The form layout never renders — asset compilation fails silently or with a stack trace in the log.

**Why it happens:**
Dart Sass has its own `min()` and `max()` built-in functions that predate the CSS math functions of the same name. Sass tries to evaluate `min(100%, 400px)` as a Sass function call. Mixing `%` and `px` units inside a Sass function is an error (Sass has no concept of CSS viewport-relative arithmetic). This is not a new issue — the project already fixed `max(100%, min-content)` in `feeds.css.scss` during v1.18 (PROJECT.md Key Decisions: "CSS `max(100%, min-content)` to `width: 100%`").

**How to avoid:**
Never use bare `min()`, `max()`, or `clamp()` in `.scss` files. Use `calc()` wrapping instead — Sass does not recurse into `calc()` arguments:

```scss
// WRONG — Sass parses this as a Sass function call:
width: min(100%, 400px);

// CORRECT — Sass treats the whole thing as a calc() CSS expression:
width: calc(min(100%, 400px));

// ALSO CORRECT — interpolation escapes Sass parsing:
width: #{min(100%, 400px)};

// SIMPLEST — avoid the function entirely if possible:
width: 100%;
max-width: 400px;
```

The project convention (established in v1.18) is to use `width: 100%` rather than `max(100%, min-content)`. Follow the same pattern for the mobile form.

**Warning signs:**
- `bin/rails test` prints a Sass compilation error for `todos.css.scss` or `application.css.scss`
- New CSS works in browser dev tools (pure CSS evaluation) but the compiled asset crashes in tests
- Error message contains "incompatible units" or "expected a number"

**Phase to address:** CSS layout phase (whichever phase touches `todos.css.scss` for mobile breakpoint rules)

---

### Pitfall 2: iOS Safari Silently Ignores `.focus()` Called in AJAX Callback

**What goes wrong:**
Adding `$('input[type="text"]').focus()` inside the `todos.new_todo()` AJAX success callback to auto-open the mobile keyboard has no effect on iOS Safari. The form appears but the keyboard never opens. The user must tap the field manually, and on a narrow screen the form may be off-screen (since `ol.prepend()` places it at the top of the list).

**Why it happens:**
iOS Safari only allows programmatic keyboard activation when `.focus()` is called synchronously inside a user-gesture event handler (click, touchend). The `$.get()` success callback is async — it executes outside the original gesture context. Apple's WebKit blocks keyboard popups from async code by design; this cannot be overridden. Current `todos.new_todo()` code:

```js
$.get(url, {format: 'html'}, function(html) {
  ol.prepend('<li>' + html + '</li>');
  // Adding .focus() HERE has no effect on iOS Safari
});
```

**How to avoid:**
Do not attempt to auto-focus. Instead, scroll the injected form into view so the user can see it and tap the field:

```js
$.get(url, {format: 'html'}, function(html) {
  const $li = $('<li>' + html + '</li>');
  ol.prepend($li);
  $li[0].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
});
```

If auto-focus is a hard requirement, the form must be pre-rendered server-side (hidden) and shown synchronously on tap — not loaded via AJAX. This is a significant redesign and should be deferred.

**Warning signs:**
- Mobile test passes in headless Chrome (Chrome does not enforce the same restriction) but fails on a real iOS device
- Form appears at top of list but keyboard never opens on iPhone or iPad
- Android Chrome may auto-focus successfully, masking the iOS-specific bug

**Phase to address:** JS behavior phase (whichever phase wires the "追加" link to `todos.new_todo()`)

---

## Moderate Pitfalls

### Pitfall 3: Media-Query Rules That Revert Table Display Break the Existing Flex Layout

**What goes wrong:**
The existing `todos.css.scss` already overrides `table.todo-form` to use flexbox:

```scss
form.todo table.todo-form {
  display: block;
  tbody { display: block; }
  tr { display: flex; flex-wrap: nowrap; align-items: center; }
  td { display: block; }
}
```

A common mistake when adding mobile rules is writing a `@media (max-width: 767px)` block that restores table semantics (`display: table-row`, `display: table-cell`) thinking the table needs its "natural" behavior for mobile stacking. This silently overwrites the flex layout and the form collapses — the priority select and title input overlap or fall outside the gadget boundary.

**Why it happens:**
Developers see `<table class="todo-form">` in `_form.html.erb` and assume the table needs to be "un-done" for mobile stacking. The flex override is applied at all times (not just desktop), which is non-obvious.

**How to avoid:**
Only ADD to the existing flex behavior inside mobile media queries. Never change `display` values back to `table`, `table-row`, or `table-cell`:

```scss
@media (max-width: 767px) {
  form.todo table.todo-form tr {
    flex-wrap: wrap; // Allow wrapping — do NOT use display: table-row
  }
  form.todo table.todo-form td:nth-child(2) {
    flex: 1 1 100%; // Title takes full width on its own row
  }
}
```

**Warning signs:**
- Priority select and title input overlap on desktop after adding mobile styles
- Submit button pushed outside the `.gadget` div (overflow: hidden clips it)
- Form layout looks broken at 1280px but fine at 390px (reverse of the expected failure direction)

**Phase to address:** CSS layout phase

---

### Pitfall 4: Gadget-Scoped Mobile CSS Breaks the Standalone `/todos/new` Page

**What goes wrong:**
If mobile CSS uses `.gadget.todo form.todo` or `#todo form.todo` selectors, the standalone `/todos/new` page does not receive the fix. Mobile users on `/todos/new` still see the broken layout. Conversely, if the selector is overly broad and targets form structure inside the standalone page's different surrounding layout, unintended visual side effects appear there.

**Why it happens:**
`_form.html.erb` is a shared partial used in two distinct contexts:
1. Inline gadget: form is prepended into a `li` inside `#todo ol` via `todos.new_todo()`
2. Standalone page: `/todos/new` renders the partial with a different surrounding layout

**How to avoid:**
Use `form.todo` as the base selector (without gadget scoping) for mobile layout rules so both contexts benefit. If context-specific overrides are needed, use explicit selectors and test both:

```scss
// Applies to both gadget and /todos/new — safe default
@media (max-width: 767px) {
  form.todo table.todo-form { ... }
}

// Gadget-only override if needed
@media (max-width: 767px) {
  .gadget.todo form.todo { ... }
}
```

**Warning signs:**
- Gadget form looks correct on mobile but `/todos/new` wraps or overflows when visited directly
- Minitest integration test for `GET /todos/new` on narrow viewport fails while Cucumber gadget test passes

**Phase to address:** CSS layout phase

---

### Pitfall 5: Double-Tap Edit Fires if "追加" Link Is Placed Inside a List Item

**What goes wrong:**
The double-tap detection in `todos.js` uses `lastTapAt` stored on each `li` via `.data()`. The `touchend` handler fires when any part of the `li` is tapped. If the "追加" trigger is placed inside an `li` element in the todo list `ol`, tapping it once sets `lastTapAt` on that `li`. A second tap on the same `li` within 350ms fires `open_edit()` — but the user intended to add a new todo, not edit an existing one.

The existing `stopPropagation` on `touchstart` for `.todo-gadget-new-link`:

```js
$(selector).on('mousedown touchstart', '.todo-gadget-new-link, ...', function(e) {
  e.stopPropagation();
});
```

This does NOT prevent `touchend` from bubbling. The double-tap detection lives on `touchend`, not `touchstart`.

**How to avoid:**
Place the "追加" link in the gadget header (the same row as `.todo-gadget-new-link` / `.todo-gadget-complete-group`), not inside any `li` in the `ol`. This is the current location of "新規" and is safe — the header is not inside a `.todo li`.

If a link inside the list area is ever needed, add a `touchend` guard:

```js
$(selector).on('touchend', 'li', function(e) {
  if ($(e.target).closest('.todo-gadget-new-link').length) return;
  // ... existing double-tap logic
});
```

**Warning signs:**
- Tapping "追加" on mobile occasionally opens an edit form for the first todo item instead of the add form
- The edit form appears on the wrong `li` after a fast tap sequence

**Phase to address:** JS behavior phase (if link placement changes from the gadget header)

---

### Pitfall 6: Cucumber `@mobile_portal` Scenario Is Hollow Without Calling `ensure_mobile_viewport!`

**What goes wrong:**
Adding `@mobile_portal` to a todo scenario in `02.タスク.feature` tags the scenario but does NOT automatically resize the browser. The `Before('@mobile_portal')` hook only sets `@mobile_portal_scenario = true`. The actual 390x844 resize happens inside `ensure_mobile_viewport!`, which must be called explicitly from a step definition before `visit root_path`. Without this call, the browser stays at 1280x800 and CSS media queries (`max-width: 767px`) never activate. The scenario passes but provides zero mobile layout coverage.

From `features/support/window_resize.rb`:

```ruby
Before('@mobile_portal') do
  @mobile_portal_scenario = true  # Only sets a flag — no resize here
end

def ensure_mobile_viewport!
  return unless @mobile_portal_scenario
  resize_browser_window(390, 844)  # Must be called before visit
end
```

Existing usage in `features/step_definitions/modern_theme.rb` confirms the required pattern — `ensure_mobile_viewport!` is called inside the step that navigates to root, not in the hook.

**How to avoid:**
In every step definition that navigates to the portal under `@mobile_portal`, call `ensure_mobile_viewport!` before `visit root_path`:

```ruby
もし /^モバイルでポータルを開きます。$/ do
  ensure_mobile_viewport!
  visit root_path
  capture
end
```

The `After('@mobile_portal')` cleanup that resets to 1280x800 already exists in `window_resize.rb` and runs automatically.

**Warning signs:**
- New `@mobile_portal` scenario is added to `02.タスク.feature` but no step definition calls `ensure_mobile_viewport!`
- The scenario passes at the same green rate as existing desktop todo scenarios (no layout difference)
- Cucumber screenshots show a full-width 1280px portal, not a stacked mobile view

**Phase to address:** Test coverage phase (whichever phase adds Cucumber mobile scenarios for the todo form)

---

## Minor Pitfalls

### Pitfall 7: English Locale Priority Column Overflows Narrowest Viewports

**What goes wrong:**
The English locale overrides the priority column width to `$todo-priority-width-en: 4.5em` (vs `$todo-priority-width: 3.5em` for Japanese). On very narrow viewports (iPhone SE: 320px) in English locale, the fixed `4.5em` priority column combined with the submit button text ("Update" is wider than "登録") may leave the title input with insufficient usable width or overflow the gadget container.

The current SCSS:

```scss
html:lang(en) .todo {
  form.todo table.todo-form td:first-child {
    width: $todo-priority-width-en; // 4.5em — fixed even on mobile
    select { width: auto; }
  }
}
```

**How to avoid:**
Add a media query that reduces the priority column width on very narrow screens:

```scss
@media (max-width: 400px) {
  html:lang(en) .todo form.todo table.todo-form td:first-child {
    width: $todo-priority-width; // Fall back to 3.5em on narrowest screens
    select { width: 100%; }
  }
}
```

**Phase to address:** CSS layout phase (verify at 320px in English locale)

---

### Pitfall 8: `portal_mobile_tabs.js` Scroll Stickiness May Hide the Injected Form

**What goes wrong:**
The known scroll stickiness issue in `portal_mobile_tabs.js` affects mobile column tab navigation. When `todos.new_todo()` prepends a new `li` at the top of the `ol`, if the todo gadget's column is not the currently visible tab, or if the scroll position is stuck, the injected form appears off-screen. The user gets no visual feedback that the form was added.

**How to avoid:**
The `scrollIntoView` call recommended in Pitfall 2 mitigates this. Additionally, verify that tapping "追加" when the todo column is not the active mobile tab either switches to the todo column first or gives appropriate feedback. This is low risk for the initial implementation — address if observed during manual testing.

**Phase to address:** JS behavior phase (check during mobile smoke testing)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip `scrollIntoView` after AJAX prepend | Less JS code | Form injected off-screen; user confused on narrow screens | Never — two-line fix |
| Scope mobile CSS only to `.gadget.todo` | Avoids touching standalone page layout | `/todos/new` broken on mobile | Never — use `form.todo` selector |
| Add `@mobile_portal` Cucumber tag without `ensure_mobile_viewport!` | Scenario appears green | Zero actual mobile layout coverage | Never — hollow test gives false confidence |
| Bare `min()`/`max()` in SCSS without `calc()` | Expressive CSS syntax | SassError kills asset compilation | Never — use `calc(min(...))` or width + max-width |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Dart Sass + Sprockets | Bare `min()`/`max()`/`clamp()` in `.scss` | Wrap in `calc()` or use `width` + `max-width` properties |
| iOS Safari + jQuery AJAX | `.focus()` in `$.get()` success callback | `scrollIntoView()` in callback; no auto-focus |
| Capybara `@mobile_portal` tag | Tag only, no `ensure_mobile_viewport!` call | Call `ensure_mobile_viewport!` in the nav step before `visit` |
| Shared `_form.html.erb` | Gadget-only CSS selector misses `/todos/new` | Use `form.todo` selector; verify standalone page on mobile |

---

## "Looks Done But Isn't" Checklist

- [ ] **Dart Sass CSS functions:** No bare `min()`/`max()`/`clamp()` in `todos.css.scss` — run `bin/rails test` and confirm no SassError
- [ ] **iOS keyboard:** Tested on a real iOS device or BrowserStack (headless Chrome does not reproduce the async focus restriction)
- [ ] **Desktop layout unchanged:** Form at 1280x800 still shows priority select + title input + submit button on one line with no wrapping
- [ ] **Standalone `/todos/new` works on mobile:** Visit `/todos/new` at 390px; form is usable without horizontal overflow
- [ ] **Double-tap still works:** Double-tapping an existing todo item on mobile still opens the edit form; no regression
- [ ] **`@mobile_portal` scenario actually at 390px:** Cucumber screenshot shows mobile-width layout, not desktop-width
- [ ] **English locale at 320px:** Priority select does not overflow the gadget in `lang(en)` on narrowest screens

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Dart Sass SassError in production build | HIGH | Revert the offending SCSS line immediately; replace with `calc()` equivalent; recompile |
| iOS keyboard not opening | LOW | Remove `.focus()` call from AJAX callback; add `scrollIntoView()` instead |
| Desktop layout broken by mobile CSS | MEDIUM | Add `@media` scope to mobile rules; audit selector conflicts with existing flex overrides |
| Hollow `@mobile_portal` Cucumber scenario | LOW | Add `ensure_mobile_viewport!` call to the step that navigates to portal before `visit` |
| Standalone `/todos/new` broken on mobile | LOW | Broaden selector from `.gadget.todo form.todo` to `form.todo`; rerun tests |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Dart Sass CSS function misparse | CSS layout phase | `bin/rails test` must pass with no SassError; check Sprockets compilation output |
| iOS Safari async focus() ignored | JS behavior phase | Manual smoke test on iOS device after wiring "追加" link |
| Table display revert in media query | CSS layout phase | Desktop layout unchanged at 1280x800; existing Cucumber suite stays green |
| Shared partial breaks standalone page | CSS layout phase | Visit `/todos/new` at 390px viewport; verify form is usable |
| Double-tap edit regression | JS behavior phase | Existing `02.タスク.feature` must stay green; smoke-test double-tap on mobile |
| Hollow mobile Cucumber scenario | Test coverage phase | Cucumber report screenshot shows 390px-width layout, not 1280px |
| English locale overflow on narrow screens | CSS layout phase | Test `html:lang(en)` at 320px viewport (iPhone SE width) |
| Portal tab hiding injected form | JS behavior phase | Manual check: tap "追加" from a non-todo tab; form becomes visible |

---

## Sources

- Project codebase direct reading: `app/assets/stylesheets/todos.css.scss`, `app/assets/javascripts/todos.js`, `app/views/todos/_form.html.erb`, `features/support/window_resize.rb`, `features/step_definitions/todos.rb`, `features/support/hooks.rb`
- PROJECT.md Key Decisions: v1.18 Dart Sass `max()` fix in `feeds.css.scss` (confirmed project precedent)
- [When Sass and New CSS Features Collide | CSS-Tricks](https://css-tricks.com/when-sass-and-new-css-features-collide/)
- [Dart Sass: Special Functions](https://sass-lang.com/documentation/syntax/special-functions/)
- [CSS min() and max() re-introduced · sass/sass#2378](https://github.com/sass/sass/issues/2378)
- [(Sort of) Fixing autofocus in iOS Safari | Tommy Brunn, Medium](https://medium.com/@brunn/autofocus-in-ios-safari-458215514a5f)
- [iOS Keyboard Not Showing on Input.focus() | xjavascript.com](https://www.xjavascript.com/blog/ios-show-keyboard-on-input-focus/)
- [How to specify size of Selenium browser window | makandra dev](https://makandracards.com/makandra/9773-how-to-specify-size-of-selenium-browser-window)
- Confidence: MEDIUM (web research cross-checked against direct codebase reading; project-specific pitfalls derived from codebase are HIGH confidence)

---
*Pitfalls research for: mobile-friendly inline todo add form (v1.37.0)*
*Researched: 2026-06-26*
