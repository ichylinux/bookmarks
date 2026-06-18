# Phase 127: Header-Integrated Task Completion — Research

**Researched:** 2026-06-18
**Domain:** Rails 7.2 ERB partial wiring + Sprockets/jQuery DOM management
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- 「完了」アクションは既存の `.title--gadget-with-icon` ヘッダ行内に配置し、「新規／追加」リンクの後ろに右寄せで並べる
- 「完了」は `todo-gadget-new-link` と同様のリンク（`<a>`）として描画し、`onclick: 'todos.delete_todos(this); return false;'` で既存ハンドラを流用（新規 JS ライブラリなし）
- 0件選択時は DOM 上に残したまま `display:none`（JS 管理クラス）で隠し、1件以上選択時に表示する
- 選択件数テキスト（例「2件選択中」）を「完了」リンクのすぐ左に置き、両者をヘッダ右側のコンテナにまとめる
- 選択件数の更新は既存の `click 'li span:first-child'` ハンドラ内で `li.selected` 件数を再計算し、ヘッダの表示／非表示と件数テキストを更新する
- CSRF トークンは `.todo_actions` 撤廃に伴い、既存の `meta[name="csrf-token"]`（`toggle_highlight` で既に使用）から取得する
- `new_todo` の挿入位置は `.todo_actions` 撤廃に伴い `<ol>` の先頭へ prepend する
- 空選択ガード: 0件のときアクションは非表示（クリック不可）にし、加えて JS 側でも件数0なら no-op にする
- 「完了」ラベルは既存の `t('todos.actions.complete')`（= 完了）を再利用する
- 選択件数文言は ja「%{count}件選択中」 / en "%{count} selected"
- 新規キーは `welcome.todo_gadget.selected_count` に置き ja/en パリティを保つ
- 英語の複数形は単純補間（`%{count} selected`）で扱い、one/other の分岐はしない

### Claude's Discretion

None stated — all key decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

- HDR-FUT-01 行ごとの個別「完了」操作（タスク単位ワンクリック完了） — v2
- HDR-FUT-02 ヘッダに「すべて選択／選択解除」トグル — v2
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HDR-01 | タスクガジェットのヘッダ行（既存の「新規」リンクと同じ行）に「完了」アクションを配置する | `_gadget_title_with_icon.html.erb` の `header_link` スロットまたは新規 `complete_group:` local を使用；§Architecture Patterns 参照 |
| HDR-02 | 「完了」アクションは1件以上のタスクが選択されているときのみ表示 | `.todo-gadget-complete-group { display: none }` + JS で `inline-flex` に切替；§Code Examples 参照 |
| HDR-03 | ヘッダに現在の選択件数を表示し、選択数の増減に追従 | `click 'li span:first-child'` ハンドラに count 再計算ロジックを追加；`data-template` 属性で i18n 文字列を JS に渡す；§Code Examples 参照 |
| LAY-01 | `.todo_actions` 行の廃止により縦スペースを回収 | `_todo_gadget.html.erb` から `render 'todos/actions'` を削除；`_actions.html.erb` は未使用になる；§Architecture Patterns 参照 |
| SEL-01 | 既存のタップ/クリック選択挙動（`span.selected`）を変更せず維持 | `todos.js` の選択トグルロジック自体は変更不要；ただし `.todo_actions` ガードの削除が必要；§Common Pitfalls 参照 |
| SEL-02 | ヘッダの「完了」実行で選択中の全タスクが完了扱いになる（`POST /todos/delete` 流用） | `todos.delete_todos` の CSRF 取得元と `closest('ol')` 探索を修正；§Code Examples 参照 |
| I18N-01 | 新規ヘッダUI文言が ja/en の両ロケールキーで提供され、ロケールキーのパリティテストが通る | `welcome.todo_gadget.selected_count` を ja.yml と en.yml に追加；parity テストは既存の `test_jaとenのキー集合が一致する` で自動検出；§Validation Architecture 参照 |
</phase_requirements>

---

## Summary

Phase 127 は ERB partial / Sprockets / jQuery のみを使った小規模な UI 改修だが、複数のファイルにわたる変更を連動して行う必要がある。主な変更は「(1) `.todo_actions` を削除し縦スペースを回収」「(2) ガジェットヘッダに完了グループを追加」「(3) `todos.js` の複数の `.todo_actions` 依存を修正」の3系統に整理できる。

