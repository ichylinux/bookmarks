---
slug: note-update-ajax
date: 2026-05-19
status: in-progress
---

# Note Update: Replace Full Reload with In-Place AJAX

## Goal
When the user edits and saves a note, replace the full page reload with an in-place DOM update via AJAX.

## Changes

### 1. `app/controllers/notes_controller.rb`
Add `respond_to` to `update`: HTML path keeps redirect (existing tests), JSON path returns note data.

### 2. `app/views/notes/gadget.html.erb`
Add `data-note-id="<%= note.id %>"` to each `.note-item` div so JS can target the right element.

### 3. `app/assets/javascripts/note_gadget.js`
Intercept `.note-item-edit-form` submit:
- Prevent default
- PATCH to note URL with JSON body + CSRF header
- On success: update `.note-body` text, update/create `.note-edited-badge`, call `hideEditControls`
- On error: `alert` the error message from JSON response

### 4. `test/controllers/notes_controller_test.rb`
Add test: JSON PATCH returns 200 with note data.
