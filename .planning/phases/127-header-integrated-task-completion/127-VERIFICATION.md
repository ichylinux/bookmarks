---
phase: 127-header-integrated-task-completion
verified: 2026-06-18T15:21:28Z
status: human_needed
score: 2/5 must-haves verified
behavior_unverified: 3
overrides_applied: 0
behavior_unverified_items:
  - truth: "A 完了 / Complete action sits in the gadget header and is visible only when at least one row is selected (HDR-01, HDR-02)"
    test: "Load the dashboard with todo items, click one todo row, observe the header area"
    expected: ".todo-gadget-complete-group transitions from display:none to inline-flex; clicking a second time deselects and the group returns to hidden"
    why_human: "The CSS default (display:none) and JS toggle (css/hide) are both present and wired, but the state transition at runtime is not exercised by any existing Minitest or Cucumber assertion. Phase 128 will add this coverage."
  - truth: "The header shows the current selection count (「N件選択中」 / \"N selected\") and the text follows selection/deselection (HDR-03)"
    test: "Select 1 todo row, observe the count text; select a second row, observe the count increment; deselect one, observe decrement"
    expected: "Count span shows \"1件選択中\" → \"2件選択中\" → \"1件選択中\" driven by _updateCompleteGroup replacing %{count} in data-template"
    why_human: "The data-template attribute, _updateCompleteGroup helper, and click-handler call are all wired in code. The live count update is a runtime DOM-mutation invariant not exercised by any current test."
  - truth: "Clicking the header 完了 marks all selected todos done:true via POST /todos/delete and hides them from the gadget list (SEL-02)"
    test: "Select two todo rows, click the header 完了 link, observe both rows disappear from the list"
    expected: "$.post to /todos/delete with collected todo_id[], success callback hides the rows and calls _updateCompleteGroup to reset the count and hide the group"
    why_human: "delete_todos structure (closest-ol fallback, meta CSRF, empty-selection guard, success callback) is all verified statically. The full state transition — todos disappear and count resets — is a runtime behavior. Phase 128 will add Minitest + Cucumber E2E coverage."
human_verification:
  - test: "Select one or more todo rows on the dashboard and verify the header 完了 / Complete action appears"
    expected: ".todo-gadget-complete-group becomes visible (inline-flex) when at least one row is selected; invisible when zero are selected"
    why_human: "The CSS hide-by-default rule and JS show/hide are present and wired, but no automated assertion exercises the visibility toggle at runtime."
  - test: "Select N todos, observe the header count text; deselect one, verify the count decrements"
    expected: "Count text reads \"N件選択中\" / \"N selected\" and updates correctly on each click"
    why_human: "The data-template attribute and _updateCompleteGroup %{count} replacement are wired, but the live DOM mutation is not covered by any current test."
  - test: "Select two todo rows, click header 完了, verify both rows disappear from the gadget list and the count group hides"
    expected: "POST /todos/delete fires with the two collected todo_id values; success callback hides the rows and resets the header count to hidden"
    why_human: "The full bulk-complete runtime flow (select → POST → hide → reset) is not exercised by any current automated assertion. Phase 128 schedules this coverage."
---

# Phase 127: Header-Integrated Task Completion Verification Report

