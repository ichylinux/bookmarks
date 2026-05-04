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

## Cucumber suite — known flakiness (as of 2026-05-01)

`bundle exec rake dad:test` exhibits intermittent scenario-order-dependent failures unrelated to any individual phase:
- Scenarios share DB state (no truncation between scenarios). One scenario's `preference.theme = 'simple'` or `use_note: true` updates can leak into a later scenario that assumes default state.
- Specific symptoms seen: `Unable to find checkbox "タスクを表示する"`, missing `.todo_actions` on `/`, missing `#notes-tab-panel`.

**Until this is fixed,** when verifying a phase: if `dad:test` fails, re-run once. A consistent failure across two runs indicates a real regression. A flake that disappears on re-run is pre-existing and tracked separately.

A future quick task should add proper between-scenario preference reset (e.g., a `Before` hook that re-creates the fixture user's preference to defaults).
