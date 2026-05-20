---
slug: mobile-note-edit-textarea-height
date: 2026-05-18
status: complete
---

# Quick Task Summary: Mobile Note Edit Textarea Height

## What Was Done

Added auto-resize behavior to the note edit textarea on mobile so it expands to show full note content without internal scrolling.

### Changes

- `app/assets/javascripts/note_gadget.js`: Added `autoResizeTextarea` helper; called in `showEditControls` when `MOBILE_MQ` matches; bound `input.noteGadgetResize` for live resize; cleaned up in `hideEditControls`.
- `app/assets/stylesheets/themes/_notes_shared.scss`: Added `overflow: hidden` on `.note-item--editing .note-item-edit-form textarea` inside `@media (max-width: 767px)` block (required for auto-resize height trick).
