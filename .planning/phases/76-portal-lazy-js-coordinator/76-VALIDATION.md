---
phase: 76
slug: portal-lazy-js-coordinator
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-17
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (ActiveSupport::TestCase) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `yarn run lint` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~60 seconds (lint fast; Cucumber ~45s) |

---

## Sampling Rate

- **After every task commit:** Run `yarn run lint`
- **After every plan wave:** Run `yarn run lint && bin/rails test`
- **Before `/gsd:verify-work`:** Full tri-suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-01-01 | 01 | 1 | IMPL-01, LAZY-01–04, DESKTP-01–02 | T-76-01..T-76-05 | CSS property `parseInt` NaN-guarded; `loadedColumns` plain object (no prototype); no localStorage write | source assertion + lint | `yarn run lint && test -f app/assets/javascripts/portal_lazy.js && grep -q 'window.portalLazy' app/assets/javascripts/portal_lazy.js` | ❌ W0 (creating file) | ⬜ pending |
| 76-01-02 | 01 | 1 | LAZY-01–04, DESKTP-01–02 | — | Zero behavior regression | e2e (tri-suite gate) | `yarn run lint && bin/rails test && bundle exec rake dad:test` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `app/assets/javascripts/portal_lazy.js` — the coordinator module being created in Task 76-01-01

*Note: `test/assets/portal_lazy_js_contract_test.rb` is the formal Wave 0 contract test for `window.portalLazy`, but it is deferred to Phase 78 per traceability matrix. Phase 76 verification uses source assertions (grep) and tri-suite regression as proxies.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `window.portalLazy.register(0, fn)` and `window.portalLazy.loadColumn(0)` callable from browser console | IMPL-01 | No browser automation test exists yet (Phase 78 covers) | Open DevTools on `/` page; type `window.portalLazy.register(0, () => console.log('ok'))` then `window.portalLazy.loadColumn(0)`; confirm no error thrown |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: 2 tasks total, no 3-consecutive-unverified window
- [x] Wave 0 covers all MISSING references (portal_lazy.js created in Task 1)
- [x] No watch-mode flags
- [x] Feedback latency < 60s (lint is fast; tri-suite is ~45s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