`todos.js` に存在する`.todo_actions` への参照は 8 箇所あり、それぞれ役割が異なる（CSRF 取得 / 挿入アンカー / イベントフィルタ）。これらをまとめて修正しないと、新規タスク追加が壊れるか、完了 POST の CSRF エラーが発生する。特に `todos.delete_todos` の `$(trigger).closest('ol')` は、trigger がヘッダ内に移った後に必ず空 jQuery を返すため、`todos.new_todo` と同様のフォールバックパターン（`.gadget.todo` → `ol`）への修正が必須である。

i18n 文言の JS への受け渡しには `data-template` 属性パターンを使う。`selected_count` キーは `%{count}` プレースホルダつきで ERB から `data-template` に書き出し、JS 側で `.replace('%{count}', count)` して DOM を更新する。これにより Rails の I18n を JS で複製しなくて済む。

**Primary recommendation:** `todos.js` の修正（CSRF・`closest` 修正・count 更新ロジック追加）を最初のタスクとして実装し、CSS 変更・ERB 変更は直後に連動させる。既存の 2 つの Minitest 検証（`dashboard_test.rb` 内の `.todo_actions a` アサーション）は Phase 127 の HTML 変更で壊れるため、フェーズ内で修正する必要がある。

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ヘッダ完了グループの HTML 構造 | Frontend Server (SSR) — ERB | — | Rails が初期 HTML を生成；JS は表示/非表示の切替のみ担当 |
| 選択件数カウントの更新 | Browser / Client — jQuery | — | サーバー往復なし；DOM の `li.selected` 件数をカウントするだけ |
| 完了 POST の実行 | API / Backend | Browser (AJAX) | 既存 `POST /todos/delete` → `TodosController#delete` |
| CSRF トークン供給 | Frontend Server (SSR) | Browser | Rails が `<meta name="csrf-token">` を埋め込み；JS が読み取る |
| i18n 選択件数テキスト | Frontend Server (SSR) → Browser | — | ERB で `data-template` に書き出し；JS が実行時に補間 |
| CSS 表示切替 | Browser / Client — jQuery | — | `display: none / inline-flex` の切替のみ；CSS クラスの付け替えで可 |

---

## Standard Stack

No new packages. This phase uses only the existing stack. [VERIFIED: codebase grep]

| Layer | Technology | Version | Notes |
|-------|------------|---------|-------|
| Server-side templating | Rails ERB + partials | 7.2 | `_gadget_title_with_icon.html.erb` を修正 |
| JavaScript | jQuery (Sprockets) | existing | `window.todos` namespace 内で拡張 |
| CSS preprocessor | SCSS (Sprockets) | existing | `todos.css.scss`, `welcome.css.scss` |
| i18n | Rails I18n | existing | `ja.yml` / `en.yml` |

**Installation:** None required.

## Package Legitimacy Audit

No external packages are introduced in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser click on li span
    │
    ▼
todos.init click handler
    │── toggles span.selected / li.selected
    │── counts ol.find('li.selected').length
    │── updates data-template → .todo-gadget-selected-count.text
    └── shows/hides .todo-gadget-complete-group (display: none / inline-flex)

Browser click on .todo-gadget-complete-link (in header)
    │
    ▼
todos.delete_todos(trigger)
    │── 0-guard: params.todo_id.length === 0 → return
    │── CSRF: $('meta[name="csrf-token"]').attr('content')
    │── ol: trigger.closest('.gadget.todo').find('ol').first()
    │── collects li.selected data-id values
    │── $.post /todos/delete
    │       └── success: ol.find('li.selected').hide()
    │                    todos._updateCompleteGroup(ol)
    └── server: TodosController#delete → todo.update!(done: true)
```

### Recommended File Change Set

```
app/
├── views/
│   ├── welcome/_todo_gadget.html.erb      # remove render 'todos/actions'; add complete_group to header
│   ├── common/_gadget_title_with_icon.html.erb  # add complete_group: local slot (optional)
│   └── todos/_actions.html.erb            # no longer rendered (file can be left; render call removed)
├── assets/
│   ├── javascripts/todos.js               # 8 changes (see §Code Examples)
│   └── stylesheets/
│       ├── todos.css.scss                 # remove .todo_actions; replace li:not(.todo_actions) selectors
│       └── welcome.css.scss               # add complete-group/count/complete-link styles
└── config/locales/
    ├── ja.yml                             # add welcome.todo_gadget.selected_count
    └── en.yml                             # add welcome.todo_gadget.selected_count