**Phase Goal:** タスクガジェットの「完了」操作がヘッダに集約され、現在の選択件数が見え、独立したアクション行が消えて縦スペースが回収される
**Verified:** 2026-06-18T15:21:28Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Clicking a todo row still toggles span.selected checkmark — selection behavior unchanged; old .todo_actions row gone and vertical space reclaimed (SEL-01, LAY-01) | VERIFIED | Click handler on `'li span:first-child'` at todos.js:81–86 calls `toggleClass('selected')` on both span and parent li. No `render 'todos/actions'` in _todo_gadget.html.erb. `_actions.html.erb` deleted. Zero `todo_actions` references across all of `app/`. |
| 2 | A 完了 / Complete action sits in the gadget header (same row as 追加) and is visible only when at least one row is selected (HDR-01, HDR-02) | PRESENT_BEHAVIOR_UNVERIFIED | CSS `.todo-gadget-complete-group { display: none; }` is present (welcome.css.scss:319). JS `_updateCompleteGroup` shows it via `$group.css('display','inline-flex')` (todos.js:104) and hides via `$group.hide()` (todos.js:106). Code is present and wired. The CSS-hidden-by-default prohibition is statically verified. The runtime visibility transition is not exercised by any existing test. |
| 3 | The header shows the current selection count (「N件選択中」 / "N selected") and the text follows selection/deselection (HDR-03) | PRESENT_BEHAVIOR_UNVERIFIED | `data-template` baked from `t('welcome.todo_gadget.selected_count', count: '%{count}')` at _todo_gadget.html.erb:22. `_updateCompleteGroup` reads `$countEl.data('template')` and replaces `%{count}` with count (todos.js:103). All wiring present. Live count-update is a runtime DOM-mutation invariant not covered by any current test. |
| 4 | Clicking the header 完了 marks all selected todos done:true via POST /todos/delete and hides them from the gadget list; empty-selection click is a no-op (SEL-02) | PRESENT_BEHAVIOR_UNVERIFIED | `todos.delete_todos` rewritten with closest-ol fallback (todos.js:154–156), meta CSRF (todos.js:161), `todo_id[]` collection from `li.selected`, empty-selection guard `if (params.todo_id.length === 0) return;` (todos.js:166), success callback calls `_updateCompleteGroup(ol)` (todos.js:169). Static code structure verified. Empty-selection no-op is statically confirmed. Full runtime bulk-complete state transition not tested by current suite. |
| 5 | The new selected_count copy renders in both ja and en, and the locale key parity test passes (I18N-01) | VERIFIED | `ja.yml:323` has `selected_count: "%{count}件選択中"`. `en.yml:323` has `selected_count: "%{count} selected"`. Both keys are under `welcome.todo_gadget`. Parity test (`locales_parity_test.rb`) flattens all dotted keys from both files and asserts equality — the structure is sound and would catch any asymmetry. Dashboard test assertions at dashboard_test.rb:94 and :109 assert `.todo-gadget-complete-link` renders with text `完了` (ja) / `Complete` (en), count 1. Tri-suite reported green (bin/rails test 679 runs, 0 failures). |

