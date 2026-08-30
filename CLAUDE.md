# Project: Bookmarks

## Test commands

Three suites must be considered:

| Suite | Command | Purpose |
|-------|---------|---------|
| Lint | `yarn run lint` | ESLint |
| Minitest | `bin/rails test` | Unit + integration |
| Cucumber | `bundle exec rake dad:test` | E2E (custom rake task — spawns Rails server + headless Chrome automatically; do **not** use `bundle exec cucumber` directly) |

## Test scoping policy (IMPORTANT)

**Never run `bin/rails test` or `bundle exec rake dad:test` in full. Run only the tests related to the change.**

Full suites take a long time, and failures unrelated to the change bury the feedback that matters. **Jenkins covers the full suites** — `Jenkinsfile` runs `bundle exec rails test` in its `unit` stage and triggers the downstream `-features` job, whose `Jenkinsfile.features` runs `bundle exec rake dad:test`.

### How to scope a run

| Target | Example |
|---|---|
| Minitest — one file | `bin/rails test test/controllers/todos_controller_test.rb` |
| Minitest — one line | `bin/rails test test/controllers/todos_controller_test.rb:42` |
| Minitest — by name | `bin/rails test test/controllers/todos_controller_test.rb -n /一覧/` |
| Minitest — one directory | `bin/rails test test/models` |
| Cucumber — one feature | `bundle exec rake dad:test features/02.タスク.feature` |
| Cucumber — one scenario (line) | `bundle exec rake dad:test features/02.タスク.feature:23` |

`dad:test` forwards any feature paths it receives (line numbers included) straight to cucumber. Called with no arguments it runs all of `features`, so **always pass a path**.

To check step-definition resolution quickly without running a browser, add `DRY_RUN=1`:
`DRY_RUN=1 bundle exec rake dad:test features/02.タスク.feature`

`yarn run lint` is fast — keep running it in full.

### Choosing the related tests

Work outward from the files you changed:

- Model / controller changed → the matching test file under `test/**`
- View / CSS / JS changed → the `features/*.feature` covering that screen
- Step definition changed → every feature using that step

When the right scope is unclear, do not widen the run to be safe — **state which tests you chose and why** in your report.

## Phase verification policy

Gate for marking a phase complete (before recording it in `.planning/STATE.md` / `.planning/ROADMAP.md`):

1. `yarn run lint` — green (full run; Jenkins does not run lint)
2. `bin/rails test <related tests>` — green
3. `bundle exec rake dad:test <related features>` — **green (0 failed scenarios)**

**Green related tests are enough to call the task complete.** Do not hold work open waiting on a full-suite run — Jenkins is the safety net for regressions outside the scoped set.

Cucumber remains part of the gate at this scope: do not declare a phase "complete" while a *related* Cucumber scenario is failing.

State which tests you ran in the completion report, so the scope you chose is reviewable.

## Cucumber suite — flakiness status (resolved 2026-05-19)

Scenario-order-dependent failures caused by preference state leakage were fixed in `bce47df`: Cucumber step definitions now use browser-driven form submissions (`/preferences` UI) for preference changes instead of direct ActiveRecord writes. This eliminates the cross-connection snapshot problem that previously caused `Unable to find checkbox "タスクを表示する"`, missing `.todo_actions`, and missing `#notes-tab-panel` failures.

`dad:test` should be consistently green. If it fails, re-run once — a consistent failure across two runs indicates a real regression.
