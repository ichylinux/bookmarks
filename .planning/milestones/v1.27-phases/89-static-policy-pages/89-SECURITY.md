---
phase: 89
slug: 89-static-policy-pages
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-19
---

# Phase 89 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Unauthenticated HTTP → PagesController | Any visitor can reach /privacy and /terms without a session | None — pages render static developer-authored content only |
| locale param → session write | ?locale=ja/en writes to session[:guest_locale] via Localization concern | Guest locale preference (non-sensitive) |
| ERB view → t() output | YAML-sourced content rendered into HTML | Static developer-controlled prose (no user input) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-89-01 | Elevation of Privilege | PagesController skip_before_action | mitigate | skip_before_action :authenticate_user! scoped to PagesController only; ApplicationController still enforces auth for all other controllers; no user data rendered on these pages | closed |
| T-89-02 | Tampering | locale param (session write) | accept | Localization concern validates locale against Preference::SUPPORTED_LOCALES allowlist; non-matching values silently ignored; no sensitive data in guest_session_locale | closed |
| T-89-03 | Tampering | YAML body text rendered via t() | accept | Rails t() HTML-escapes by default; simple_format auto-escapes; raw()/html_safe not used; YAML content is developer-controlled, not user input | closed |
| T-89-04 | Tampering (XSS) | simple_format(t("pages.*.body")) | accept | simple_format calls h() on input before wrapping in p tags; t() returns a plain String; no raw()/html_safe calls in either view (verified) | closed |
| T-89-05 | Information Disclosure | Policy page content | accept | Content is intentionally public; no user-specific data rendered; PagesController actions are empty (no instance variables) | closed |
| T-89-SC | Tampering | Package manager installs | accept | No npm/pip/cargo installs in this phase — package legitimacy gate not applicable | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-89-01 | T-89-02 | Locale param writes a non-sensitive guest preference to session; allowlist validation prevents unexpected values; no PII or auth state involved | gsd-secure-phase | 2026-05-19 |
| AR-89-02 | T-89-03 | t() output is developer-authored YAML prose rendered via Rails default HTML-escaping; raw() not used; no user input path exists | gsd-secure-phase | 2026-05-19 |
| AR-89-03 | T-89-04 | simple_format wraps developer-controlled t() strings; h() escaping confirmed; no raw()/html_safe in views | gsd-secure-phase | 2026-05-19 |
| AR-89-04 | T-89-05 | Policy pages are intentionally public content with no user-specific data; skip_before_action is the designed access model | gsd-secure-phase | 2026-05-19 |
| AR-89-05 | T-89-SC | No package manager installs in this phase | gsd-secure-phase | 2026-05-19 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-19 | 6 | 6 | 0 | gsd-secure-phase (register_authored_at_plan_time: true) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-19
