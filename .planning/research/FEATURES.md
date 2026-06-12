# Features Research: Mastodon OAuth 2.0 Sign-In

**Milestone:** v1.35
**Date:** 2026-06-12

## Table Stakes (must have)

| Feature | Notes |
|---------|-------|
| Sign in with Mastodon | OAuth 2.0 authorization code flow |
| Instance domain input | User specifies their home instance (e.g. `mastodon.social`) before redirect |
| Account identity | Composite key: instance domain + Mastodon account ID |
| Link to existing account | Re-auth updates `oauth_identities` row; find user by composite uid |
| Sign-in page button | Consistent with Google/X/Facebook OAuth button pattern |
| Connected Accounts row | Show linked/unlinked + disconnect (reuse v1.34 safety guard) |
| ja/en locale strings | Match existing auth UI i18n parity |

## Differentiators (nice, defer if costly)

| Feature | Defer to |
|---------|----------|
| Connect Mastodon from preferences (no sign-in) | v2 IDNT-FUT-01 |
| Auto-link to existing `mastodon_accounts` gadget rows | Future — separate data model |
| Remember last-used instance in cookie | v2 |

## Anti-Features (do not build)

| Feature | Why |
|---------|-----|
| Use OAuth1 Mastodon gems | OAuth 2.0 required; gems don't support it |
| Store OAuth token on `users` for gadget API | Gadget uses public RSS/API; auth token is for identity only |
| Multiple Mastodon accounts per user | `oauth_identities` unique on `(user_id, provider)` |
| Live OAuth round-trip in Cucumber CI | Facebook precedent: static presence check only |

## Dependencies on Existing Features

- v1.34 `OauthIdentity.upsert_for!` — reuse as-is
- v1.34 disconnect safety guard — applies to `mastodon` provider automatically
- v1.16 `mastodon_accounts` — separate feature; no coupling required this milestone
