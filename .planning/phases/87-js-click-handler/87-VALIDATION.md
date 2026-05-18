---
phase: 87
slug: js-click-handler
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-18
---

# Phase 87 — Validation Strategy

> Nyquist validation reconstructed from PLAN/SUMMARY/VERIFICATION (State B). Gaps filled during `/gsd-validate-phase 87`: Cucumber steps hardened + `rails-ujs`/jQuery load order corrected so `$.post` receives CSRF.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ESLint · Minitest (ActiveSupport::TestCase contract tests + IntegrationTest) · Cucumber + Capybara + Selenium (via `dad:test`) |
| **Config file** | `eslint.config.mjs`; Cucumber via `features/support/env.rb` (daddy) |
| **Quick run command** | `yarn run lint && bin/rails test test/assets/visited_links_js_contract_test.rb` |
| **Full suite command** | `yarn run lint && bin/rails test && bundle exec rake dad:test` |
| **Estimated runtime** | ~80–120s (full tri-suite on typical hardware) |

---

## Sampling Rate

- **After every task commit:** `yarn run lint` on touched JS; targeted `bin/rails test test/assets/visited_links_js_contract_test.rb` after visited_links edits
- **After wave / phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Max feedback latency:** bounded by full Cucumber run (~60–75s)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 87-01-T1 | 01 | 1 | JS-01, JS-02 | T-87-01–03 | Delegated handler posts normalized URL; server authoritative | lint | `yarn run lint` | ✅ | ✅ green |
| 87-01-T2 | 01 | 1 | JS-01, JS-02 | T-87-03 | Structural CSRF/post/url contract via source read | unit | `bin/rails test test/assets/visited_links_js_contract_test.rb` | ✅ | ✅ green |
| 87-02-T1 | 02 | 2 | JS-01 (E2E infra) | T-87-04 | Tagged WebMock stub scoped + cleaned up | e2e (infra) | `bundle exec rake dad:test` | ✅ | ✅ green |
| 87-02-T2 | 02 | 2 | JS-01, JS-02 | T-87-05 | E2E optimistic class + reload persistence | e2e | `bundle exec rake dad:test` | ✅ | ✅ green |

*Status: ✅ green · ⚠️ flaky (document in CLAUDE.md rerun policy)*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 stubs required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| — | — | — | *All phase behaviors have automated verification.* |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing suite coverage
- [x] Sampling continuity: contract + lint between JS edits; full gate at wave close
- [x] No watch-mode flags in automated commands
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-18

---

## Validation Audit 2026-05-18

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |

**Resolved (summary):**

1. **Cucumber selectors** — `.gadget ol li a:first` targeted non-feed gadgets; steps now key off stub article title + `stub-article` href sanity check + JS `href` property comparison for capture-phase intercept and class checks.
2. **`bundle exec rake dad:test` persistence scenario** — `$.post` silently failed CSRF because `rails-ujs` loaded before `jquery`, so jQuery AJAX never received the CSRF prefilter; fixed `application.js` order (`jquery` → `rails-ujs`) and simplified `visited_links.js` to `{ url: url }` only.
3. **Contract test** — Replaced manual `authenticity_token` assertions with “URL-only POST + refute `authenticity_token`” to match rails-ujs responsibility.
