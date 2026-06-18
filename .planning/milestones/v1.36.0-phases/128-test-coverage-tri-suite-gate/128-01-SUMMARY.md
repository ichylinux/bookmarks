---
phase: 128-test-coverage-tri-suite-gate
plan: "01"
status: complete
requirements: [TEST-01, TEST-02, TEST-03]
---

# Phase 128 Plan 01 Summary

**One-liner:** Added Minitest coverage for header complete-group structure and TodosController#delete batch/no-op paths; Cucumber E2E for select→header complete→hide flow.

## Tasks Completed

| # | Task | Files |
|---|------|-------|
| 1 | Minitest structure + controller tests | dashboard_test.rb, todos_controller_test.rb |
| 2 | Cucumber E2E scenario + steps | 02.タスク.feature, todos.rb |
| 3 | Tri-suite gate | — |

## Verification

| Check | Result |
|-------|--------|
| `yarn run lint` | 0 errors |
| `bin/rails test` | 681 runs, 0 failures |
| `bundle exec rake dad:test` | 39 scenarios, 0 failures |

## New Coverage

- **TEST-01:** complete-group DOM structure (ja/en data-template), batch delete, todo_id absent no-op
- **TEST-02:** Cucumber「ヘッダの完了で選択したタスクを一括完了する」— selection count visible, bulk complete E2E
- **TEST-03:** tri-suite green at milestone close
