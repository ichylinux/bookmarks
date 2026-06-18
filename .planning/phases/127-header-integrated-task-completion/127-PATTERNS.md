# Phase 127: Header-Integrated Task Completion - Pattern Map

**Mapped:** 2026-06-18
**Files analyzed:** 8 (modified) + 1 (removed)
**Analogs found:** 8 / 8 (all files are existing files being modified; analogs are the files themselves plus sibling patterns)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `app/views/welcome/_todo_gadget.html.erb` | view/partial | request-response (SSR) | `app/views/common/_gadget_title_with_icon.html.erb` (local-slot pattern) | exact |
| `app/views/common/_gadget_title_with_icon.html.erb` | view/partial | request-response (SSR) | itself — add optional `complete_group:` local slot mirroring existing `header_link:` | exact |
| `app/views/todos/_actions.html.erb` | view/partial | — | — (file to be REMOVED from render call; file left as dead code or deleted) | n/a |
| `app/assets/javascripts/todos.js` | utility/JS namespace | event-driven (jQuery) | `todos.toggle_highlight` (CSRF from meta tag); `todos.new_todo` (closest-ol fallback) | exact |
| `app/assets/stylesheets/todos.css.scss` | stylesheet | — | itself — remove/replace `.todo_actions` selectors | exact |
| `app/assets/stylesheets/welcome.css.scss` | stylesheet | — | itself — refactor `.todo-gadget-new-link` rule, add `.todo-gadget-complete-group` rules | exact |
| `config/locales/ja.yml` | i18n config | — | existing `welcome.todo_gadget` block (lines 320–322) | exact |
| `config/locales/en.yml` | i18n config | — | existing `welcome.todo_gadget` block (lines 320–322) | exact |
| `test/controllers/welcome_controller/dashboard_test.rb` | test | request-response | itself — update 2 assertions at lines 94, 109 | exact |

---

## Pattern Assignments

### `app/views/welcome/_todo_gadget.html.erb` (view/partial, SSR)

**Analog:** itself (current file) + `_gadget_title_with_icon.html.erb` local-slot pattern

**Current render call pattern** (lines 9–19 of current file):
```erb
<%= render 'common/gadget_title_with_icon',
           variant: :todo,
           header_link: link_to(
             t('welcome.todo_gadget.new_link'),
             new_todo_path,
             class: 'todo-gadget-new-link',
             aria: { label: t('welcome.todo_gadget.new_link_aria_label') },
             onclick: 'todos.new_todo(this); return false;'
           ) do %>
  <%= gadget.title %>
<% end %>
```

**Change required — two options (executor chooses):**

Option A: Add `complete_group:` local (requires touching `_gadget_title_with_icon.html.erb`):
```erb
<%= render 'common/gadget_title_with_icon',
           variant: :todo,
           header_link: link_to(
             t('welcome.todo_gadget.new_link'),
             new_todo_path,
             class: 'todo-gadget-new-link',
             aria: { label: t('welcome.todo_gadget.new_link_aria_label') },
             onclick: 'todos.new_todo(this); return false;'
           ),
           complete_group: content_tag(:span, class: 'todo-gadget-complete-group') {
             content_tag(:span, '',
               class: 'todo-gadget-selected-count',
               aria: { live: 'polite' },
               data: { template: t('welcome.todo_gadget.selected_count', count: '%{count}') }
             ) +
             link_to(
               t('todos.actions.complete'),
               delete_todos_path,
               class: 'todo-gadget-complete-link',
               onclick: 'todos.delete_todos(this); return false;'
             )
           } do %>
  <%= gadget.title %>
<% end %>
```

Option B: Bundle into `header_link:` (no change to shared partial):
```erb
header_link: (
  link_to(t('welcome.todo_gadget.new_link'), new_todo_path,
    class: 'todo-gadget-new-link',
    aria: { label: t('welcome.todo_gadget.new_link_aria_label') },
    onclick: 'todos.new_todo(this); return false;') +
  content_tag(:span, class: 'todo-gadget-complete-group') {
    content_tag(:span, '',
      class: 'todo-gadget-selected-count',
      aria: { live: 'polite' },
      data: { template: t('welcome.todo_gadget.selected_count', count: '%{count}') }
    ) +
    link_to(t('todos.actions.complete'), delete_todos_path,
      class: 'todo-gadget-complete-link',
      onclick: 'todos.delete_todos(this); return false;')
  }
),
```

**Also remove** line 21: `<%= render 'todos/actions' %>`

---

### `app/views/common/_gadget_title_with_icon.html.erb` (view/partial, SSR)

**Analog:** itself — existing `header_link:` optional local pattern (lines 12–14)

**Current optional-local pattern to copy for `complete_group:`** (lines 12–14):
```erb
<% if local_assigns[:header_link] %>
  <%= header_link %>
<% end %>
```

**Change required (Option A only):** Add after the `header_link` block:
```erb
<% if local_assigns[:complete_group] %>
  <%= complete_group %>
<% end %>
```

**No change needed for Option B.**

---

