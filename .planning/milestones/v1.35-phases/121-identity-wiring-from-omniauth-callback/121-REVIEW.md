# Phase 121 Code Review

**Reviewed:** 2026-06-12  
**Depth:** standard  
**Scope:** Phase 121 changed files

## Files Reviewed

- `lib/omniauth/strategies/mastodon.rb`
- `app/models/user.rb`
- `app/controllers/users/omniauth_callbacks_controller.rb`
- `test/models/oauth_identity_test.rb`
- `test/controllers/users/omniauth_callbacks_controller_test.rb`
- `test/lib/omniauth/strategies/mastodon_test.rb`

## Summary

Implementation correctly wires Mastodon OAuth identity with composite uid `instance:account_id`, follows established `upsert_for!` patterns from Phase 114, and adds adequate Minitest coverage. No Critical or Warning findings requiring code changes.

## Findings

### Info

| # | File | Finding |
|---|------|---------|
| 1 | `app/models/user.rb` | If `info[:instance]` were blank at callback, composite uid would be malformed (`:account_id`). Mitigated by strategy `validate_mastodon_instance!` in `callback_phase` and Phase 120 session plumbing. No change needed for Phase 121 scope. |
| 2 | `test/controllers/users/omniauth_callbacks_controller_test.rb` | `Rails.application.routes.routes` preload in setup fixes nil `OmniAuth.config.path_prefix` before first callback request — defensive fix applicable to all providers in this test class. |

## Security

- Composite uid prevents cross-instance account ID collision (PITFALLS.md #1) — satisfied
- No new SSRF surface; instance validation remains Phase 120 responsibility

## Verdict

**APPROVED** — no fixes required.
