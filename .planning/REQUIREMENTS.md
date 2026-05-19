# Requirements: Bookmarks v1.27

**Defined:** 2026-05-19
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.27 Requirements

### Privacy Policy Page

- [ ] **PRIV-01**: User can view a privacy policy page at `/privacy` without authentication
- [ ] **PRIV-02**: Privacy policy content is available in both Japanese and English (locale YAML pattern matching the existing i18n infrastructure)
- [ ] **PRIV-03**: Privacy policy covers data collected, purpose of X login, email address handling, and data retention

### Terms of Service Page

- [ ] **TOS-01**: User can view a terms of service page at `/terms` without authentication
- [ ] **TOS-02**: Terms of service content is available in both Japanese and English
- [ ] **TOS-03**: Terms of service covers acceptable use, service availability, and account termination

### OAuth2 Email Scope

- [ ] **OAUTH-01**: X OAuth2 sign-in requests the `email` scope
- [ ] **OAUTH-02**: `User.from_omniauth` stores the real X email on new user creation instead of generating a dummy email
- [ ] **OAUTH-03**: On re-authentication, `from_omniauth` overwrites an existing dummy-pattern email with the real X email

## Future Requirements

_(none identified for this milestone)_

## Out of Scope

| Feature | Reason |
|---------|---------|
| Footer/nav links to privacy or ToS | Not required by X; links can be added later |
| Cookie consent banner | Overkill for a personal app with no tracking cookies |
| GDPR data export/deletion flow | Personal app; single-user; deferred |
| Rich policy editor / CMS | Static YAML-backed content is sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRIV-01 | — | Pending |
| PRIV-02 | — | Pending |
| PRIV-03 | — | Pending |
| TOS-01 | — | Pending |
| TOS-02 | — | Pending |
| TOS-03 | — | Pending |
| OAUTH-01 | — | Pending |
| OAUTH-02 | — | Pending |
| OAUTH-03 | — | Pending |

**Coverage:**
- v1.27 requirements: 9 total
- Mapped to phases: 0 (roadmap pending)
- Unmapped: 9 ⚠️

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 after initial definition*
