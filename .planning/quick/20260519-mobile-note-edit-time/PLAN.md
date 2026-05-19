---
slug: mobile-note-edit-time
date: 2026-05-19
---

# Quick Task: Show note edit time on mobile

## Goal

On desktop, hovering over the `編集済み` badge shows the edit timestamp via a `title` tooltip.
On mobile there is no hover, so the edit time is inaccessible. Surface it inline on touch devices.

## Approach

CSS-only fix using `@media (hover: none)`:
- Add `data-time="<%= updated_time %>"` attribute to `.note-edited-badge` span in the ERB template
- Add `::after` pseudo-element in `_notes_shared.scss` that renders the time inline on devices that don't support hover

## Files

- `app/views/notes/gadget.html.erb` — add `data-time` attribute
- `app/assets/stylesheets/themes/_notes_shared.scss` — add `@media (hover: none)` rule
