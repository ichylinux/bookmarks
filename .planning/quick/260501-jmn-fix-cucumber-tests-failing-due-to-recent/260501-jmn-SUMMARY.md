---
quick_id: 260501-jmn
description: Fix cucumber test failure from Phase 15-01 redirect change; require dad:test green after each phase
date: 2026-05-01
status: complete
---

# Quick 260501-jmn — Summary

## Root cause

Phase 15-01 (`ff7bf65`) changed `PreferencesController#update` redirect from `root_path` → `preferences_path` (D-11, "rerender same /preferences page in new locale after save"). The cucumber step at `features/step_definitions/todos.rb:7` had been asserting `has_no_button?('保存')` after `click_on '保存'` — silently relying on the redirect taking the browser away from /preferences. With the new behavior the form re-renders in place and the 保存 button persists, so the assertion failed:

```
Expected false to be truthy. (Minitest::Assertion)
./features/step_definitions/todos.rb:7
```

## Changes

| File | Change |
|------|--------|
| `features/step_definitions/todos.rb` | Removed obsolete `assert has_no_button?('保存')` after `click_on '保存'`. Capybara `click_on` already blocks on the form-submit response; the next step (`click_on 'Bookmarks'`) provides the next sync point. |
| `CLAUDE.md` (new) | Added phase verification policy: lint + Minitest + `bundle exec rake dad:test` must all be green before marking a phase complete. Documented known cucumber flakiness for the workflow. |

## Verification

`bundle exec rake dad:test` — repeated runs after the fix:

| Run | Result | Notes |
|-----|--------|-------|
| 1 | 9/9 pass | seed 53836 |
| 2 | 9/9 pass | seed 52677 |
| 3 | 9/9 pass | seed 20649 |
| 4 | 9/9 pass | seed 7966 |
| Flake A | 1 failed (`#notes-tab-panel`) | seed 50260 — pre-existing scenario-order flake, unrelated to fix |
| Flake B | 2 failed (checkbox / `.todo_actions`) | seed 18915 — pre-existing scenario-order flake, unrelated to fix |

Without the fix the widget scenario fails deterministically every run; with the fix it passes. Remaining intermittents are pre-existing isolation issues between scenarios (preference state leaks, e.g. `preference.theme = 'simple'` set by notes scenario persists into later scenarios). Documented in `CLAUDE.md` as a follow-up.

## Follow-ups (not in this quick task)

- Add a Cucumber `Before` hook to reset the fixture user's `preference` to defaults between scenarios. Once added, the "re-run on flake" guidance in `CLAUDE.md` can be removed.

## Commits

- `d5311a6` — fix(quick-260501-jmn): drop obsolete redirect-await assertion in todos cucumber step (`features/step_definitions/todos.rb`)
- `03c892c` — docs(quick-260501-jmn): add CLAUDE.md with phase verification policy (`CLAUDE.md`)