test/
└── controllers/welcome_controller/dashboard_test.rb  # update 2 broken assertions
```

### Pattern 1: Header Slot for Complete Group

**Two valid approaches — executor may choose either:**

**Option A (add `complete_group:` local to the shared partial):**

`_gadget_title_with_icon.html.erb`:
```erb
<div class="title title--gadget-with-icon" data-gadget-icon="<%= v %>">
  <span class="gadget-title-icon ...">...</span>
  <span class="gadget-title-text"><%= yield %></span>
  <% if local_assigns[:header_link] %>
    <%= header_link %>
  <% end %>
  <% if local_assigns[:complete_group] %>
    <%= complete_group %>
  <% end %>
</div>
```

`_todo_gadget.html.erb` (caller):
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

**Option B (bundle both links into `header_link:`):**

Keep `_gadget_title_with_icon.html.erb` unchanged. In `_todo_gadget.html.erb`, pass a combined string for `header_link:`:

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

**Recommendation:** Option A is cleaner for future extensibility (other gadgets could use `complete_group:`). Option B avoids touching the shared partial. Both are functionally equivalent.

### Pattern 2: data-template for i18n Count Text

The JS cannot call Rails I18n directly. ERB bakes the locale-appropriate format string into a `data-template` attribute at render time:

```erb
data: { template: t('welcome.todo_gadget.selected_count', count: '%{count}') }
```

This renders as `data-template="2件選択中"` for ja with count=2... no — it renders as `data-template="%{count}件選択中"` because the string `'%{count}'` is passed as the `count:` argument. Rails I18n interpolates it verbatim, yielding the literal string `%{count}件選択中`. Then JS replaces `%{count}` with the actual number at click time.

[ASSUMED: Rails I18n passes a string value for `%{count}` through verbatim without type coercion — verify in console if needed.]

JavaScript:
```js
const template = $countEl.data('template'); // "%{count}件選択中" or "%{count} selected"
$countEl.text(template.replace('%{count}', count));
```

### Pattern 3: `closest('ol')` Fallback in `delete_todos`

The new trigger lives in the HEADER div, which is NOT inside the `<ol>`. `$(trigger).closest('ol')` returns an empty jQuery object. Use the same pattern already established in `todos.new_todo`:

```js
// Before (works only when trigger is inside <ol>):
const ol = $(trigger).closest('ol');

// After (handles both header and in-list trigger positions):
const $trigger = $(trigger);
const ol = $trigger.closest('ol').length
  ? $trigger.closest('ol')
  : $trigger.closest('.gadget.todo').find('ol').first();
```

[VERIFIED: codebase grep — `todos.new_todo` already uses this exact fallback pattern at line 108–111 of todos.js]

### Anti-Patterns to Avoid

- **Calling `todos.delete_todos` with `closest('ol')` unchanged:** Returns empty jQuery; `params.todo_id` will always be `[]`; the POST succeeds but completes nothing. No error is thrown, making this silent.
- **Adding `margin-left: auto` to `.todo-gadget-complete-link`:** The link is a child of `.todo-gadget-complete-group` which is itself a flex item. `margin-left: auto` on the link would push the 完了 text to the right within the group, separating it from the count span.
- **Removing `li:not(.todo_actions)` selectors without verifying scope:** The `.todo-highlight-btn` hover rules depend on these selectors. Replacing with bare `li` is correct but requires checking that no NEW `li` elements (e.g., form row) accidentally show the highlight button. [ASSUMED: the form row `li` has class `form.todo` descendant check, and the `:has(form.todo)` CSS rule already handles hiding highlights for those rows]
- **Not updating the complete group after `delete_todos` POST:** If `ol.find('li.selected').hide()` runs but the count display stays showing "2件選択中", the UX is broken. The count update helper must run in the POST success callback.
- **Using `display: none` via a class toggle vs. inline style:** The UI-SPEC prescribes JS managing `display` directly (`$group.hide()` / `$group.css('display', 'inline-flex')`). Either `$.fn.hide()` + manual show with `inline-flex`, or a CSS utility class approach works — just be consistent.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| i18n string in JS | JS-side locale detection + hardcoded strings | `data-template` attribute baked by ERB | Rails already owns the locale; duplicating strings in JS creates drift |
| CSRF token supply | Custom cookie / localStorage | `$('meta[name="csrf-token"]').attr('content')` | Rails `csrf_meta_tags` already emits this; `toggle_highlight` already uses it [VERIFIED: todos.js line 100] |
| Count sync state machine | Global variable / custom event bus | Re-read `ol.find('li.selected').length` on each click | DOM is the single source of truth; no separate state to sync |

**Key insight:** This phase has zero new dependencies. Every mechanism it needs (CSRF, count, AJAX, selection state) already exists in the codebase. The work is wiring, not building.

---

## Common Pitfalls

### Pitfall 1: `closest('ol')` Returns Empty from Header Context

**What goes wrong:** `todos.delete_todos` calls `$(trigger).closest('ol')`. When the trigger is `.todo-gadget-complete-link` inside `.title--gadget-with-icon`, this returns `$()` (empty set). `ol.find('li.selected')` returns nothing. `params.todo_id` is `[]`. The POST fires with an empty ID list. `TodosController#delete` checks `params[:todo_id].present?` and silently does nothing (returns `head :ok`). No visible error.

