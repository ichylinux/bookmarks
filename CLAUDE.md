# Project: Bookmarks

## Test commands

Three suites must be considered:

| Suite | Command | Purpose |
|-------|---------|---------|
| Lint | `yarn run lint` | ESLint |
| Minitest | `bin/rails test` | Unit + integration |
| Cucumber | `bundle exec rake dad:test` | E2E (custom rake task — spawns Rails server + headless Chrome automatically; do **not** use `bundle exec cucumber` directly) |

Full local check: `yarn run lint && bin/rails test && bundle exec rake dad:test`

## Phase verification policy

After completing each phase (and before marking it complete in `.planning/STATE.md` / `ROADMAP.md`), all three suites above must pass:

1. `yarn run lint` — green
2. `bin/rails test` — green
3. `bundle exec rake dad:test` — **green (0 failed scenarios)**

Cucumber is part of the green-bar gate. Do not declare a phase "complete" if `dad:test` reports failures attributable to the phase's changes.

## Cucumber suite — flakiness status (resolved 2026-05-19)

Scenario-order-dependent failures caused by preference state leakage were fixed in `bce47df`: Cucumber step definitions now use browser-driven form submissions (`/preferences` UI) for preference changes instead of direct ActiveRecord writes. This eliminates the cross-connection snapshot problem that previously caused `Unable to find checkbox "タスクを表示する"`, missing `.todo_actions`, and missing `#notes-tab-panel` failures.

`dad:test` should be consistently green. If it fails, re-run once — a consistent failure across two runs indicates a real regression.
