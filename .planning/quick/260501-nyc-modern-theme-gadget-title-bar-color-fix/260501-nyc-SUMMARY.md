---
status: complete
quick_id: 260501-nyc
slug: modern-theme-gadget-title-bar-color-fix
date: 2026-05-01
commit: fb43b2c
---

# Quick Task 260501-nyc: Modern Theme Gadget Title Bar Color Fix

## What Was Done

Added a CSS override in `app/assets/stylesheets/themes/modern.css.scss` so that gadget title bars use the modern theme's primary blue color (`#3b82f6`) with white text, instead of inheriting the classic theme's semi-transparent dark grey (`rgba(0,0,0,.20)`).

## Root Cause

`welcome.css.scss` sets `div.gadgets div.gadget div div.title { background: rgba(0, 0, 0, .20) }` globally. `modern.css.scss` had no override for this selector, causing both themes to render the same dark grey gadget title bars.

## Fix

Appended to `modern.css.scss`:

```scss
// STYLE-05: Gadget title bars — override welcome.css.scss rgba(0,0,0,.20) with modern primary color
// Higher specificity (0,4,4) beats welcome.css.scss (0,3,4)
.modern div.gadgets div.gadget div div.title {
  background: var(--modern-color-primary);
  color: #ffffff;
}
```

Used `.modern div.gadgets div.gadget div div.title` (specificity 0,4,4) to beat the existing `div.gadgets div.gadget div div.title` rule (specificity 0,3,4).

## Files Changed

- `app/assets/stylesheets/themes/modern.css.scss` (+7 lines)

## Verification

- `yarn run lint` — ✅ passed
- `bin/rails test` — ✅ 142 runs, 0 failures
- Commit: fb43b2c
