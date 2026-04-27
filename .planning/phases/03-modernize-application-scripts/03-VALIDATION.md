---
phase: 3
slug: modernize-application-scripts
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-27
---

# Phase 3 — Validation Strategy

> Per-phase validation for modernizing Sprockets-first-party JavaScript (ESLint + optional Rails build).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (JS)** | ESLint 9 + Babel parser (preconfigured) |
| **Framework (app)** | Minitest (unchanged; Phase 3 should not add Ruby changes) |
| **Quick run command** | `yarn run lint` |
| **Full suite command** | `yarn run lint` then `RAILS_ENV=production bin/rails assets:precompile` (see README) |
| **Optional app test** | `bin/rails test` when Ruby touched |

---

## Sampling Rate

- **After every task that touches `app/assets/javascripts`:** `yarn run lint` (target < 30s)
- **After wave / before closing STYL-04:** `assets:precompile` per plan
- **Max feedback latency:** 120s for precompile (environment-dependent)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A (client style) | static | `yarn run lint` | ✅ | ⬜ |
| 3-01-02 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A | static | `yarn run lint` | ✅ | ⬜ |
| 3-01-03 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A | static | `yarn run lint` | ✅ | ⬜ |
| 3-01-04 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A | static | `yarn run lint` | ✅ | ⬜ |
| 3-01-05 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A | static | `yarn run lint` | ✅ | ⬜ |
| 3-01-06 | 01 | 1 | STYL-01 | T-3-01 / N/A | N/A | static | `yarn run lint` + `! rg '\\bvar\\b' app/assets/javascripts` (except `eslint-disable`) | ✅ | ⬜ |
| 3-02-01 | 02 | 1 | STYL-02, DOCS-01 | T-3-02 / N/A | N/A (docs) | review | `grep` conventions heading | ✅ | ⬜ |
| 3-02-02 | 02 | 1 | STYL-02, STYL-03 | T-3-02 / N/A | N/A | static | `yarn run lint` | ✅ | ⬜ |
| 3-02-03 | 02 | 1 | STYL-04 | T-3-01 / N/A | N/A | build | `RAILS_ENV=production bin/rails assets:precompile` | ✅ | ⬜ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ESLint + `yarn run lint` from Phase 2 — no new test framework install
- [x] `babel.config.js` / `eslint.config.mjs` present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bookmark title auto-fill | VERI-02 (Phase 4) / STYL-04 smoke | Browser + server | After precompile: new bookmark form, blur URL, title field fills when server returns title |
| Todo / feed / calendar gadgets | STYL-02 / UJS | Server-rendered + JS | Open portal; double-click / actions per existing flows, no console errors |
| `.js.erb` responses | STYL-02 | Browser | Todo update / create paths that replace HTML via AJAX (see `app/views/todos/*.js.erb`) |

*Phase 3 plans focus on static + precompile; full UAT is Phase 4 / verify-work.*

---

## Validation Sign-Off

- [ ] All tasks have `yarn run lint` or precompile in verify path
- [ ] `nyquist_compliant: true` set in frontmatter when strategies proven in execution
- [ ] `wave_0_complete: true` remains accurate (lint infra exists)

**Approval:** pending
