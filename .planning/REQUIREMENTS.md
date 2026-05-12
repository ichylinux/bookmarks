# Requirements: Bookmarks v1.17 — Email Registration for X/Twitter Users

**Defined:** 2026-05-13
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.17 Requirements

### Email Registration (EMAIL)

- [ ] **EMAIL-01**: Devise `:validatable` format and uniqueness validation applies correctly to the email update path (confirmed scope; no new validator code needed beyond what Devise provides)

### Controller & Route (CTRL)

- [ ] **CTRL-01**: User who signed up via X/Twitter (dummy email) can register a real email address via a dedicated `EmailRegistrationsController` with `new` and `create` actions
- [ ] **CTRL-02**: User receives a clear error when submitting an email address already registered to another account (collision guard prevents silent account takeover)
- [ ] **CTRL-03**: User who already has a real email is redirected away from the registration form (form is not accessible once `has_valid_email?` is true)

### View & UX (VIEW)

- [ ] **VIEW-01**: Preferences page displays an email registration entry point (link or inline row) visible only to users with a dummy email (`!has_valid_email?`)
- [ ] **VIEW-02**: User sees a localized success flash message after successfully registering their email address

### Locale & Tests (I18N)

- [ ] **I18N-01**: ja/en locale keys for email registration form labels, error messages, and success flash are added to both `ja.yml` and `en.yml` with parity (parity test enforces both files simultaneously)
- [ ] **TEST-01**: Minitest integration tests cover model validation paths, controller guard (dummy-only access), and collision scenario

## Future Requirements

### Email Confirmation

- **CONF-01**: Email ownership confirmed via confirmation email before activating the address
- **CONF-02**: Unconfirmed email shown separately until confirmed (`unconfirmed_email` pattern)

### Account Merging

- **MERGE-01**: User can merge a Twitter account and an existing Google account that share the same email (migrates bookmarks, notes, todos, feeds, mastodon_accounts, preferences)

### Extended Testing

- **E2E-01**: Cucumber E2E scenario: sign in as Twitter user → preferences → register email → verify Google OAuth available

## Out of Scope

| Feature | Reason |
|---------|--------|
| Email confirmation via Devise `:confirmable` | No `users` confirmation columns exist; SMTP not confirmed for production; out of scope for v1.17 |
| Account merging for collision case | Requires migrating multiple associated models — separate milestone |
| Cucumber E2E scenario | Deferred; Minitest integration coverage is sufficient for this milestone |
| Standalone email registration root page | Entry point via preferences page is sufficient |
| Fixing Twitter `from_omniauth` name-based lookup bug | Pre-existing issue; must not be mixed into this PR |
| Allowing real-email users to change their email | This feature is specifically for dummy-email users registering for the first time |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EMAIL-01 | TBD | Pending |
| CTRL-01 | TBD | Pending |
| CTRL-02 | TBD | Pending |
| CTRL-03 | TBD | Pending |
| VIEW-01 | TBD | Pending |
| VIEW-02 | TBD | Pending |
| I18N-01 | TBD | Pending |
| TEST-01 | TBD | Pending |

**Coverage:**
- v1.17 requirements: 8 total
- Mapped to phases: 0 (TBD — roadmapper assigns)
- Unmapped: 8 ⚠ (pending roadmap)

---
*Requirements defined: 2026-05-13*
*Last updated: 2026-05-13 after initial definition*