### `app/assets/javascripts/todos.js` (utility/JS, event-driven)

**Analog:** itself — `todos.toggle_highlight` (CSRF pattern, lines 95–105) and `todos.new_todo` (closest-ol fallback, lines 107–117)

**CSRF meta-tag pattern to copy from `todos.toggle_highlight`** (line 100):
```js
authenticity_token: $('meta[name="csrf-token"]').attr('content'),
```

**Closest-ol fallback pattern to copy from `todos.new_todo`** (lines 108–111):
```js
const $trigger = $(trigger);
const ol = $trigger.closest('ol').length
  ? $trigger.closest('ol')
  : $trigger.closest('.gadget.todo').find('ol').first();
```

**Change 1 — `dblclick` handler** (line 32): `'li:not(.todo_actions)'` → `'li'`

**Change 2 — `touchstart` handler** (line 36): `'li:not(.todo_actions)'` → `'li'`

**Change 3 — `touchend` handler** (line 44): `'li:not(.todo_actions)'` → `'li'`

**Change 4 — `touchend` siblings filter** (line 70):
```js
// Before:
$li.siblings(':not(.todo_actions)').removeClass('todo-highlight-visible');
// After:
$li.siblings().removeClass('todo-highlight-visible');
```

**Change 5 — touchstart document handler** (line 76):
```js
// Before:
if (!$(e.target).closest('.todo li:not(.todo_actions)').length) {
// After:
if (!$(e.target).closest('.todo li').length) {
```

**Change 6 — `click 'li span:first-child'` handler** (lines 81–86):
```js
// Before:
$(selector).on('click', 'li span:first-child', function() {
  if (!$(this).parent().is('.todo_actions')) {
    $(this).toggleClass('selected');
    $(this).parent().toggleClass('selected');
  }
});

// After:
$(selector).on('click', 'li span:first-child', function() {
  $(this).toggleClass('selected');
  $(this).parent().toggleClass('selected');
  const ol = $(this).closest('ol');
  todos._updateCompleteGroup(ol);
});
```

**New function — `todos._updateCompleteGroup`** (add after `todos.init`):
```js
todos._updateCompleteGroup = function(ol) {
  const count = ol.find('li.selected').length;
  const $gadget = ol.closest('.gadget.todo');
  const $group = $gadget.find('.todo-gadget-complete-group');
  const $countEl = $group.find('.todo-gadget-selected-count');

  if (count > 0) {
    const template = $countEl.data('template'); // "%{count}件選択中" or "%{count} selected"
    $countEl.text(template.replace('%{count}', count));
    $group.css('display', 'inline-flex');
  } else {
    $group.hide();
  }
};
```

**Change 7 — `todos.new_todo` insertion point** (line 115):
```js
// Before:
ol.find('.todo_actions').after('<li>' + html + '</li>');
// After:
ol.prepend('<li>' + html + '</li>');
```

**Change 8 — `todos.delete_todos`** (lines 137–152) — full replacement:
```js
todos.delete_todos = function(trigger) {
  const $trigger = $(trigger);
  const ol = $trigger.closest('ol').length
    ? $trigger.closest('ol')
    : $trigger.closest('.gadget.todo').find('ol').first();
  const url = $trigger.attr('href');

  const params = {};
  params.format = 'html';
  params.authenticity_token = $('meta[name="csrf-token"]').attr('content');
  params.todo_id = [];
  ol.find('li.selected').each(function() {
    params.todo_id.push($(this).data('id'));
  });
  if (params.todo_id.length === 0) return;
  $.post(url, params, function () {
    ol.find('li.selected').hide();
    todos._updateCompleteGroup(ol);
  });
};
```

---

### `app/assets/stylesheets/todos.css.scss` (stylesheet)

**Analog:** itself — 8 selectors containing `.todo_actions` to remove or replace

**Current `.todo_actions` block** (lines 178–184) — remove entirely:
```scss
.todo_actions {
  min-height: 1.2em;

  a:visited {
    color: blue;
  }
}
```

**Selector replacements** (per UI-SPEC §CSS Cleanup):

| Current selector | Replace with |
|-----------------|-------------|
| `li:not(.todo_actions)` (line 13) | `li` |
| `&:not(.todo_actions):has(form.todo)` (line 26) | `&:has(form.todo)` |
| `&:not(.todo_actions):not(:has(form.todo))` (line 31) | `&:not(:has(form.todo))` |
| `li:not(.todo_actions):hover .todo-highlight-btn` (line 67) | `li:hover .todo-highlight-btn` |
| `li.highlighted:not(.todo_actions)` (line 72, inside `@media`) | `li.highlighted` |
| `li:not(.todo_actions) .todo-highlight-btn` (line 76, inside `@media`) | `li .todo-highlight-btn` |
| `li:not(.todo_actions).todo-highlight-visible .todo-highlight-btn` (line 80, inside `@media`) | `li.todo-highlight-visible .todo-highlight-btn` |

---

### `app/assets/stylesheets/welcome.css.scss` (stylesheet)