**Score:** 2/5 truths verified (3 present + wired but behavior-unverified — Phase 128 schedules test coverage)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/views/welcome/_todo_gadget.html.erb` | Header renders complete group; `render 'todos/actions'` removed | VERIFIED | Contains `todo-gadget-complete-group` span at line 18. No `render 'todos/actions'`. `render todo` loop preserved. |
| `config/locales/ja.yml` | `welcome.todo_gadget.selected_count` key (ja) | VERIFIED | Line 323: `selected_count: "%{count}件選択中"` |
| `config/locales/en.yml` | `welcome.todo_gadget.selected_count` key (en) | VERIFIED | Line 323: `selected_count: "%{count} selected"` |
| `app/assets/stylesheets/welcome.css.scss` | Complete group / count / complete-link styles; `.todo-gadget-complete-link` in shared rule without `margin-left:auto` or `opacity` | VERIFIED | Lines 287–299: shared visual rule includes `.todo-gadget-complete-link`. Lines 302–311: new-link-only rule (`margin-left:auto`, `opacity:0`) excludes `.todo-gadget-complete-link`. Lines 319–332: `.todo-gadget-complete-group { display:none; ... }` and `.todo-gadget-selected-count` rules present. |
| `app/assets/javascripts/todos.js` | `todos._updateCompleteGroup` helper; rewritten `todos.delete_todos`; `ol.prepend` in `new_todo`; count update in click handler | VERIFIED | `_updateCompleteGroup` at lines 95–108. `delete_todos` rewritten at lines 152–171 with closest-ol fallback, meta CSRF, empty-selection guard. `ol.prepend` at line 130. Click handler calls `_updateCompleteGroup` at line 85. |
| `app/views/todos/_actions.html.erb` (deleted) | No longer rendered | VERIFIED | File does not exist on filesystem. Zero `todo_actions` references found anywhere in `app/`. |
| `app/views/common/_gadget_title_with_icon.html.erb` | Optional `complete_group:` local slot | VERIFIED | Lines 15–17: `<% if local_assigns[:complete_group] %> <%= complete_group %> <% end %>` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `_todo_gadget.html.erb` | `todos.js` | Header complete group exposes `.todo-gadget-complete-group` / `.todo-gadget-selected-count` / `.todo-gadget-complete-link` and `data-template`; `todos.js` reads and toggles them | WIRED | DOM selectors are present in ERB (lines 18–29). `_updateCompleteGroup` finds `.todo-gadget-complete-group` via `.closest('.gadget.todo').find(...)` (todos.js:97–99). Click handler at line 84–85 passes the `ol` to `_updateCompleteGroup`. |
| `todos.js` | `todos_controller.rb` | `todos.delete_todos` posts collected `todo_id[]` to `delete_todos_path` (POST /todos/delete) | WIRED | `$.post(url, params, ...)` at todos.js:167. `url` is `$trigger.attr('href')` where trigger is the `.todo-gadget-complete-link` pointing to `delete_todos_path`. |
| `_todo_gadget.html.erb` | `config/locales/ja.yml` | Count span `data-template` baked from `t('welcome.todo_gadget.selected_count', count: '%{count}')` | WIRED | ERB line 22 calls the translation key. Key exists in ja.yml:323 and en.yml:323. |

### Data-Flow Trace (Level 4)

Not applicable — this phase moves UI elements and JS wiring; it introduces no new data-fetching layer. The backend data source (`TodosController#delete`) is unchanged from prior phases and was already verified.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Zero `todo_actions` references in app/ | `grep -rn 'todo_actions' app/` | 0 matches | PASS |
| `_actions.html.erb` deleted | `ls app/views/todos/_actions.html.erb` | No such file | PASS |
| `_updateCompleteGroup` defined in todos.js | `grep '_updateCompleteGroup' todos.js` | Line 95: function definition | PASS |
| Empty-selection guard present | `grep 'length === 0' todos.js` | Line 166: `if (params.todo_id.length === 0) return;` | PASS |
| `ol.prepend` in `new_todo` | `grep 'prepend' todos.js` | Line 130: `ol.prepend('<li>' + html + '</li>')` | PASS |
| Closest-ol fallback in `delete_todos` | `grep -A3 'closest.*ol.*length' todos.js` | Lines 154–156: ternary fallback | PASS |
| Prohibition: `.todo-gadget-complete-group { display: none }` on load | `grep -A3 'todo-gadget-complete-group' welcome.css.scss` | Line 320: `display: none;` | PASS |
| Prohibition: empty-selection no-op | `grep 'length === 0' todos.js` | Line 166: early return | PASS |
| Dashboard assertions updated | `grep 'todo-gadget-complete-link' dashboard_test.rb` | Lines 94, 109: assert `.todo-gadget-complete-link` with correct text | PASS |
| JS DOM-interaction behaviors (toggle, count, bulk complete) exercised by automated test | No test exists in current suite; Phase 128 schedules coverage | No assertion found | SKIP (deferred to Phase 128) |

Tri-suite status (reported by orchestrator, all green): `yarn run lint` 0 errors; `bin/rails test` 679 runs / 0 failures; `bundle exec rake dad:test` 38/38 scenarios passed.

### Probe Execution

