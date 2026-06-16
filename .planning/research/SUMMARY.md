# Project Research Summary

**Project:** Bookmarks
**Domain:** Mastodon handle pre-registration for existing-user OAuth linking
**Researched:** 2026-06-16
**Confidence:** HIGH

## Executive Summary

v1.35 delivered Mastodon OAuth sign-in with composite uid identity storage, but existing users cannot link their Mastodon account without creating a new Bookmarks user. The fix is a thin vertical slice: persist a canonical `user@instance` handle on `users` (column already migrated), expose it on `/preferences`, and extend `User.from_omniauth` `:mastodon` to resolve existing users by verified handle before falling back to user creation.

No new gems or OAuth infrastructure are required. Reuse `MastodonInstanceNormalizer` patterns for a new `MastodonHandleNormalizer`, add uniqueness on `mastodon_handle`, and verify OAuth callback username+instance matches the stored handle to prevent handle squatting.

## Key Findings

### Recommended Stack

Existing Rails 8.1 + Devise/OmniAuth stack only. New code: normalizer service, model validation, preferences field, `from_omniauth` lookup branch.

### Expected Features

**Must have:**
- Preferences save for `mastodon_handle`
- OAuth match to existing user by verified handle
- Normalization and uniqueness

**Defer:**
- Auto-fill handle after OAuth
- Connect-from-preferences (IDNT-FUT-01)

### Architecture Approach

Lookup order for `:mastodon`: (1) composite uid via `oauth_identities`, (2) `mastodon_handle` on active user with OAuth proof, (3) create new user.

### Critical Pitfalls

1. **Handle squatting** — require OAuth username+instance proof at callback
2. **Duplicate handles** — unique index on `mastodon_handle`
3. **Instance mismatch** — full `user@instance` comparison, not username alone
4. **Deleted users** — `User.active` scope on lookup

## Implications for Roadmap

### Phase 124: Handle data layer + preferences UI
**Rationale:** User must register handle before OAuth can match  
**Delivers:** Normalizer, validation, unique index, preferences field, locales, save tests  
**Avoids:** Duplicate handles, invalid format

### Phase 125: OAuth identity wiring by handle
**Rationale:** Depends on persisted handle  
**Delivers:** `from_omniauth` branch, security cross-check, Minitest  
**Avoids:** Squatting, instance mismatch, deleted-user link

### Phase 126: Verification gate (optional tri-suite)
**Rationale:** Project green-bar policy  
**Delivers:** Cucumber/preferences smoke if needed, tri-suite run  
**Avoids:** Regressions in connected accounts

### Research Flags

- **Phase 125:** Standard — follows v1.35 `from_omniauth` pattern
- **Phase 124:** Standard — mirrors email registration / preference field patterns

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new dependencies |
| Features | HIGH | User goal explicit |
| Architecture | HIGH | Codebase patterns exist |
| Pitfalls | HIGH | Classic account-linking risks |

**Overall confidence:** HIGH

---
*Research completed: 2026-06-16*
*Ready for roadmap: yes*