**Why it happens:** The old trigger (`.todo_actions` link) was inside `<ol>`. The new trigger is in a sibling `<div>`. `closest()` traverses ancestors only, not siblings.

**How to avoid:** Apply the fallback pattern from `todos.new_todo`:
```js
const ol = $trigger.closest('ol').length
  ? $trigger.closest('ol')
  : $trigger.closest('.gadget.todo').find('ol').first();
```

**Warning signs:** Post fires successfully (200 OK) but no items disappear. `params.todo_id` is empty in server logs.

### Pitfall 2: Existing Minitest Assertions Will Break

**What goes wrong:** `dashboard_test.rb` has two assertions that reference `.todo_actions a`:
- Line 94: `assert_select '#todo .todo_actions a', text: '完了', count: 1`
- Line 109: `assert_select '#todo .todo_actions a', text: 'Complete', count: 1`

After `.todo_actions` is removed from the DOM, both fail with `Expected 1 element matching '#todo .todo_actions a', found 0`.

**Why it happens:** Phase 127 removes the `.todo_actions` `<li>` from the rendered HTML. These tests assert on the old structure.

**How to avoid:** Update both assertions to reflect the new header-based structure. The assertions should now verify that `.todo-gadget-complete-link` is present in `.title--gadget-with-icon`. Since the complete link is always in the DOM (just hidden), `count: 1` remains correct:
```ruby
# Old:
assert_select '#todo .todo_actions a', text: '完了', count: 1
# New:
assert_select '#todo .title .todo-gadget-complete-link', text: '完了', count: 1
```

**Warning signs:** `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` fails immediately after removing `render 'todos/actions'`.

**Impact on phase gate:** The phase verification policy (CLAUDE.md) requires `bin/rails test` to be green. These two assertions must be fixed in Phase 127 even though Phase 128 handles new test additions.

### Pitfall 3: `li:not(.todo_actions)` Selector Replacements Must Be Exhaustive

**What goes wrong:** `todos.css.scss` has 8 selectors containing `.todo_actions`. Missing even one leaves a dead selector that silently does nothing — or causes style gaps if the selector was preventing something.

**Why it happens:** These selectors were added piecemeal over multiple phases. They are not in one place.

**How to avoid:** Verify all replacements using the audit table from UI-SPEC.md §CSS Cleanup. After changes, grep for `.todo_actions` across the entire codebase to confirm no references remain:
```bash
grep -rn "todo_actions" app/assets/ app/views/ app/assets/javascripts/
```
Expected result: 0 matches.

**Warning signs:** After completing changes, `grep -rn "todo_actions"` shows remaining hits.

### Pitfall 4: `margin-left: auto` on Complete Link

**What goes wrong:** If `.todo-gadget-complete-link` is added to the `.bookmark-gadget-new-link, .todo-gadget-new-link { margin-left: auto; ... }` rule without overriding `margin-left`, the link inside the complete-group gains `margin-left: auto`, which pushes it to the far right of the group's flex container — splitting the count text from the 完了 link.