No phase-declared probes. Conventional acceptance checks from PLAN `<verification>` block:

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Lint | `yarn run lint` | 0 errors | PASS (orchestrator-reported) |
| Full Minitest | `bin/rails test` | 679 runs, 0 failures | PASS (orchestrator-reported) |
| Cucumber E2E | `bundle exec rake dad:test` | 38 scenarios, 0 failures | PASS (orchestrator-reported) |
| Dead-class cleanup | `grep -rn 'todo_actions' app/` | 0 matches | PASS (verified directly) |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| HDR-01 | 完了アクションをヘッダ行に配置 | VERIFIED | `.todo-gadget-complete-link` rendered in `_gadget_title_with_icon` header slot |
| HDR-02 | 完了は1件以上選択時のみ表示 | PRESENT_BEHAVIOR_UNVERIFIED | CSS `display:none` default + JS toggle present and wired; runtime visibility not tested |
| HDR-03 | ヘッダに選択件数を表示・追従 | PRESENT_BEHAVIOR_UNVERIFIED | `data-template` + `_updateCompleteGroup` wired; live count not tested |
| LAY-01 | `.todo_actions` 行を廃止、縦スペース回収 | VERIFIED | `render 'todos/actions'` removed; `_actions.html.erb` deleted; 0 `todo_actions` references |
| SEL-01 | 既存選択挙動（span.selected）を維持 | VERIFIED | Click handler on `li span:first-child` with `toggleClass('selected')` unchanged; tri-suite green |
| SEL-02 | ヘッダ完了で全選択タスク完了・未選択は無操作 | PRESENT_BEHAVIOR_UNVERIFIED | `delete_todos` rewritten with guard; runtime bulk-complete not tested by current suite |
| I18N-01 | ja/en ロケールキーパリティ | VERIFIED | Both keys present; parity test structure sound; dashboard assertions updated |

### Anti-Patterns Found

No anti-patterns found. Scan results:

- `grep -rn 'TBD\|FIXME\|XXX' {modified files}` — 0 matches
- `grep -rn 'todo_actions' app/` — 0 matches (all dead references removed)
- `grep -n 'return null\|return \[\]\|return {}' todos.js` — no stub returns
- `grep -n 'placeholder\|not yet implemented' {modified files}` — 0 matches

### Human Verification Required

#### 1. Header Complete Group Visibility Toggle (HDR-02)

**Test:** Load the dashboard with at least one incomplete todo item. Click a todo row to select it.
**Expected:** The `.todo-gadget-complete-group` span (containing the count and 完了 link) transitions from hidden to visible (inline-flex). Deselect the row — the group returns to hidden.
**Why human:** The CSS `display:none` default is statically verified. The JS `_updateCompleteGroup` show/hide calls are code-wired. The actual runtime state transition (hidden → visible → hidden) is not exercised by any current Minitest or Cucumber assertion. Phase 128 will add this coverage.

#### 2. Live Selection Count Update (HDR-03)

**Test:** Select 1 todo row, read the count text in the header. Select a 2nd row, read again. Deselect the first, read again.
**Expected:** Count text reads "1件選択中" → "2件選択中" → "1件選択中" (ja) or "1 selected" → "2 selected" → "1 selected" (en), driven by `_updateCompleteGroup` replacing `%{count}` in the `data-template` attribute.
**Why human:** The `data-template` attribute and `_updateCompleteGroup` replacement logic are present and wired. The live DOM mutation sequence (increment and decrement) is a runtime invariant not covered by any existing test.

#### 3. Bulk Complete via Header 完了 (SEL-02)

**Test:** Select two todo items, click the header 完了 link, observe the gadget list.
**Expected:** Both selected rows disappear from the gadget list. The header count group returns to hidden (count resets to 0). In the database, both todos have `done: true`.
**Why human:** `todos.delete_todos` is structurally correct — closest-ol fallback, CSRF from meta tag, `todo_id[]` collection, empty-selection guard, success callback with `_updateCompleteGroup`. The empty-selection no-op is statically confirmed. But the full state transition (select → POST → server marks done → client hides rows → count resets) is not exercised by any automated assertion in the current suite. Phase 128 schedules Minitest + Cucumber E2E coverage for this flow.

### Gaps Summary

No gaps found. All artifacts are present, substantive, and wired. All key links are confirmed. No dead references, no stub patterns, no anti-pattern debt markers.

The three `PRESENT_BEHAVIOR_UNVERIFIED` truths (SC2, SC3, SC4) reflect the deliberate Phase 127 scope decision: no new automated tests are added in this phase — Phase 128 (Test Coverage and Tri-Suite Gate) schedules dedicated Minitest assertions and a Cucumber E2E scenario for the runtime JS behaviors. The code delivering those behaviors is fully present and wired.

---

_Verified: 2026-06-18T15:21:28Z_
_Verifier: Claude (gsd-verifier)_
