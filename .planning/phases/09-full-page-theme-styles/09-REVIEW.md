---
phase: 09-full-page-theme-styles
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - app/assets/stylesheets/themes/modern.css.scss
  - test/assets/modern_full_page_theme_contract_test.rb
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 9: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two source files were reviewed: the modern theme SCSS and its contract test. No security or data-loss issues were found. Three warnings were identified — one is a dead declaration that silently breaks the stated width contract, one is a duplicate `display: block` rule that partially re-opens a block defined earlier in the same scope, and one is a misleading string literal in the test that happens to pass for the wrong reason. Two informational items cover a commented-out CSS property that is no longer applied and a test assertion that is weaker than intended.

## Warnings

### WR-01: Duplicate `max-width` — second declaration silently overrides the first, defeating the 88 vw + 320 px cap contract

**File:** `app/assets/stylesheets/themes/modern.css.scss:42-43`

**Issue:** The drawer width contract, documented in the comment on line 40, is `min(88vw, 320px)`. The implementation correctly sets `width: 88vw` and then `max-width: 320px` on line 42 to enforce the cap. However, line 43 immediately overrides that with `max-width: 100%`, which removes the 320 px upper bound entirely. On screens wider than 363 px (320 / 0.88) the drawer will be exactly 88 vw instead of capped at 320 px. The `max-width: 100%` line appears to be a leftover edit that was not removed.

**Fix:** Remove line 43. The intended contract is already expressed by lines 41–42:
```scss
width: 88vw;
max-width: 320px;   // keep — enforces the min(88vw, 320px) cap
// max-width: 100%;  // DELETE — overrides the cap above
```

---

### WR-02: Duplicate `.drawer-overlay` rule block adds `display: block` after `common.css.scss` sets `display: none` — creates a rule-ordering dependency

**File:** `app/assets/stylesheets/themes/modern.css.scss:62-64`

**Issue:** `common.css.scss` hides `.drawer-overlay` globally with `display: none` (line 44 of common.css.scss). The modern theme's first `.drawer-overlay` block (lines 18–26) defines positioning, background, z-index, opacity, and transitions — but does not restore `display`. A second, separate `.drawer-overlay` block at lines 62–64 adds only `display: block`. This is a split definition: both compile to `.modern .drawer-overlay { ... }`, but they appear to be two distinct authored blocks rather than one. The `display: block` restoration is correct in intent, but placing it in a disconnected second block 36 lines later makes it easy to miss and accidentally delete. It also means the visual behaviour depends on the cascade order of `common.css` relative to `modern.css` loading order in Sprockets — if that order changes, the drawer overlay becomes invisible regardless of JS state.

**Fix:** Consolidate `display: block` into the first `.drawer-overlay` block and delete the second block:
```scss
.drawer-overlay {
  display: block;          // add here — undoes common.css display:none
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1000;
  opacity: 0;
  pointer-events: none;
  transition: opacity 250ms ease-out;
}
// Delete lines 62-64
```

---

### WR-03: Misleading string literal in test — `'input[type='` relies on a Ruby quoting accident and does not test what it appears to test

**File:** `test/assets/modern_full_page_theme_contract_test.rb:48`

**Issue:** The assertion is:
```ruby
assert_includes @scss, 'input[type='
```
Ruby parses `'input[type='` as the string `"input[type="` — the trailing single-quote is consumed as the string delimiter, and the `"text"` that follows on the same line becomes free-standing Ruby syntax (a string literal that is evaluated and discarded). The test passes today because the SCSS contains `input[type="text"` which does include the substring `input[type=`. However:

1. The intent is almost certainly to match `input[type=` (without the trailing `"`), but the actual search string includes a literal double-quote character. If the SCSS were ever refactored to use unquoted attribute selectors (`input[type=text]`) the assertion would silently fail even though valid CSS is present.
2. The `"text"` string that is left dangling after `'input[type='` generates no syntax error but is dead code. `ruby -c` reports `Syntax OK` only because a bare string expression is legal Ruby; it is not caught as an unterminated literal.
3. Any future reader will misread the intent of this assertion.

**Fix:** Use a double-quoted string or escape the embedded quote:
```ruby
assert_includes @scss, "input[type="
# or more specifically:
assert_includes @scss, 'input[type="text"]'
```

## Info

### IN-01: `hamburger-btn::before` uses `box-shadow` as a pseudo-middle bar — no test coverage for this structural convention

**File:** `app/assets/stylesheets/themes/modern.css.scss:126`

**Issue:** The three-line hamburger icon is rendered via `::before` (top bar + middle bar via `box-shadow: 0 6px 0 #fff`) and `::after` (bottom bar). The `box-shadow` technique is a known CSS trick but it is unconventional and invisible to CSS linters. There is no contract test asserting the `box-shadow` value on `::before`. If this declaration is accidentally removed, the hamburger loses its middle bar with no test failure.

**Fix (suggestion):** Add a contract assertion in `modern_full_page_theme_contract_test.rb`:
```ruby
test 'modern scss hamburger middle bar rendered via box-shadow on ::before' do
  assert_match(/hamburger-btn::before/, @scss)
  assert_match(/box-shadow:\s*0 6px 0/, @scss)
end
```

---

### IN-02: Magic z-index values with no named tokens or comment cross-reference

**File:** `app/assets/stylesheets/themes/modern.css.scss:22, 48, 103`

**Issue:** Three z-index values are used — `1000` (overlay), `1010` (drawer panel), `1020` (hamburger button) — with no shared constant, no CSS custom property, and no comment linking them. The relative ordering is correct, but each value is a magic number. If another component in the application uses any of these values, stacking conflicts will arise with no compiler warning.

**Fix (suggestion):** Document the stacking context with inline comments or promote to CSS custom properties:
```scss
--modern-z-overlay:     1000;
--modern-z-drawer:      1010;
--modern-z-hamburger:   1020;
```
Note that libsass does not support `var()` inside `z-index` when the variable is declared inside a selector scope in all versions; verify before applying.

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
