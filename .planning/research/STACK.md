# Stack Research

**Domain:** Mastodon handle linking for existing Bookmarks users (brownfield extension)
**Researched:** 2026-06-16
**Confidence:** HIGH

## Recommended Stack

### Core Technologies (no additions)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Rails | 8.1 | MVC, ActiveRecord, Devise/OmniAuth | Already powers auth and preferences |
| Devise + OmniAuth | existing | Mastodon OAuth callback | v1.35 custom strategy already live |
| MySQL | existing | `users.mastodon_handle` persistence | Column migration already added |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `MastodonInstanceNormalizer` | in-repo | Hostname validation | Reuse for handle instance segment parsing |
| `OauthIdentity.upsert_for!` | in-repo | Link Mastodon identity after match | Same as v1.35 composite uid flow |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Minitest | Model/controller tests for handle save + `from_omniauth` match | Extend existing `oauth_identity_test.rb` patterns |
| Cucumber `dad:test` | Preferences UI smoke | Optional row for handle field; no live OAuth |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `users.mastodon_handle` string column | Separate `mastodon_identities` table | Only if multiple handles per user needed (out of scope) |
| Normalizer service class (`MastodonHandleNormalizer`) | Inline regex in model | Normalizer preferred — mirrors `MastodonInstanceNormalizer` |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New OAuth gems | v1.35 custom strategy is OAuth 2.0 | Extend `User.from_omniauth` `:mastodon` branch |
| WebFinger lookup at save time | Adds network dependency to preferences save | Trust user input format; verify at OAuth callback via `verify_credentials` |
| Storing handle only in `oauth_identities` | Pre-OAuth link requires user-level field | `users.mastodon_handle` (already migrated) |

## Stack Patterns by Variant

**If handle input accepts `@user@instance` or URL forms:**
- Normalize to canonical `localpart@hostname` before save
- Because OAuth callback compares against `raw_info['username']` + session instance

## Sources

- `.planning/PROJECT.md` — v1.35 Mastodon OAuth decisions
- `db/migrate/20260616125530_add_column_mastodon_handle_on_users.rb` — column exists
- `lib/omniauth/strategies/mastodon.rb` — `info[:instance]`, `raw_info['username']`

---
*Stack research for: Mastodon handle linking*
*Researched: 2026-06-16*
