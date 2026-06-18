---
phase: 127-header-integrated-task-completion
verified: 2026-06-19T12:00:00Z
status: passed
score: 3/3 phase-scope truths verified
behavior_unverified: 3
overrides_applied: 0
deferred:
  - truth: "Header complete group visibility toggle at runtime (HDR-02)"
    deferred_to: "Phase 128"
    reason: "Phase 127 scope excludes new automated tests; Phase 128 TEST-01/TEST-02 schedule Minitest + Cucumber coverage"
  - truth: "Live selection count update in header (HDR-03)"
    deferred_to: "Phase 128"
    reason: "Runtime DOM-mutation invariant; Phase 128 adds automated assertions"
  - truth: "Bulk complete via header 完了 at runtime (SEL-02)"
    deferred_to: "Phase 128"
    reason: "Full select→POST→hide flow; Phase 128 Cucumber E2E scenario"
behavior_unverified_items:
  - truth: "A 完了 / Complete action sits in the gadget header and is visible only when at least one row is selected (HDR-01, HDR-02)"
    test: "Load the dashboard with todo items, click one todo row, observe the header area"
    expected: ".todo-gadget-complete-group transitions from display:none to inline-flex; deselect returns to hidden"
    why_human: "Code wired; automated runtime assertion deferred to Phase 128 per phase scope"
  - truth: "The header shows the current selection count and the text follows selection/deselection (HDR-03)"
    test: "Select rows, observe count increment/decrement"
    expected: "Count driven by _updateCompleteGroup replacing %{count} in data-template"
    why_human: "Code wired; automated runtime assertion deferred to Phase 128"
  - truth: "Clicking the header 完了 marks all selected todos done via POST /todos/delete (SEL-02)"
    test: "Select two rows, click header 完了, observe list"
    expected: "POST /todos/delete, rows hidden, count resets"
    why_human: "Code wired; Cucumber E2E deferred to Phase 128"
human_verification:
  - test: "Select a todo row, click highlight button — checkmark and header count preserved"
    expected: "li.selected and span.selected remain; header count unchanged after toggle_highlight re-render"
    result: "PASSED — operator confirmed OK after 127-02 gap fix"
---

# Phase 127: Header-Integrated Task Completion Verification Report

**Phase Goal:** タスクガジェットの「完了」操作がヘッダに集約され、現在の選択件数が見え、独立したアクション行が消えて縦スペースが回収される
**Verified:** 2026-06-19T12:00:00Z
**Status:** passed
**Re-verification:** Yes — after 127-02 gap closure (highlight/selection bug)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Row click toggles span.selected; `.todo_actions` row gone; vertical space reclaimed (SEL-01, LAY-01) | VERIFIED | Click handler todos.js:81–86; no `render 'todos/actions'` in _todo_gadget.html.erb; `_actions.html.erb` deleted; 0 `todo_actions` in app/ |
| 2 | Highlight toggle preserves completion selection across AJAX re-render (127-02 gap, SEL-01) | VERIFIED | `wasSelected` capture + re-apply at todos.js:113–125; `_updateCompleteGroup(ol)` at line 125; operator manual validation PASSED |
| 3 | 完了 in gadget header; visible only when ≥1 row selected (HDR-01, HDR-02) | PRESENT_BEHAVIOR_UNVERIFIED → deferred Phase 128 | CSS `display:none` default (welcome.css.scss:319); JS show/hide wired (_updateCompleteGroup). Static structure verified; runtime toggle test deferred to Phase 128 |
| 4 | Header shows selection count following select/deselect (HDR-03) | PRESENT_BEHAVIOR_UNVERIFIED → deferred Phase 128 | `data-template` in _todo_gadget.html.erb:22; `_updateCompleteGroup` at todos.js:95–108. Runtime count mutation test deferred to Phase 128 |
| 5 | Header 完了 bulk-completes selected todos via POST /todos/delete; empty selection no-op (SEL-02) | PRESENT_BEHAVIOR_UNVERIFIED → deferred Phase 128 | `delete_todos` rewritten todos.js:160–179 with guard at line 174; runtime E2E deferred to Phase 128 |
| 6 | selected_count copy in ja/en; locale parity passes (I18N-01) | VERIFIED | ja.yml:323, en.yml:323; dashboard_test.rb:94,109 assert `.todo-gadget-complete-link` |

**Score:** 3/3 phase-scope truths verified (3 runtime behaviors deferred to Phase 128 by design)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/views/welcome/_todo_gadget.html.erb` | Header complete group; no actions partial | VERIFIED | `todo-gadget-complete-group` at line 18; no `render 'todos/actions'` |
| `config/locales/ja.yml` / `en.yml` | `welcome.todo_gadget.selected_count` | VERIFIED | Both keys present at line 323 |
| `app/assets/stylesheets/welcome.css.scss` | Complete group styles | VERIFIED | `.todo-gadget-complete-group { display: none }` at line 319 |
| `app/assets/javascripts/todos.js` | `_updateCompleteGroup`, `delete_todos`, `toggle_highlight` selection preserve | VERIFIED | All symbols present; `wasSelected` in toggle_highlight |
| `app/views/todos/_actions.html.erb` | Deleted | VERIFIED | File absent; 0 references |
| `app/views/common/_gadget_title_with_icon.html.erb` | `complete_group:` slot | VERIFIED | Lines 15–17 |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `_todo_gadget.html.erb` | `todos.js` | DOM selectors + data-template | WIRED |
| `todos.js` | `todos_controller.rb` | POST delete_todos_path | WIRED |
| `todos.js` | `todos.js` | toggle_highlight → _updateCompleteGroup after replaceWith | WIRED |

### Behavioral Verification

| Check | Result | Status |
|-------|--------|--------|
| `yarn run lint` | 0 errors | PASS |
| `bin/rails test` | 679 runs, 0 failures | PASS |
| `bundle exec rake dad:test` | 38 scenarios, 0 failures | PASS |
| `grep -rn 'todo_actions' app/` | 0 matches | PASS |
| `grep 'wasSelected' todos.js` | Line 113 | PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| HDR-01 | SATISFIED | Complete link in header |
| HDR-02 | SATISFIED (static) / runtime test Phase 128 | CSS + JS wired |
| HDR-03 | SATISFIED (static) / runtime test Phase 128 | data-template + _updateCompleteGroup |
| LAY-01 | SATISFIED | `.todo_actions` removed |
| SEL-01 | SATISFIED | Selection preserved including across highlight toggle |
| SEL-02 | SATISFIED (static) / runtime test Phase 128 | delete_todos rewritten |
| I18N-01 | SATISFIED | ja/en keys + dashboard assertions |

### Anti-Patterns Found

None.

### Deferred Items (Phase 128)

| Concern | Deferred To | Rationale |
|---------|-------------|-----------|
| Runtime header visibility toggle | Phase 128 | TEST-01 Minitest + TEST-02 Cucumber |
| Runtime selection count update | Phase 128 | TEST-01 |
| Runtime bulk-complete E2E | Phase 128 | TEST-02 Cucumber scenario |

### Gaps Summary

No gaps. Gap closure (127-02) resolved the highlight/selection interaction bug. All artifacts present and wired. Tri-suite green.

---

_Verified: 2026-06-19T12:00:00Z_
_Re-verification after 127-02 gap closure_
