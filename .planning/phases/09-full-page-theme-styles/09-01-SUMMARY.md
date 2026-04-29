---
phase: "09-full-page-theme-styles"
plan: "01"
subsystem: frontend-css
tags:
  - rails
  - scss
  - modern-theme
  - a11y

dependency_graph:
  requires:
    - "phases/07-drawer-css-animation (modern.css.scss, token definitions)"
    - "phases/08-system-tests (layout_structure_test.rb baseline)"
  provides:
    - "STYLE-01: .modern #header .head-box overrides #AAA, .modern .header nav strip modernised"
    - "STYLE-02: 16px system font stack on body.modern"
    - "STYLE-03: table th/td padding 10px 12px, distinct thead, zebra/hover"
    - "STYLE-04: .modern .actions a pill buttons, form control border/focus ring"
    - "Phase 9 SCSS contract test (CI guard)"
  affects:
    - "app/assets/stylesheets/themes/modern.css.scss"
    - "test/assets/modern_full_page_theme_contract_test.rb"

tech_stack:
  added: []
  patterns:
    - "Top-level .modern-prefixed selectors for grep-verifiable CI contracts"
    - "CSS custom property tokens with plain hex/rgba literals (libsass-safe)"
    - "ID specificity override: .modern #header .head-box beats #header .head-box {#AAA}"
    - "focus-visible outline using --modern-color-primary for WCAG-friendly keyboard nav"

key_files:
  created:
    - test/assets/modern_full_page_theme_contract_test.rb
  modified:
    - app/assets/stylesheets/themes/modern.css.scss

decisions:
  - "Top-level selectors (outside .modern{}) used for STYLE-01 and STYLE-03–04 so literal .modern #header .head-box, .modern table, .modern .actions appear in source for grep-based CI"
  - "Four new tokens added: --modern-header-fg (#ffffff), --modern-border (#d1d5db), --modern-surface-alt (#f3f4f6), --modern-danger (#dc2626) — all plain hex (libsass-safe)"
  - "Typography (STYLE-02) placed inside .modern{} block as property declarations since body carries the class"

metrics:
  duration: "~12 minutes"
  completed: "2026-04-29"
  tasks_completed: 4
  tasks_total: 4
  files_created: 1
  files_modified: 1
---

# Phase 9 Plan 01: Full-Page Theme Styles Summary

Full-page visual overrides for `body.modern` via additive rules in `themes/modern.css.scss`: header bar replaces legacy `#AAA`, body gets 16px system typography, tables gain padding and header/zebra styling, action links and form controls adopt token-based borders and focus rings. CI-guarded by a new Minitest contract test with 7 tests / 46 assertions.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Header bars (STYLE-01) | 2e4d2a8 | modern.css.scss |
| 2 | Body typography (STYLE-02) | 3d7a5c2 | modern.css.scss |
| 3 | Tables (STYLE-03) | d702a0f | modern.css.scss |
| 4 | Actions + forms + contract test (STYLE-04) | 8be9dad | modern.css.scss, modern_full_page_theme_contract_test.rb |

## What Was Built

### STYLE-01 — Header bars
- `.modern #header .head-box`: `background: var(--modern-header-bg)` — beats `common.css.scss` `#header .head-box { background: #AAA }` via ID specificity. Added `--modern-header-fg: #ffffff` token for text/icon contrast.
- `.modern .header`: modernised legacy `height: 20px` strip — `min-height: 36px`, `border-bottom`, link colours from `--modern-text`, hover/focus-visible using `--modern-color-primary`. `.modern .header .menu` uses token border, bg, and `box-shadow`.

### STYLE-02 — Body typography
- On `.modern` (body): `font-size: 16px`, `line-height: 1.5`, `font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`, `color: var(--modern-text)`.

### STYLE-03 — Tables
- `.modern table`: `border-collapse: collapse`
- `th`/`td`: `padding: 10px 12px`, `border-bottom: 1px solid var(--modern-border)`
- `thead th`: `background: var(--modern-surface-alt)`, `font-weight: 600`, `2px` bottom border
- `tbody tr:nth-child(even)`: subtle alternating row background
- `tbody tr:hover`: primary-tinted hover (`rgba(59, 130, 246, 0.06)`)

### STYLE-04 — Actions + form controls
- `.modern .actions a`: token `border`/`border-radius`/`padding`/`transition`, hover fill with primary colour, `focus-visible` ring
- Form inputs (`input[type=text/email/password/url/number]`, `textarea`, `select`): `border`, `border-radius: 4px`, `padding: 6px 10px`, `background: var(--modern-bg)`, inherit font
- `:focus-visible` on all controls: `outline: 2px solid var(--modern-color-primary)` + `border-color`

### Contract test
- `test/assets/modern_full_page_theme_contract_test.rb`: 7 tests, 46 assertions
- Asserts presence of `.modern #header .head-box`, `var(--modern-header-bg)`, `font-size: 16px`, `-apple-system`, `.modern table`, `nth-child`, `.modern .actions`, `focus-visible`, Phase 9 tokens

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Selector structure] Top-level selectors for grep-verifiable CI contract**
- **Found during:** Task 1 verification
- **Issue:** Acceptance criteria use `grep -E '\.modern #header \.head-box'` on source file. SCSS nesting inside `.modern {}` produces compiled output `.modern #header .head-box` but the literal string does not appear in source.
- **Fix:** Wrote STYLE-01, STYLE-03, STYLE-04 rules as top-level selectors (e.g. `.modern #header .head-box { ... }`) outside the `.modern {}` block. STYLE-02 stays inside `.modern {}` as body-level property declarations (correct pattern for typography).
- **Files modified:** `app/assets/stylesheets/themes/modern.css.scss`
- **Commit:** 2e4d2a8

## Verification Results

- `bin/rails test test/assets/modern_full_page_theme_contract_test.rb`: 7 runs, 46 assertions, 0 failures
- `bin/rails test test/controllers/welcome_controller/layout_structure_test.rb`: 7 runs, 33 assertions, 0 failures
- `bin/rails test` (full suite): 89 runs, 430 assertions, 0 failures, 0 errors, 0 skips
- All task acceptance_criteria grep checks: green
- Non-modern theme unchanged (all new selectors prefixed `.modern`)

## Known Stubs

None — all rules wire to real tokens and apply to live DOM elements.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. All changes are static CSS.

## Self-Check: PASSED

- `app/assets/stylesheets/themes/modern.css.scss`: exists, contains all required selectors
- `test/assets/modern_full_page_theme_contract_test.rb`: exists, 7 tests pass
- Commits 2e4d2a8, 3d7a5c2, d702a0f, 8be9dad: all present in git log
