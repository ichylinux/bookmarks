---
slug: mobile-note-edit-textarea-height
date: 2026-05-18
status: complete
---

# Mobile note edit textarea height

When editing a note on mobile, auto-resize the textarea vertically to show the full note content without internal scrolling.

## Changes

- `app/assets/javascripts/note_gadget.js`: Add `autoResizeTextarea` helper; call it in `showEditControls` when on mobile (MOBILE_MQ matches) and bind `input.noteGadgetResize` for live resize; clean up in `hideEditControls`.
- `app/assets/stylesheets/themes/_notes_shared.scss`: Add `overflow: hidden` on `.note-item--editing .note-item-edit-form textarea` inside the `@media (max-width: 767px)` block (required for the auto-resize height trick).
