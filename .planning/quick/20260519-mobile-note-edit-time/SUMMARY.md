---
slug: mobile-note-edit-time
date: 2026-05-19
status: complete
commit: 4f5e6cb
---

# Summary

Added `data-time` attribute to `.note-edited-badge` (ERB). On touch devices (`hover: none`),
tapping the badge toggles a dark popup tooltip above it showing the edit time; tapping outside
dismisses it. Desktop hover behavior (native `title` tooltip) is unchanged.

- CSS: `.tooltip-active::after` positions the bubble above the badge
- JS: delegated click handler in `note_gadget.js`, gated by `matchMedia('(hover: none)')`
