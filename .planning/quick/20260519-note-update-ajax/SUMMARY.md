---
slug: note-update-ajax
date: 2026-05-19
status: complete
commit: eb98bc7
---

# Note Update: In-Place AJAX

## What changed
- `NotesController#update` now uses `respond_to`: HTML requests get the existing redirect; JSON requests get note data (id, body, timestamps, edited flag + i18n strings).
- `gadget.html.erb` adds `data-note-id` to each `.note-item` div.
- `note_gadget.js` intercepts `.note-item-edit-form` submit via `submit.noteGadgetUpdate`, sends `PATCH /notes/:id.json`, and updates the note body + edited badge in-place on success — no reload.
- Two new controller tests cover the JSON success and validation-error paths.

## Outcome
Submitting an edit now updates the note in-place. 460 Minitest runs, 0 failures. ESLint clean.
