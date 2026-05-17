---
phase: 79-note-gadget-ajax-extraction
plan: 01
subsystem: ui, api, testing
tags: [ajax, notes, lazy-loading, refactor, minitest, cucumber]

requires:
  - phase: 78-contract-tests-cucumber-e2e
    provides: portalLazy coordinator + tab hook + Cucumber E2E green bar

provides:
  - GET /notes/gadget endpoint returning note gadget HTML fragment without layout
  - WelcomeController#index no longer assigns @note or @notes
  - AJAX lazy-load of note gadget for all themes (once per page session)
  - note_gadget.js re-initialization after AJAX injection via noteGadgetLoaded event

affects: [notes-crud, welcome-dashboard, portal-lazy, simple-theme-tabs]

tech-stack:
  added: []
  patterns:
    - "AJAX gadget endpoint: render layout: false, scoped to current_user"
    - "noteGadgetLoaded custom event for post-AJAX JS re-init"
    - "initNoteGadget() factory function pattern for re-entrant initialization"

key-files:
  created:
    - app/views/notes/gadget.html.erb
  modified:
    - config/routes.rb
    - app/controllers/notes_controller.rb
    - app/controllers/welcome_controller.rb
    - app/views/welcome/_dashboard.html.erb
    - app/assets/javascripts/notes_tabs.js
    - app/assets/javascripts/note_gadget.js
    - config/locales/ja.yml
    - config/locales/en.yml
    - test/controllers/notes_controller_test.rb
    - test/controllers/welcome_controller/dashboard_test.rb
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Simple theme lazy-fetches on first tab click via notesLoaded flag in notes_tabs.js"
  - "Modern/classic theme fetches immediately on $(document).ready when ?tab=notes is active"
  - "noteGadgetLoaded custom event fires after $.get success to trigger note_gadget.js re-init"
  - "notesLoaded set synchronously before $.get call to prevent duplicate in-flight requests"
  - "No preference guard in gadget action — panel omitted server-side when use_note is false"

patterns-established:
  - "noteGadgetLoaded event: fire after AJAX injection, listen in note_gadget.js to re-init"
  - "initNoteGadget() factory: removes old handlers, re-binds fresh — safe to call multiple times"

requirements-completed: [NOTE-01, NOTE-02, NOTE-03]

duration: 45min
completed: 2026-05-17
---

# Phase 79: Note Gadget AJAX Extraction Summary

**Removed two DB queries (Note.new + notes.active.recent) from every dashboard page load by extracting the note gadget into an AJAX-fetched fragment at GET /notes/gadget.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-05-17
- **Tasks:** 3 tasks + 1 JS re-init refactor
- **Files modified:** 12

## Accomplishments

- Added `NotesController#gadget` action and `GET /notes/gadget` route; view delegates to existing `welcome/note_gadget` partial
- Removed `@note` / `@notes` assignments from `WelcomeController#index` — those queries no longer run on every page load
- Simple theme: `notes_tabs.js` fires one `$.get('/notes/gadget')` on first tab activation; `notesLoaded` flag set synchronously prevents duplicates
- Modern/classic theme: inline `<script>` emitted when `notes_active` (i.e., `?tab=notes`), fires `$.get(gadget_notes_path)` on DOM ready
- Both themes fire `$(document).trigger('noteGadgetLoaded')` after injection; `note_gadget.js` re-initializes dblclick/longpress/Cmd+S handlers via `initNoteGadget()`
- Added `welcome.note_gadget.loading` locale key in both `ja.yml` and `en.yml`
- Migrated 9 SSR-content tests out of `dashboard_test.rb`; added 10 endpoint tests in `notes_controller_test.rb`; added NOTE-01/02/03 to REQUIREMENTS.md

## Verification

- `yarn run lint` — green
- `bin/rails test` — 407 runs, 0 failures, 0 errors
- `bundle exec rake dad:test` — 25 scenarios, 25 passed, 0 failed
