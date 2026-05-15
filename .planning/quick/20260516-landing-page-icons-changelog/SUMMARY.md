---
slug: landing-page-icons-changelog
status: complete
date: 2026-05-16
---

# Summary

Added SVG icons to the three landing page value cards (capture/organize/focus) and a new changelog entry for the recently-shipped gadget header icons.

## Changes made
- `show.html.erb`: wrapped each value card `<h2>` in `.landing-value-card-header` with an inline SVG icon (bookmark, apps-grid, checklist)
- `landing.css.scss`: added `.landing-value-card-header` (flex, gap) and `.landing-value-icon` (blue, 20px svg)
- `en.yml` + `ja.yml`: prepended 2026-05-16 `ux` changelog entry for gadget header icons
