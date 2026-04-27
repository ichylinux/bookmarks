---
phase: 3
slug: 03-modernize-application-scripts
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-27
---

# Phase 3 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser → Server | Ajax calls (`$.post`, `$.get`) in `feeds.js`, `bookmarks.js` | URL strings, feed title/id — low sensitivity, no auth tokens |
| Browser → localStorage | `bookmark_gadget.js` reads/writes expanded-folder state via `STORAGE_KEY` | JSON array of folder IDs — low sensitivity; now guarded by `try/catch` (CR-01 fix) |
| Sprockets bundle scope | `window.todos` / `window.feeds` / `window.calendars` shared across files via global namespace | Function references — internal only, no cross-origin exposure |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-3-01-A | Tampering | `app/assets/javascripts/*.js` global bindings | mitigate | `window.ns \|\| {}` + `const ns = window.ns` pattern applied; `yarn run lint` gate passed (03-01-SUMMARY) | closed |
| T-3-01-B | Denial of Service | Asset pipeline / Sprockets precompile | mitigate | `RAILS_ENV=production bin/rails assets:precompile` exit 0 verified (03-02-SUMMARY) | closed |
| T-3-02 | Tampering | jQuery event handlers (`bookmark_gadget.js`, `bookmarks.js`, `todos.js`) | mitigate | `function` expressions preserved for jQuery `this`-using handlers; arrow conversion only on non-`this` callbacks; `.delegate()` → `.on()` preserves `this` (WR-01 fix); lint passes | closed |
| T-3-03-A | Information Disclosure | Client-side scripts (style-only phase) | accept | Phase 01 is declaration-only (`var` → `const`/`let`); no behavioral changes; no new data paths introduced | closed |
| T-3-03-B | Tampering | `window.*` namespace (`todos`, `feeds`, `calendars`) | mitigate | No new globals introduced; existing namespaces documented in `CONVENTIONS.md`; STYL-03 comments added; WR-04 snapshot-semantics comment added (03-REVIEW-FIX) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-3-01 | T-3-03-A | Phase 3 Plan 01 is a mechanical declaration replacement (var → const/let). No behavioral changes were introduced, so no new client-side attack surface exists. | gsd-secure-phase (Claude) | 2026-04-27 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-27 | 5 | 5 | 0 | gsd-secure-phase (Claude, State B — from PLAN artifacts) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-27
