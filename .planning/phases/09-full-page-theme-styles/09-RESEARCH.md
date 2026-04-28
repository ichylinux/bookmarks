# Phase 9 — Technical Research

**Phase:** Full-Page Theme Styles  
**Question:** What do we need to know to extend `modern.css.scss` for global surfaces without breaking legacy themes?

## RESEARCH COMPLETE

---

## A. Specificity map (`common.css.scss`)

- **Finding:** `#header .head-box` sets `background: #AAA` (STYLE-01 violation under modern). `.header` block styles dropdown nav (margin, height 20px, `.menu` chrome).
- **Implication:** Modern overrides live under `.modern #header .head-box` and `.modern .header` (and nested rules). Never edit `common.css.scss` for Phase 9 — additive SCSS only.

---

## B. Body font baseline

- **Finding:** `html { font-size: 62.5%; }` and `body { font-size: 12px; }` globally.
- **Implication:** `.modern` on `body` can set `font-size: 16px` and preferred `line-height` so rem-based layouts inherit sensibly; verify list/label readability on Preferences and CRUD.

---

## C. Tables

- **Finding:** Global `table { margin: 20px; tr th/td { padding: 5px; } tr:hover { background: #EEEEEE; } }`.
- **Implication:** `.modern table` rules should increase padding, clarify header background, keep or refine hover/zebra using tokens — avoid removing table margins without replacing spacing intent.

---

## D. Actions + forms

- **Finding:** `.actions a` uses gray border `#595757`, pill radius, hover invert. Form fields inherit minimal styling from browser defaults in most views.
- **Implication:** `.modern .actions a` receives tokenized treatment; form selectors scoped under `.modern` so non-modern theme unchanged.

---

## E. Sprockets / libsass

- **Finding:** Phase 5–8 forbid `$vars` inside custom property values.
- **Implication:** Any new `--modern-*` token uses literal colours only.

---

## F. Verification

- **Finding:** Phase 7 introduced SCSS substring contract test.
- **Implication:** Add `test/assets/modern_full_page_theme_contract_test.rb` (or extend existing) with curated strings: `#header .head-box`, `16px`, system font stack fragment, table/header/hover tokens, `focus-visible` or focus styles, `.actions`.

---

## Validation Architecture

| Dimension | Strategy |
|-----------|----------|
| Automated | `bin/rails test`; dedicated `test/assets/modern_full_page_theme_contract_test.rb` reading `modern.css.scss` |
| Manual | Browser: Preferences + one CRUD index — confirm no `#AAA` band, readable tables, visible inputs |
| Sampling | After each plan task: contract test + targeted tests; end: full suite |

Nyquist note: CSS-only — no schema push. Asset compile must stay green.

---

## G. Schema / ORM

Not applicable (no migration files in scope).