**Why it happens:** The shared rule includes `margin-left: auto` as a layout mechanism for standalone header links. It's incorrect when the link is a child of a flex container that handles its own layout.

**How to avoid:** Either (a) separate the `margin-left: auto` into a rule that applies only to `.bookmark-gadget-new-link, .todo-gadget-new-link`, keeping the visual-only properties in a wider rule that also includes `.todo-gadget-complete-link`; or (b) add `.todo-gadget-complete-link { margin-left: 0; }` as a specific override.

### Pitfall 5: Selection Guard in Click Handler

**What goes wrong:** The current click handler on `li span:first-child` has an explicit guard:
```js
if (!$(this).parent().is('.todo_actions')) { ... }
```
Once `.todo_actions` is gone, this guard is permanently false (`.todo_actions` never exists) — the guard is inert but harmless. However, it reads as confusing dead code and should be removed for clarity.

**Why it happens:** Guard was added to prevent clicking the old 完了 link inside `.todo_actions` from toggling selection.

**How to avoid:** Remove the guard entirely. The new 完了 link is in a `<div>`, not a `<li>`, so it will never match `li span:first-child`.

---

## Code Examples

### todos.js — Full List of Changes

Source: codebase inspection [VERIFIED: todos.js as of current HEAD]

**Change 1: `dblclick` handler — remove `.todo_actions` exclusion**
```js
// Before:
$(selector).on('dblclick', 'li:not(.todo_actions)', function() {
// After:
$(selector).on('dblclick', 'li', function() {
```

**Change 2: `touchstart` handler**
```js
// Before:
$(selector).on('touchstart', 'li:not(.todo_actions)', function(e) {
// After:
$(selector).on('touchstart', 'li', function(e) {
```

**Change 3: `touchend` handler**
```js
// Before:
$(selector).on('touchend', 'li:not(.todo_actions)', function(e) {
// After:
$(selector).on('touchend', 'li', function(e) {
```

**Change 4: `touchend` — siblings filter**
```js
// Before:
$li.siblings(':not(.todo_actions)').removeClass('todo-highlight-visible');
// After:
$li.siblings().removeClass('todo-highlight-visible');
```

**Change 5: `touchstart document` — click-away detection**
```js
// Before:
if (!$(e.target).closest('.todo li:not(.todo_actions)').length) {
// After:
if (!$(e.target).closest('.todo li').length) {
```

**Change 6: `click 'li span:first-child'` handler — remove guard, add count update**
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

**New helper: `todos._updateCompleteGroup`**
```js
todos._updateCompleteGroup = function(ol) {
  const count = ol.find('li.selected').length;
  const $gadget = ol.closest('.gadget.todo');
  const $group = $gadget.find('.todo-gadget-complete-group');
  const $countEl = $group.find('.todo-gadget-selected-count');

  if (count > 0) {
    const template = $countEl.data('template'); // e.g. "%{count}件選択中"
    $countEl.text(template.replace('%{count}', count));
    $group.css('display', 'inline-flex');
  } else {
    $group.hide();
  }
};
```

**Change 7: `todos.new_todo` — insertion point**
```js
// Before:
ol.find('.todo_actions').after('<li>' + html + '</li>');

// After:
ol.prepend('<li>' + html + '</li>');
```

**Change 8: `todos.delete_todos` — CSRF source, `closest('ol')` fix, 0-guard, count reset**
```js
// Before:
todos.delete_todos = function(trigger) {
  const ol = $(trigger).closest('ol');
  const url = $(trigger).attr('href');
  const params = {};
  params.format = 'html';
  params.authenticity_token = $(trigger).closest('.todo_actions').data('authenticity_token');
  params.todo_id = [];
  ol.find('li.selected').each(function() {
    params.todo_id.push($(this).data('id'));
  });
  $.post(url, params, function () {
    ol.find('li.selected').hide();
  });
};

// After:
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

### welcome.css.scss — New styles to add

```scss
// Extend existing selector to include complete-link visual style
// NOTE: do NOT include margin-left: auto in this shared rule
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

// margin-left: auto stays on the original pair only (pushes new-link to far right)
.bookmark-gadget-new-link,
.todo-gadget-new-link {
  margin-left: auto;
  opacity: 0;
  transition: opacity 0.12s ease;

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
}

