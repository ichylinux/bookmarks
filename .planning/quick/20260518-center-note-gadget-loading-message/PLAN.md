---
slug: center-note-gadget-loading-message
date: 2026-05-18
status: complete
---

# Quick Task: Center Note Gadget Loading Message

Center the loading message for the note gadget both horizontally and vertically.

## Problem
The note gadget loading message (`.note-gadget-loading`) currently has no specific styling, so it appears at the top-left of its container, which feels unpolished when the tab is first opened.

## Strategy
Add flexbox centering to `.note-gadget-loading` in `welcome.css.scss`. Provide a minimum height to ensure it feels centered on the screen.

## Proposed Changes

### Styles
- `app/assets/stylesheets/welcome.css.scss`:
  - Add `.note-gadget-loading` class with `display: flex`, `justify-content: center`, `align-items: center`, and a `min-height` (e.g., `40vh`).

## Verification Plan

### Manual Verification
- Open the application and switch to the Notes tab.
- Observe the "Loading notes..." message. It should be centered.

### Automated Verification
- No new tests required as this is a purely visual change, but ensure existing tests pass.
