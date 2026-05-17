---
plan: "074-002"
phase: 74
status: complete
date: "2026-05-17"
---

# Summary: 074-002 — CSS hide rules under body.no-icons

## What was built

Appended two CSS rules to `common.css.scss`:
- `body.no-icons .gadget-title-icon { display: none !important; }`
- `body.no-icons .drawer-nav-icon { display: none !important; }`

`!important` required to override higher-specificity existing rules (e.g. `.modern .drawer nav a .drawer-nav-icon { display: inline-flex }`).

## Tasks completed

- [x] Appended no-icons rules to `common.css.scss`
- [x] `yarn run lint` — green
- [x] `bin/rails assets:precompile` — no errors; `assets:clobber` run after

## Files changed

- `app/assets/stylesheets/common.css.scss` (9 lines appended)
