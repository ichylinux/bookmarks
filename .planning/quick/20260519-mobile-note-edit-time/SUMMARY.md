---
slug: mobile-note-edit-time
date: 2026-05-19
status: complete
commit: aa6308e
---

# Summary

Added `data-time` attribute to `.note-edited-badge` and a `@media (hover: none)` CSS rule
that appends the edit timestamp inline via `::after`. No JS needed.

Desktop behavior unchanged (tooltip on hover). Mobile now shows `編集済み (2026-05-19 14:30)` inline.
