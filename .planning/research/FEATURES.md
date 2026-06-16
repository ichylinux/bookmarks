# Feature Research

**Domain:** Mastodon handle pre-registration for existing-user OAuth linking
**Researched:** 2026-06-16
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Preferences field to save Mastodon handle | User must declare identity before OAuth | LOW | Same form as other prefs; `PreferencesController#update` |
| OAuth signs into existing account when handle matches | Core milestone goal | MEDIUM | Extend `:mastodon` branch lookup order |
| Handle format validation with localized errors | Prevents garbage input | LOW | Reuse hostname rules from `MastodonInstanceNormalizer` |
| Successful OAuth still creates `OauthIdentity` row | Connected Accounts row shows linked | LOW | Existing `upsert_for!` after match |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Canonical handle normalization (`@user@host` → `user@host`) | Reduces user error | LOW | Strip leading `@`, downcase instance |
| Optional blank handle (clear unlink intent) | User can remove pre-registration | LOW | `allow_blank: true` |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-fill handle from Connected Accounts after link | Convenience | OAuth already stores composite uid; handle is pre-link only | Show read-only current handle when set |
| Match by username only (ignore instance) | Simpler UX | Federated Mastodon — same local name on different instances | Require full `user@instance` |
| Connect Mastodon from preferences without OAuth | IDNT-FUT-01 deferred | Out of milestone scope | Sign-in page OAuth only |

## Feature Dependencies

```
Preferences handle save
    └──requires──> users.mastodon_handle column (exists)
    └──requires──> MastodonHandleNormalizer + User validation

OAuth existing-user match
    └──requires──> Preferences handle save (user must register first)
    └──requires──> verify_credentials username + session instance
    └──enhances──> v1.35 composite uid identity wiring
```

## MVP Definition (v1.35.1)

### Launch With

- [ ] Preferences text field + save for `mastodon_handle`
- [ ] `User.from_omniauth` finds active user by normalized handle when composite uid not found
- [ ] OAuth-verified username+instance must match stored handle (security)
- [ ] Minitest for save, validation, match, and no-match-create paths
- [ ] ja/en locale keys

### Defer

- [ ] Auto-populate handle after first successful Mastodon OAuth — nice-to-have
- [ ] Admin UI for handle column — not needed (personal app)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Preferences save | HIGH | LOW | P1 |
| OAuth match by handle | HIGH | MEDIUM | P1 |
| Handle normalization | HIGH | LOW | P1 |
| Unique handle constraint | HIGH | LOW | P1 |
| Cucumber preferences field | MEDIUM | LOW | P2 |

---
*Feature research for: Mastodon handle linking*
*Researched: 2026-06-16*
