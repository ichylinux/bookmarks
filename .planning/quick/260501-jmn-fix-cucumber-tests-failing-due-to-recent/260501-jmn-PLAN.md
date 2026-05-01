---
quick_id: 260501-jmn
description: Fix cucumber test failure from Phase 15-01 redirect change; require dad:test green after each phase
date: 2026-05-01
---

# Quick 260501-jmn: Fix cucumber failure + dad:test policy

## Root Cause

Phase 15-01 (commit `ff7bf65`) changed `PreferencesController#update` redirect from `root_path` → `preferences_path` (D-11). The cucumber step `features/step_definitions/todos.rb:7` asserted `has_no_button?('保存')` after `click_on '保存'`, implicitly relying on the redirect away from /preferences. With the new behavior the form re-renders on /preferences and the 保存 button persists, so the assertion fails:

```
Expected false to be truthy. (Minitest::Assertion)
./features/step_definitions/todos.rb:7:in 'block in <main>'
```

`bundle exec rake dad:test`: 9 scenarios, 1 failed (`features/02.タスク.feature:5 タスクウィジェットを使用する`).

## Tasks

### T1 — Remove obsolete redirect-await assertion
- **File:** `features/step_definitions/todos.rb`
- **Change:** Delete `assert has_no_button?('保存')` on line 7. Capybara `click_on '保存'` already blocks on the form-submit response; the subsequent step (`click_on 'Bookmarks'`) provides the next synchronization point.
- **Verify:** scenario passes when running just that feature
- **Done:** `bundle exec rake dad:test` reports 0 failed scenarios

### T2 — Add CLAUDE.md policy: dad:test green after each phase
- **File:** `CLAUDE.md` (new)
- **Change:** Document that after each phase completion, `bundle exec rake dad:test` must pass alongside `bin/rails test`. List both as required green-bar checks before marking a phase complete.
- **Verify:** file exists, references `bundle exec rake dad:test`
- **Done:** future phase agents read this and run cucumber as part of phase verification

## Must-haves
- truths:
  - `features/step_definitions/todos.rb:7` no longer references `has_no_button?('保存')`
  - `CLAUDE.md` at repo root contains `bundle exec rake dad:test` policy
- artifacts:
  - `features/step_definitions/todos.rb`
  - `CLAUDE.md`
- key_links:
  - `app/controllers/preferences_controller.rb` (Phase 15-01 redirect change at `ff7bf65`)
  - `.planning/phases/04-verify-and-document/04-VALIDATION.md` (full-suite command reference)
