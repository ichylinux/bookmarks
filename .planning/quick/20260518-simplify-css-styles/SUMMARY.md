---
slug: simplify-css-styles
date: 2026-05-18
status: complete
---

# Summary: Simplify CSS Styles

Removed pure redundancies across four SCSS files. No visual change.

## Changes applied

| File | Change |
|------|--------|
| `calendars.css.scss` | `margin: 0px` → `margin: 0` |
| `feeds.css.scss` | Consolidated `overflow: hidden` into shared selector (removed 2 duplicate single-declaration rules) |
| `common.css.scss` | Merged `table tr { th { … } td { … } }` → `table tr { th, td { … } }` |
| `common.css.scss` | Merged two `body.no-icons` rules into one comma-separated selector |
| `welcome.css.scss` | Merged two identical `@media (min-width: $portal-mobile-breakpoint)` blocks into one |

## Verification

- `yarn run lint` — green
