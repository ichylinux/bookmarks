---
status: passed
phase: 94-tests-tri-suite-gate
verified_at: "2026-05-20"
---

# Phase 94 — Tests & Tri-suite Gate: Verification

## Must-haves (from ROADMAP success criteria)

| Check | Result | Evidence |
|-------|--------|----------|
| Minitest covers soft-delete (deleted flag + deleted_at set) | ✅ | `test/models/user_test.rb` — asserts `deleted: true` and `deleted_at` present after `destroy_account!` |
| Minitest covers auth block (deleted user cannot sign in) | ✅ | `test/models/user_test.rb` — asserts `active_for_authentication?` returns `false` for deleted user |
| Minitest covers PII anonymization (email + OAuth tokens cleared) | ✅ | `test/models/user_test.rb` — asserts email anonymized, `provider`/`uid`/OAuth token fields nulled |
| Minitest covers transactional rows still present after deletion | ✅ | `test/models/user_test.rb` — asserts Note and Bookmark row counts unchanged after `destroy_account!` |
| Minitest covers confirmation gate (wrong token renders form without deleting) | ✅ | `test/controllers/users/account_deletions_controller_test.rb` — POST with wrong confirmation renders `:new`, no `destroy_account!` called |
| Minitest covers successful deletion flow (sign out + redirect) | ✅ | `test/controllers/users/account_deletions_controller_test.rb` — DELETE with `confirmation=DELETE` calls `destroy_account!`, signs out, redirects to root |
| Cucumber covers end-to-end deletion from preferences page | ✅ | `features/09.アカウント削除.feature` — scenario navigates preferences → danger zone → confirmation form → submits DELETE → verifies signed out |
| Cucumber step definitions implement the full deletion flow | ✅ | `features/step_definitions/account_deletion.rb` — steps for preferences navigation, confirmation input, form submit, post-deletion state |
| Cucumber hooks support account deletion scenario isolation | ✅ | `features/support/hooks.rb` — `@account_deletion` tag uses `rack_test` driver for reliable DELETE form submit |
| Tri-suite is fully green | ✅ | STATE.md: `yarn run lint` ✓ · `bin/rails test` 500/500 ✓ · `bundle exec rake dad:test` 28/28 ✓ |

## Automated gates (tri-suite)

| Gate | Command | Result |
|------|---------|--------|
| Lint | `yarn run lint` | ✅ exit 0 |
| Minitest | `bin/rails test` | ✅ 500/500 |
| Cucumber | `bundle exec rake dad:test` | ✅ 28/28 |

## Coverage notes

**ACCT-07 — Transactional row-count assertions partial (tracked tech debt):**
`test/models/user_test.rb` asserts row-count preservation for Notes and Bookmarks only. Eight other table types (feeds, todos, portals, portal_layouts, preferences, mastodon_accounts, x_accounts, visited_links) lack explicit count-preservation assertions. Implementation is correct by inspection: `destroy_account!` uses `update!` on the `users` row, so no cascade fires regardless of `has_many` dependent settings. Adding count assertions for the remaining 8 table types is tracked as future test-coverage improvement, not a blocker.

**ACCT-04 — Google OAuth post-deletion blocking untested (tracked tech debt):**
The Minitest and Cucumber suites cover Twitter/X OAuth blocking after deletion. There is no dedicated test for Google OAuth post-deletion blocking. The code path is correct (`User.active.where(email:)` excludes anonymized email for all providers), but test coverage for the Google provider specifically is absent. Tracked as tech debt from Phase 92.

## Overall verdict

**PASSED** — retroactive verification; implementation shipped in `de956cd`, tri-suite green.
