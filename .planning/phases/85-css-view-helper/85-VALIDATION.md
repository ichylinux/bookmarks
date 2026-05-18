---
phase: 85
slug: css-view-helper
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-18
---

# Phase 85 — Validation Strategy

> Reconstructed from `85-01-PLAN.md`, `85-01-SUMMARY.md`, and `85-VERIFICATION.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (`ActionView::TestCase`) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/helpers/application_helper_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~2–3 min (full gate) |

---

## Sampling Rate

- **After every task commit:** `bin/rails test test/helpers/application_helper_test.rb`
- **After plan wave:** `yarn run lint && bin/rails test`
- **Before `/gsd-verify-work`:** Full gate per `CLAUDE.md`
- **Max feedback latency:** ~180 s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 85-01-01 | 01 | 1 | VIS-01 | T-85-03 | Gadget-only `.gadget a.link--visited`; specificity without `!important` | contract / grep | `grep -c 'link--visited' app/assets/stylesheets/common.css.scss`; `bin/rails test test/helpers/application_helper_test.rb` (CSS contract) | ✅ | ✅ green |
| 85-01-02 | 01 | 1 | VIS-02 | T-85-01–02 | Helper returns fixed class tokens only; normalizes via `VisitedLink.normalize_url` | unit | `bin/rails test test/helpers/application_helper_test.rb` | ✅ | ✅ green |

---

## Wave 0 Requirements

Existing Rails helper tests cover VIS-01/VIS-02; no Wave 0 stubs.

---

## Manual-Only Verifications

All phase 85 behaviors have automated verification (helper unit tests + SCSS source contract).

---

## Validation Sign-Off

- [x] All tasks mapped to automated commands
- [x] Sampling continuity: helper test file is the fast feedback path
- [x] Wave 0 N/A
- [x] No watch-mode flags
- [x] `nyquist_compliant: true`

**Approval:** approved 2026-05-18

---

## Validation Audit — 2026-05-18

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Retrofill complete — VIS-01/VIS-02 already fully exercised by `application_helper_test.rb` prior to this audit.
