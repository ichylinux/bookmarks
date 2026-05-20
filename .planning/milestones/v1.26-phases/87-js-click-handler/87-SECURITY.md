---
phase: 87
slug: js-click-handler
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-18
---

# Phase 87 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| browser → Rails API | `$.post('/visited_links', { url })` — client-supplied URL crosses into server | URL string (user browsing intent); requires authenticated session |
| Cucumber test process → Rails Puma server | Browser AJAX calls hit the embedded test server; WebMock stubs server-side outbound HTTP | Test-only HTTP stubs; no production data |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-87-01 | Tampering | Optimistic `.link--visited` class | accept | Display-only class; server `visited_links` is authoritative; reload corrects from DB | closed |
| T-87-02 | Information Disclosure | `$.post` sends visited URL to server | accept | Intentional product behavior; endpoint gated by authentication (unauthenticated does not persist) | closed |
| T-87-03 | Spoofing | Client can POST arbitrary URL strings | mitigate | Server: `VisitedLink.normalize_url`, `url` limited to 2083 chars, unique `(user_id, url)` index; `record!` uses normalized URL (Phase 84) | closed |
| T-87-04 | Tampering | WebMock stub override for feed URL | accept | Scoped to `@feed_visited_links`; After hook removes stub; production unaffected | closed |
| T-87-05 | Tampering | `execute_script` navigation intercept in tests | accept | Cucumber-only; prevents Capybara navigation during assertion; no production code | closed |
| T-87-SC | Tampering | npm/pip/cargo installs | accept | No new runtime deps in Phase 87 plans | closed |

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-87-01 | T-87-01 | Optimistic CSS class may diverge briefly from DB; reload restores truth; no privilege or integrity impact beyond UX | Phase plan | 2026-05-18 |
| AR-87-02 | T-87-02 | Recording visited URLs is the feature goal | Phase plan | 2026-05-18 |
| AR-87-03 | T-87-04 | Test-local WebMock ordering; cleaned up per scenario | Phase plan | 2026-05-18 |
| AR-87-04 | T-87-05 | Test harness only | Phase plan | 2026-05-18 |
| AR-87-05 | T-87-SC | No supply-chain surface change in this phase | Phase plan | 2026-05-18 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-18 | 6 | 6 | 0 | gsd-secure-phase (orchestrator) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-18
