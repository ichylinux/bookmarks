---
phase: 59
slug: view-preferences-entry-locale-and-tests
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-13
---

# Phase 59 — Security

> Retroactive threat verification for v1.17 Phase 59 (email registration UI, preferences entry, locale, tests). Register authored at plan time in `059-01-PLAN.md`.

---

## Trust Boundaries

| Boundary | Description | Data crossing |
|----------|-------------|----------------|
| Browser (authenticated session) → Rails | Signed-in user; POST protected by CSRF | Session cookie, `email_registration[email]` |
| Rails → MySQL | Update of `users.email` for `current_user` | Email (PII) |
| Locale YAML → Views | Marketing/help copy | Version-controlled strings only |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-59-01 | Spoofing | `users/email_registration` | mitigate | `ApplicationController` → `before_action :authenticate_user!`; controller only loads `current_user` | closed |
| T-59-02 | Elevation of privilege | Dummy-only gate | mitigate | `Users::EmailRegistrationsController#require_dummy_email` redirects when `current_user.has_valid_email?` | closed |
| T-59-03 | Tampering | Email collision / race | mitigate | Uniqueness + `rescue ActiveRecord::RecordNotUnique` → `errors.add(:email, :taken)` and `422` (`email_registrations_controller_test.rb`) | closed |
| T-59-04 | Information disclosure | Errors / flash | mitigate | Model validation errors + `t('email_registrations.saved')`; `<%= message %>` escapes `full_messages` in `new.html.erb` | closed |
| T-59-05 | Tampering | Mass assignment | mitigate | `params.require(:email_registration).permit(:email)` | closed |
| T-59-06 | Tampering | CSRF on POST | mitigate | `form_with` on `new.html.erb` issues Rails authenticity token for `create` | closed |

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-13 | 6 | 6 | 0 | Cursor orchestrator (retroactive verify vs codebase) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-13
