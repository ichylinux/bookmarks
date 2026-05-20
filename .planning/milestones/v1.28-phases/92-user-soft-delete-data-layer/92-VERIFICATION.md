---
status: passed
phase: 92-user-soft-delete-data-layer
verified_at: "2026-05-20"
---

# Phase 92 — User Soft-Delete Data Layer: Verification

## Must-haves (from ROADMAP success criteria)

| Check | Result | Evidence |
|-------|--------|----------|
| Migration adds `deleted` (boolean, default false) and `deleted_at` (datetime, nullable) on `users` | ✅ | `db/migrate/20260519164758_add_soft_delete_to_users.rb` — adds both columns; confirmed in `db/schema.rb` |
| `User#destroy_account!` sets deleted flags, clears OAuth tokens, and anonymizes email | ✅ | `app/models/user.rb` — `destroy_account!` sets `deleted: true`, `deleted_at: Time.current`; nulls `provider`, `uid`, `oauth2_token`, `oauth2_refresh_token`, `oauth2_token_expires_at`; anonymizes email to UUID placeholder; randomizes password |
| Deleted user fails `active_for_authentication?` check | ✅ | `app/models/user.rb` — `active_for_authentication?` returns `false` when `deleted?`; verified by `test/models/user_test.rb` |
| OAuth re-auth with same identity is blocked (deleted user cannot sign in via OAuth) | ✅ | `app/models/user.rb` — `User.active` scope (`where(deleted: false)`) excludes deleted users; `from_omniauth` resolves via `User.active.where(email:)` — anonymized email never matches |
| Transactional rows (Bookmark, Note, etc.) unchanged after soft-delete | ✅ | `app/models/user.rb` — `destroy_account!` uses `update!`, not `destroy`; no cascade fires; row counts asserted in `test/models/user_test.rb` for Notes and Bookmarks |

## Automated gates (tri-suite)

| Gate | Command | Result |
|------|---------|--------|
| Lint | `yarn run lint` | ✅ exit 0 |
| Minitest | `bin/rails test` | ✅ 500/500 |
| Cucumber | `bundle exec rake dad:test` | ✅ 28/28 |

## Coverage notes

**ACCT-04 — Google OAuth post-deletion test gap (tracked tech debt):**
`active_for_authentication?` and `User.active` scope correctly block re-auth for all OAuth providers because email is anonymized. However, the test suite covers Twitter/X OAuth blocking specifically; there is no dedicated test for Google OAuth post-deletion blocking. Code is correct by inspection — this is a test-coverage gap, not a behavioral gap.

**ACCT-06 — Transactional row-count assertions partial (tracked tech debt):**
`test/models/user_test.rb` asserts count preservation for Notes and Bookmarks only. Eight other table types (feeds, todos, portals, portal_layouts, preferences, mastodon_accounts, x_accounts, visited_links) lack explicit count-preservation assertions. These are correct by inspection: `destroy_account!` uses `update!` on the `users` row, so no cascade fires regardless of table type. This is a test-coverage gap, not an implementation gap. Tracked alongside the `has_many :x_accounts, dependent: :destroy` fragility note (safe because soft-delete never calls `destroy` on user).

## Overall verdict

**PASSED** — retroactive verification; implementation shipped in `de956cd`, tri-suite green.
