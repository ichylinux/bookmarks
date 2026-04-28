# Phase 9 — Pattern Map

**Purpose:** Closest analogs in repo for executor `read_first` shortcuts.

| Planned touch | Analog file | Notes |
|---------------|-------------|-------|
| `modern.css.scss` structure | `app/assets/stylesheets/themes/modern.css.scss` | Extend `.modern { }` block; match indentation / comment style |
| Legacy competition | `app/assets/stylesheets/common.css.scss` | `#header .head-box`, `table`, `.actions`, `.header` |
| SCSS contract test | `test/assets/modern_drawer_css_contract_test.rb` | Copy pattern: `Rails.root.join(...).read`, `assert_includes`, `assert_match` |
| Phase 7 specificity lesson | `.planning/phases/07-drawer-css-animation/07-RESEARCH.md` | `.modern #header` for ID wins |

---

## Files modified (expected)

1. `app/assets/stylesheets/themes/modern.css.scss`
2. `test/assets/modern_full_page_theme_contract_test.rb` (create)

---

## Anti-patterns

- Editing `common.css.scss` for modern-only look — **forbidden** (breaks other themes).
- `$variable` inside `var(--custom-prop)` values — **forbidden** (libsass).