div.title:hover .bookmark-gadget-new-link,
div.title:hover .todo-gadget-new-link {
  opacity: 1;
}

// Complete group: hidden until JS shows it
.todo-gadget-complete-group {
  display: none;      // JS toggles to inline-flex when count > 0
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

**Important:** The existing `welcome.css.scss` rule at line 288 must be refactored — not appended — because the current `margin-left: auto` and `opacity: 0` must NOT apply to `.todo-gadget-complete-link`.

### ja.yml / en.yml additions

```yaml
# ja.yml — under welcome.todo_gadget:
selected_count: "%{count}件選択中"

# en.yml — under welcome.todo_gadget:
selected_count: "%{count} selected"
```

### dashboard_test.rb — assertions to update

```ruby
# test_Todoガジェットが日本語ロケールで日本語表示される
# Before:
assert_select '#todo .todo_actions a', text: '完了', count: 1
# After:
assert_select '#todo .title .todo-gadget-complete-link', text: '完了', count: 1

# test_Todoガジェットが英語ロケールで英語表示されタイトルは変わらない
# Before:
assert_select '#todo .todo_actions a', text: 'Complete', count: 1
# After:
assert_select '#todo .title .todo-gadget-complete-link', text: 'Complete', count: 1
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.todo_actions` inline `data-authenticity_token` | `meta[name="csrf-token"]` (already used by `toggle_highlight`) | Phase 127 | No change to backend; CSRF token is the same value |
| `ol.find('.todo_actions').after(html)` for new todo insertion | `ol.prepend(html)` | Phase 127 | New todos appear at top of list (same as `.todo_actions` was at top) |

**Deprecated/outdated after Phase 127:**
- `_actions.html.erb`: File is no longer rendered. May be left in place as dead code or deleted — the render call in `_todo_gadget.html.erb` is the only entry point.
- `.todo_actions` CSS class: Completely unused after phase. All CSS referencing it is removed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Rails I18n passes a string value `'%{count}'` for `count:` verbatim without type-checking, yielding `"%{count}件選択中"` as the `data-template` value | Code Examples §Pattern 2 | If Rails raises `ArgumentError` expecting an Integer, the ERB render will fail; fallback: use a `data-count-format-ja` / `data-count-format-en` approach or check `html_lang` in JS |
| A2 | `&:not(:has(form.todo))` selector (CSS `:has` replacement) is supported by the browser targets for this app | CSS Cleanup | If old browsers without `:has` support are required, keep a simpler combinator |
| A3 | `.todo-gadget-new-link` currently has `margin-left: auto` in `welcome.css.scss` | Architecture Patterns | Confirmed by reading welcome.css.scss line 289 [VERIFIED: codebase read] — but marking as A3 because the refactoring approach depends on this layout assumption |

---

## Open Questions (RESOLVED)

1. **Should `_actions.html.erb` be deleted or left as dead code?** — RESOLVED: deleted in plan Task 2.
   - What we know: The render call is removed from `_todo_gadget.html.erb`; the file becomes unreferenced.
   - What's unclear: Project convention on dead partial cleanup.
   - Recommendation: Delete it to avoid confusion. The planner may include a task to delete it.

2. **Is the `data-template` i18n approach reliable for `%{count}` string passing?** — RESOLVED: planner verified directly — `t('welcome.todo_gadget.selected_count', count: '%{count}')` yields the literal `"%{count}件選択中"` / `"%{count} selected"`. The `data-template` approach is locked; no fallback path needed.
   - What we know: See A1 above.
   - Recommendation: locked per direct verification during planning.

---

## Environment Availability

Step 2.6: SKIPPED — this phase makes no changes to external dependencies, runtimes, or services. All changes are within the Rails asset pipeline and ERB templates.

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails built-in) + Cucumber (via `bundle exec rake dad:test`) |
| Config file | `test/test_helper.rb` |
| Quick run command (Minitest) | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb test/controllers/todos_controller_test.rb test/i18n/locales_parity_test.rb` |
| Full suite | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HDR-01 | `.todo-gadget-complete-link` is rendered in the header | unit | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` | Yes (assertions need updating — see Pitfall 2) |
| HDR-02 | Complete group is hidden on page load (0 selected) | unit | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` | Yes (new assertion needed — Phase 128) |
| HDR-03 | Count text updates on selection | E2E (JS-driven) | `bundle exec rake dad:test` | No (Phase 128) |
| LAY-01 | `.todo_actions` element is absent from DOM | unit | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` | No (Phase 128) |
| SEL-01 | `span.selected` toggle still works | E2E | `bundle exec rake dad:test` | Partial — existing タスク.feature covers selection |
| SEL-02 | POST /todos/delete marks selected items done | unit | `bin/rails test test/controllers/todos_controller_test.rb` | Yes — `test_完了でdoneが立つ` exists |
| I18N-01 | ja/en parity for `selected_count` key | unit | `bin/rails test test/i18n/locales_parity_test.rb` | Yes — parity test automatically catches missing keys |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/welcome_controller/dashboard_test.rb test/i18n/locales_parity_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`

### Wave 0 Gaps

Phase 127 does not add new tests (that is Phase 128's responsibility). However, the two existing assertions in `dashboard_test.rb` that reference `.todo_actions a` must be updated in Phase 127 because they will fail after the HTML changes. These are not "new" test files — they are existing files that need assertion updates:

- [ ] Update `test/controllers/welcome_controller/dashboard_test.rb` — change 2 assertions from `.todo_actions a` to `.title .todo-gadget-complete-link` (see §Code Examples)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase makes no auth changes |
| V3 Session Management | no | Phase makes no session changes |
| V4 Access Control | no | `TodosController#delete` ownership guard is unchanged (`updatable_by?` check) |
| V5 Input Validation | yes | `params[:todo_id]` is already validated in `TodosController#delete` via `updatable_by?` per-item check |
| V6 Cryptography | no | CSRF token source changes from `data-authenticity_token` to `meta[name="csrf-token"]` — both are the same token value; no cryptographic change |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CSRF on POST /todos/delete | Tampering | Rails `protect_from_forgery` already active; token now sourced from `meta[name="csrf-token"]` — same defense, same token, just a different DOM source |
| Cross-user todo completion | Elevation of Privilege | `TodosController#delete` iterates `params[:todo_id]`, calls `updatable_by?(current_user)` per item, returns `head :not_found` on violation — already tested by `test_他人のタスクはバッチ削除できない` |

