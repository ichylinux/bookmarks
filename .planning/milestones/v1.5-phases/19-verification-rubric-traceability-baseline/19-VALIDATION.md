---
phase: 19
slug: verification-rubric-traceability-baseline
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-03
---

# Phase 19 — Validation Strategy

> Documentation-phase validation: artifact structure + repo green bar. No Wave 0 code stubs required.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ESLint (yarn) + Rails Minitest + Cucumber via `dad:test` rake task |
| **Config file** | `eslint.config.js`, Rails default test layout |
| **Quick run command** | `yarn run lint` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | Environment-dependent (order of minutes with Cucumber) |

---

## Sampling Rate

- **After every task commit:** `yarn run lint`
- **After plan completion:** Full three-suite command above
- **Before marking phase complete:** Full suite must be green (per `CLAUDE.md`)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | VERF-01 / VERF-02 | — | N/A (docs) | doc + lint | `yarn run lint` | Rubric path | ⬜ pending |
| 19-01-02 | 01 | 1 | VERF-01 / VERF-02 | — | N/A (docs) | doc + full suite | Full suite | REQUIREMENTS + ROADMAP | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase behaviors. No new test stubs required for this documentation milestone.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rubric readability / maintainer sign-off | VERF-01 | Judgment on doc clarity | Peer review optional per CONTEXT D-07 |

---

## Validation Sign-Off

- [x] Rubric file committed with all mandatory sections
- [x] Canonical pointers updated (`REQUIREMENTS.md`, `ROADMAP.md` Plans line)
- [x] Full three-suite green at closure SHA
- [x] `nyquist_compliant` updated when execution waves complete

**Approval:** pending
