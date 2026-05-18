---
slug: simplify-css-styles
date: 2026-05-18
status: in_progress
---

# Simplify CSS Styles

Remove obvious redundancies and consolidate duplicate declarations across SCSS files.
No visual change — pure code simplification.

## Changes

### calendars.css.scss
- `margin: 0px;` → `margin: 0;` (remove redundant unit on zero)

### feeds.css.scss
- Consolidate `overflow: hidden` into the shared `div.feed_url, input[type="text"].feed_url` rule
  (both selectors had identical separate single-declaration rules afterward)

### common.css.scss
- Merge `table tr { th { padding: 5px; } td { padding: 5px; } }` → `table tr { th, td { padding: 5px; } }`
- Merge two `body.no-icons` rules (gadget-title-icon and drawer-nav-icon) into one comma-separated selector

### welcome.css.scss
- Merge the two `@media (min-width: $portal-mobile-breakpoint)` blocks into one
