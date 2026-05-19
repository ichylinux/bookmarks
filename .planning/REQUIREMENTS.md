# Requirements: Bookmarks v1.27

**Defined:** 2026-05-19
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.27 Requirements

### Privacy Policy Page

- [x] **PRIV-01**: User can view a privacy policy page at `/privacy` without authentication
- [x] **PRIV-02**: Privacy policy content is available in both Japanese and English (locale YAML pattern matching the existing i18n infrastructure)
- [x] **PRIV-03**: Privacy policy covers data collected, purpose of X login, email address handling, and data retention

### Terms of Service Page

- [x] **TOS-01**: User can view a terms of service page at `/terms` without authentication
- [x] **TOS-02**: Terms of service content is available in both Japanese and English
- [x] **TOS-03**: Terms of service covers acceptable use, service availability, and account termination

### OAuth2 Email Scope

- [x] **OAUTH-01**: X OAuth2 sign-in requests the `email` scope
- [x] **OAUTH-02**: `User.from_omniauth` stores the real X email on new user creation instead of generating a dummy email
- [x] **OAUTH-03**: On re-authentication, `from_omniauth` overwrites an existing dummy-pattern email with the real X email

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
| PRIV-01 | Phase 89 | Satisfied |
| PRIV-02 | Phase 89 | Satisfied |
| PRIV-03 | Phase 89 | Satisfied |
| TOS-01 | Phase 89 | Satisfied |
| TOS-02 | Phase 89 | Satisfied |
| TOS-03 | Phase 89 | Satisfied |
| OAUTH-01 | Phase 90 | Satisfied |
| OAUTH-02 | Phase 90 | Satisfied |
| OAUTH-03 | Phase 90 | Satisfied |

**Coverage:**
- v1.27 requirements: 9 total
- Mapped to phases: 9 (Phase 89: 6, Phase 90: 3)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-19*
*Last updated: 2026-05-19 — all 9 requirements marked Satisfied after milestone audit (evidence: SUMMARY requirements-completed, passing tri-suites, UAT 7/7 Phase 89)*