**Analog:** itself — existing `.todo-gadget-new-link` rule at lines 287–310

**Current rule to REFACTOR** (lines 287–305) — note `margin-left: auto` and `opacity: 0` must NOT apply to `.todo-gadget-complete-link`:
```scss
// Gadget header "new" link — visible on title hover
.bookmark-gadget-new-link,
.todo-gadget-new-link {
  margin-left: auto;
  flex-shrink: 0;
  opacity: 0;
  font-size: 0.78em;
  font-weight: normal;
  text-decoration: none;
  padding: 1px 6px;
  border-radius: 3px;
  border: 1px solid currentColor;
  line-height: 1.4;
  cursor: pointer;
  transition: opacity 0.12s ease;

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
}
```

**Refactored into two rules:**
```scss
// Shared visual style for all gadget header action links
.bookmark-gadget-new-link,
.todo-gadget-new-link,
.todo-gadget-complete-link {
  flex-shrink: 0;
  font-size: 0.78em;
  font-weight: normal;
  text-decoration: none;
  padding: 1px 6px;
  border-radius: 3px;
  border: 1px solid currentColor;
  line-height: 1.4;
  cursor: pointer;
}

// New-link only: hover-opacity and auto-margin (pushes to far right)
.bookmark-gadget-new-link,
.todo-gadget-new-link {
  margin-left: auto;
  opacity: 0;
  transition: opacity 0.12s ease;

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
}
```

**New rules to add** (after the hover rule at lines 307–310):
```scss
// Complete group: hidden until JS shows it (JS toggles to inline-flex when count > 0)
.todo-gadget-complete-group {
  display: none;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

.todo-gadget-selected-count {
  font-size: 0.78em;
  font-weight: normal;
  line-height: 1.4;
  white-space: nowrap;
  color: inherit;
}
```

---

### `config/locales/ja.yml` (i18n config)

**Analog:** itself — existing `welcome.todo_gadget` block (lines 320–322)

**Current block:**
```yaml
    todo_gadget:
      new_link: 追加
      new_link_aria_label: タスクを追加
```

**Add one key:**
```yaml
    todo_gadget:
      new_link: 追加
      new_link_aria_label: タスクを追加
      selected_count: "%{count}件選択中"
```

---

### `config/locales/en.yml` (i18n config)

**Analog:** itself — existing `welcome.todo_gadget` block (lines 320–322)

**Current block:**
```yaml
    todo_gadget:
      new_link: new
      new_link_aria_label: Add task
```

**Add one key:**
```yaml
    todo_gadget:
      new_link: new
      new_link_aria_label: Add task
      selected_count: "%{count} selected"
```

---

### `test/controllers/welcome_controller/dashboard_test.rb` (test)

**Analog:** itself — lines 94 and 109 contain assertions that will break

**Current broken assertions:**
```ruby
# Line 94 (test_Todoガジェットが日本語ロケールで日本語表示される):
assert_select '#todo .todo_actions a', text: '完了', count: 1

# Line 109 (test_Todoガジェットが英語ロケールで英語表示されタイトルは変わらない):
assert_select '#todo .todo_actions a', text: 'Complete', count: 1
```

**Replacement assertions (new header structure):**
```ruby
# Line 94 replacement:
assert_select '#todo .title .todo-gadget-complete-link', text: '完了', count: 1

# Line 109 replacement:
assert_select '#todo .title .todo-gadget-complete-link', text: 'Complete', count: 1
```

---

## Shared Patterns

### CSRF Token Source
**Source:** `app/assets/javascripts/todos.js` line 100 (inside `todos.toggle_highlight`)
**Apply to:** `todos.delete_todos` rewrite
```js
$('meta[name="csrf-token"]').attr('content')
```

### Closest-OL Fallback
**Source:** `app/assets/javascripts/todos.js` lines 108–111 (inside `todos.new_todo`)
**Apply to:** `todos.delete_todos` rewrite — trigger is now in header div, not inside `<ol>`
```js
const $trigger = $(trigger);
const ol = $trigger.closest('ol').length
  ? $trigger.closest('ol')
  : $trigger.closest('.gadget.todo').find('ol').first();
```

### Optional Local Slot in Shared Partial
**Source:** `app/views/common/_gadget_title_with_icon.html.erb` lines 12–14
**Apply to:** Adding `complete_group:` slot (Option A)
```erb
<% if local_assigns[:header_link] %>
  <%= header_link %>
<% end %>
```

### Link-button Visual Style
**Source:** `app/assets/stylesheets/welcome.css.scss` lines 287–305 (`.todo-gadget-new-link` rule)
**Apply to:** `.todo-gadget-complete-link` — must share all properties EXCEPT `margin-left: auto` and `opacity: 0`

---

## No Analog Found

None. All files are existing — modified or extended from known patterns.

---

## Metadata

**Analog search scope:** `app/views/`, `app/assets/javascripts/`, `app/assets/stylesheets/`, `config/locales/`, `test/controllers/welcome_controller/`
**Files scanned:** 9 source files read directly
**Pattern extraction date:** 2026-06-18
