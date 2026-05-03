# Phase 05 Verification (Theme Foundation)

**Status:** passed  
**Phase:** 05-theme-foundation  
**Requirements in scope:** THEME-01, THEME-02, THEME-03  
**Verified commit SHA:** `802897cbbd6807e1d754b736f54f93a1076905fc`  
**Recorded at:** 2026-05-03T20:34:21+09:00

---

## Baseline runs

| Suite | Command | Outcome | Evidence |
|---|---|---|---|
| Lint | `yarn run lint` | PASS | `eslint "app/assets/javascripts/**/*.js"` completed with exit code 0 |
| Minitest | `bin/rails test` | PASS | `192 runs, 1105 assertions, 0 failures, 0 errors, 0 skips` |
| Cucumber (run 1) | `bundle exec rake dad:test` | FAIL | `9 scenarios (2 failed, 7 passed)` |
| Cucumber (run 2) | `bundle exec rake dad:test` | PASS | `9 scenarios (9 passed)` |
| Combined full check | `yarn run lint && bin/rails test && bundle exec rake dad:test` | PASS (with allowed one-rerun handling for `dad:test`) | Per-suite logs + rerun table below |

### Flake / rerun log

| Run | Command | Outcome | Classification |
|---|---|---|---|
| 1 | `bundle exec rake dad:test` | FAIL (`features/02.タスク.feature` scenario-order failures) | Pre-existing flake candidate |
| 2 | `bundle exec rake dad:test` | PASS | Classified as pre-existing flake per `CLAUDE.md` one-rerun policy |

Policy pointer: see `CLAUDE.md` section **"Cucumber suite — known flakiness"**.

---

## Core traceability table

| Claim ID | REQ-ID(s) | Claim summary | Status | Confidence | Evidence block |
|---|---|---|---|---|---|
| P05-C01 | THEME-01 | User can choose modern theme from preferences screen | PASS | MEDIUM | § P05-C01 |
| P05-C02 | THEME-02 | `themes/modern.css.scss` exists with `.modern {}` scope and tokenized theme rules | PASS | HIGH | § P05-C02 |
| P05-C03 | THEME-03 | `menu.js` uses strict `body.modern` guard for drawer logic | PASS | HIGH | § P05-C03 |

---

### P05-C01 — Preferences screen offers modern theme selection

- **Requirement rows:** THEME-01 — "User can select 'modern' theme from the preferences screen"
- **Evidence type:** automated test + code reference
- **Artifact:**
  - `test/controllers/preferences_controller_test.rb:163` (`assert_select 'option', text: 'モダン'`)
  - `test/controllers/preferences_controller_test.rb:178` (`assert_select 'option', text: 'Modern'`)
  - `app/views/preferences/index.html.erb:15` (`f.select :theme` includes `'modern'`)
- **Run record:** baseline runs section (`bin/rails test` PASS)
- **Confidence:** MEDIUM — selection option visibility is covered directly; end-to-end UI persistence is tracked by manual fallback steps below.

### P05-C02 — modern.scss contract exists with modern scope and tokenized styling

- **Requirement rows:** THEME-02 — "`themes/modern.css.scss` exists with `.modern {}` scope and CSS custom property design tokens"
- **Evidence type:** automated test + code reference
- **Artifact:**
  - `test/assets/modern_full_page_theme_contract_test.rb:65` (`modern scss declares Phase 9 tokens`)
  - `test/assets/modern_drawer_css_contract_test.rb:10` (`modern scss includes drawer motion contracts`)
  - `app/assets/stylesheets/themes/modern.css.scss:1` (`.modern {`) and token declarations (`--modern-*`)
- **Run record:** baseline runs section (`bin/rails test` PASS)
- **Confidence:** HIGH — tests and source both directly assert scope + token contract.

### P05-C03 — menu.js guard strictness against requirement wording

- **Requirement rows:** THEME-03 — "`menu.js` exists with `body.modern` guard for drawer interaction logic"
- **Evidence type:** automated test + code reference (fail-first then remediation)
- **Artifact:**
  - RED evidence: `test/assets/menu_js_theme_guard_contract_test.rb:10-12` failed on first run
    (`Expected /if...hasClass('modern').../ to match`), proving mismatch before remediation.
  - Remediation target: `app/assets/javascripts/menu.js:2`
  - GREEN evidence: `bin/rails test test/assets/menu_js_theme_guard_contract_test.rb` passed
    (`1 runs, 4 assertions, 0 failures`).
- **Run record:** claim-specific red/green runs + baseline combined run section
- **Confidence:** HIGH — claim has explicit fail-first test evidence, minimal one-line fix, and passing re-verification.
- **root cause:** Guard was broadened to include `classic`, diverging from archived Phase 05 requirement wording.
- **action taken:** Applied localized fix in `menu.js` guard from
  `if (!$('body').hasClass('modern') && !$('body').hasClass('classic')) return;`
  to `if (!$('body').hasClass('modern')) return;`.
- **re-verification:** `bin/rails test test/assets/menu_js_theme_guard_contract_test.rb` PASS; full suite chain
  (`yarn run lint && bin/rails test && (bundle exec rake dad:test || bundle exec rake dad:test)`) PASS with one allowed dad:test rerun.

---

## Dependency notes

Cross-phase dependencies are tracked as links only (no additional Phase 05 claims):

- Drawer interaction behavior coupling: NAV-01..03 ownership in Phase 06 verification target
  `.planning/phases/06-html-structure/06-VERIFICATION.md` (to be populated in Phase 21).
- Reduced-motion drawer behavior coupling: A11Y-01 ownership in Phase 06/07 verification target
  `.planning/phases/06-html-structure/06-VERIFICATION.md` (to be populated in Phase 21).

---

## Manual fallback rationale

Automation currently verifies modern option presence and contract-level CSS/JS assertions. A full UI-path proof for "user explicitly changes theme to modern from preferences and confirms resulting page state" is not yet represented as a dedicated claim-level automated test in Phase 05 artifacts, so a manual fallback is recorded for reproducibility.

## Manual steps

1. Sign in as a user with non-modern theme selected (e.g., `classic`).
2. Open `/preferences`.
3. In the "Theme" select box, choose "モダン / Modern" and save.
4. Navigate to `/` and confirm modern-specific UI (hamburger button + drawer markup) is present.
5. Confirm `<body>` includes modern theme class (DOM inspection).
6. Record result in this file if automated coverage remains unchanged.

---

## Current phase-closure state

Phase 05 verification is **closure-ready**: `P05-C01..C03` are PASS with anchored evidence.
