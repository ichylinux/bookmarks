# Pitfalls Research

**Domain:** Mastodon handle linking for existing users
**Researched:** 2026-06-16
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Handle squatting without OAuth proof

**What goes wrong:**
User A registers `bob@mastodon.social`; User B completes OAuth as bob and gets signed into User A's account.

**Why it happens:**
Matching on stored handle alone without verifying OAuth credentials username+instance.

**How to avoid:**
At callback, build canonical handle from `raw_info['username']` + `info['instance']` and require exact match with candidate user's `mastodon_handle` before signing in.

**Warning signs:**
Test only checks DB lookup, not credential cross-check.

**Phase to address:**
Phase 125 (identity wiring)

---

### Pitfall 2: Duplicate handles across users

**What goes wrong:**
Two users save the same handle; OAuth match becomes ambiguous.

**Why it happens:**
Missing uniqueness validation/index on `users.mastodon_handle`.

**How to avoid:**
Add unique index on `mastodon_handle` (MySQL allows multiple NULLs) + model uniqueness validation `allow_nil: true`.

**Warning signs:**
`find_by(mastodon_handle:)` used without uniqueness guarantee.

**Phase to address:**
Phase 124 (data + validation)

---

### Pitfall 3: Instance mismatch on OAuth

**What goes wrong:**
User registers `alice@mastodon.social` but OAuth via `ruby.social` with same username links incorrectly.

**Why it happens:**
Matching username only or ignoring session instance.

**How to avoid:**
Full `localpart@instance` comparison; instance from OAuth session must match stored handle's domain.

**Warning signs:**
Tests mock OAuth without `info[:instance]`.

**Phase to address:**
Phase 125

---

### Pitfall 4: Linking to soft-deleted user

**What goes wrong:**
Deleted account resurrected via handle match.

**Why it happens:**
Lookup without `User.active` scope.

**How to avoid:**
Use `User.active.find_by(mastodon_handle: ...)` consistent with other `from_omniauth` branches.

**Phase to address:**
Phase 125

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Open redirect via handle input | Low (field is not URL) | Reject paths/schemes in normalizer |
| Account takeover via pre-registered handle | HIGH | OAuth proof required at callback |
| Case confusion on instance | MEDIUM | Downcase instance in normalizer |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Unclear handle format | Save errors | Placeholder `user@mastodon.social` ja/en |
| No explanation of pre-link step | User creates duplicate account | Help text: register handle before first Mastodon sign-in |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Handle squatting | Phase 125 | Minitest: wrong OAuth user does not match |
| Duplicate handles | Phase 124 | Model validation + DB unique index test |
| Instance mismatch | Phase 125 | Minitest with differing instances |
| Deleted user link | Phase 125 | Minitest with `deleted: true` user |

---
*Pitfalls research for: Mastodon handle linking*
*Researched: 2026-06-16*