No new threat surface is introduced. The CSRF source change (`data-authenticity_token` on `.todo_actions` → `meta[name="csrf-token"]`) is security-neutral: both attributes hold identical token values, and the `meta` tag is already used elsewhere in the same JS file.

---

## Sources

### Primary (HIGH confidence)

- `app/assets/javascripts/todos.js` — full content read; all `.todo_actions` references enumerated
- `app/assets/stylesheets/todos.css.scss` — full content read; all `:not(.todo_actions)` selectors catalogued
- `app/assets/stylesheets/welcome.css.scss` — relevant sections read; `.todo-gadget-new-link` rule verified
- `app/views/welcome/_todo_gadget.html.erb` — full content read
- `app/views/common/_gadget_title_with_icon.html.erb` — full content read
- `app/views/todos/_actions.html.erb` — full content read
- `app/controllers/todos_controller.rb` — full content read; `delete` action logic confirmed
- `test/controllers/welcome_controller/dashboard_test.rb` — full content read; breaking assertions identified at lines 94 and 109
- `test/controllers/todos_controller_test.rb` — full content read
- `config/locales/ja.yml` / `en.yml` — `welcome.todo_gadget` sections read; `selected_count` key confirmed absent
- `test/i18n/locales_parity_test.rb` — parity test mechanism confirmed

### Secondary (MEDIUM confidence)

- `127-CONTEXT.md` — all locked decisions
- `127-UI-SPEC.md` — CSS measurements, component inventory, interaction state machine, CSS cleanup table

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing code inspected directly
- Architecture: HIGH — all relevant files read; change set is fully enumerated
- Pitfalls: HIGH — bugs identified by static analysis of the existing code (e.g., `closest('ol')` issue confirmed by reading todos.js line 138)
- i18n template approach: MEDIUM — see A1 in Assumptions Log; one console verification recommended

**Research date:** 2026-06-18
**Valid until:** Stable — this research is based on stable, committed code. Valid until any of the listed source files change.
