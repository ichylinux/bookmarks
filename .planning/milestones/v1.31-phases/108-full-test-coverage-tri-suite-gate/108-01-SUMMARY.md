---
phase: 108
plan: 01
status: complete
commit: b489a28
---

# Summary: Phase 108-01 — Cucumber E2E Coverage for X Manual-Add

## What was built

Added Cucumber E2E test coverage for the v1.31 X account manual-add feature (built in Phases 104–107).

### Artifacts

**`features/support/hooks.rb`** — `@x_manual_add` Before/After hooks added:
- Before: sets user credentials (`provider: 'twitter2', uid: 'x_manual_uid_host', oauth2_token: 'manual_add_token'`), stubs 3 WebMock endpoints (lookup success, lookup 404, following for refresh — all regex to handle query params)
- After: removes all 3 stubs, deletes `XAccount` records for user, resets user credential columns

**`features/07.X手動追加.feature`** — new feature file with 2 Japanese scenarios:
1. Happy-path: enter `testhandle` → account card appears → click Refresh → card still visible
2. Not-found: enter `ghost_user` → not-found flash (`データが見つかりませんでした。`) appears

**`features/step_definitions/x_accounts.rb`** — 6 new step definitions appended:
- Visit x_accounts page
- Fill handle input (by placeholder `@handle`)
- Click `追加` submit button
- Assert account text visible (`assert_text`, wait: 10)
- Click `フォロー一覧を更新` refresh button
- Assert not-found flash (`assert_text`, wait: 5)

### Key fix during implementation
Initial WebMock stubs used exact string URLs. `XClient#lookup_user_by_username` appends `?user.fields=...` as a query param, causing WebMock to reject the request as unregistered. Fixed by switching to regex stubs (consistent with all other stubs in `hooks.rb`).

## Tri-suite gate results

| Suite | Result |
|-------|--------|
| `yarn run lint` | ✓ 0 errors |
| `bin/rails test` | ✓ 546 runs, 0 failures, 0 errors |
| `bundle exec rake dad:test` | ✓ 33 scenarios, 0 failures |
