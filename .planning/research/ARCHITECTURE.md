# Architecture Research

**Domain:** Mastodon handle linking (Bookmarks brownfield)
**Researched:** 2026-06-16
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌──────────────── Preferences ─────────────────┐
│  form_with @user → PreferencesController#update │
│  permits :mastodon_handle                       │
│  MastodonHandleNormalizer → users.mastodon_handle │
└────────────────────┬──────────────────────────┘
                     │ save
┌────────────────────▼──────────────────────────┐
│              User (ActiveRecord)               │
│  mastodon_handle (canonical user@instance)     │
│  from_omniauth :mastodon lookup chain:         │
│    1) oauth_identities composite uid           │
│    2) mastodon_handle match (verified)         │
│    3) create new user (fallback)               │
└────────────────────┬──────────────────────────┘
                     │ OAuth callback
┌────────────────────▼──────────────────────────┐
│  OmniAuth::Strategies::Mastodon                │
│  raw_info username + session instance          │
│  → OauthIdentity.upsert_for!                   │
└────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `MastodonHandleNormalizer` | Parse/validate `user@instance` | New service mirroring `MastodonInstanceNormalizer` |
| `User` validations | Uniqueness, format on update | `validates :mastodon_handle, allow_blank: true` |
| `PreferencesController` | Strong params + save | Add `:mastodon_handle` to `user_params` |
| `User.from_omniauth` | Identity resolution | Insert handle lookup between composite uid and create |

## Recommended Project Structure

```
app/
├── services/mastodon_handle_normalizer.rb   # NEW
├── models/user.rb                           # validation + from_omniauth branch
├── controllers/preferences_controller.rb    # permit mastodon_handle
└── views/preferences/index.html.erb         # text field row

config/locales/ja.yml, en.yml                # label, placeholder, errors
test/
├── services/mastodon_handle_normalizer_test.rb
├── models/user_test.rb                      # from_omniauth handle match
└── controllers/preferences_controller_test.rb # save round-trip
```

## Data Flow

### Pre-registration Flow

```
User enters "@alice@mastodon.social" on /preferences
    → POST preference_path
    → MastodonHandleNormalizer → "alice@mastodon.social"
    → users.mastodon_handle persisted
```

### OAuth Link Flow

```
User starts Mastodon OAuth (instance in session)
    → verify_credentials returns username "alice"
    → composite_uid = "mastodon.social:12345"
    → lookup oauth_identities (existing v1.35)
    → if miss: lookup User.active by mastodon_handle == "alice@mastodon.social"
    → verify instance+username match stored handle
    → upsert OauthIdentity, sign in user
```

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Handle field ↔ OAuth strategy | Indirect via DB | Strategy must expose `info[:nickname]` or use `raw_info` in `from_omniauth` |
| Handle ↔ `MastodonAccount` gadget | None | Gadget follows profile URLs; separate from auth handle |

## Anti-Patterns

### Anti-Pattern 1: Trust handle match without OAuth verification

**What people do:** Match DB handle only from session instance user typed earlier  
**Why it's wrong:** Attacker could register another user's handle if not verified at callback  
**Do this instead:** Compare `verify_credentials` username + OAuth instance against stored handle at callback time

### Anti-Pattern 2: Case-sensitive instance comparison

**What people do:** Store `User@Mastodon.Social` literally  
**Why it's wrong:** Mastodon instances are case-insensitive domains  
**Do this instead:** Downcase instance segment in normalizer

---
*Architecture research for: Mastodon handle linking*
*Researched: 2026-06-16*
