# Phase 79: Note Gadget AJAX Extraction - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract the note gadget from server-side rendering into an AJAX-loaded fragment. `WelcomeController#index` stops assigning `@note`/`@notes`. A new `NotesController#gadget` action serves the note gadget HTML fragment. On the simple theme, the first click on the notes tab triggers one AJAX request; subsequent clicks use the already-loaded DOM. On the modern/classic theme with `?tab=notes`, the note gadget is fetched immediately on page load. CRUD actions (create/update/destroy) remain unchanged.

</domain>

<decisions>
## Implementation Decisions

### Controller & Route Shape
- Route as a `collection` action inside `resources :notes` → `GET /notes/gadget` (Rails conventions, no naming clash)
- Action renders with `layout: false` (plain HTML fragment, consistent with `calendars#get_gadget`)
- Authentication relies on existing `before_action :authenticate_user!` from `ApplicationController` — redirects to sign-in if unauthenticated
- View: `app/views/notes/gadget.html.erb` renders `render 'welcome/note_gadget'` — new action file, existing partial reused

### JS Loading Mechanism
- Simple theme: extend `notes_tabs.js` with a `loaded` flag; on first `activateTab('notes')` call, fire `$.get('/notes/gadget')` and replace `#notes-tab-panel` contents
- Modern/classic theme: inline `<script>` at the bottom of the `#notes-tab-panel` placeholder, server-conditionally emitting JS to fire `$.get('/notes/gadget')` on `$(document).ready` when `params[:tab] == 'notes'`
- Initial placeholder HTML inside `#notes-tab-panel`: `<div class="note-gadget-loading">` with `t('welcome.loading')` text span — matches "Loading..." pattern used by portal column gadgets
- Error handling: `console.warn` only (silent degradation) — note gadget errors are non-critical

### Cleanup & Test Strategy
- Update `welcome_controller_test.rb` to remove `@note`/`@notes` assigns assertions; add assertions that they are NOT assigned
- Add `test_gadget` to `notes_controller_test.rb` asserting: 200 response, `@note` is a new Note, `@notes` is the user's active notes, no layout rendered
- Existing Cucumber notes scenarios left as-is — they test CRUD at the form level which is unchanged
- Add NOTE-01, NOTE-02, NOTE-03 to `REQUIREMENTS.md` during plan/execute (as noted in STATE.md pending todos)

### Claude's Discretion
- Exact i18n key for the loading placeholder text (reuse `welcome.loading` if it exists, or add `notes.gadget.loading`)
- Whether to name the JS `loaded` flag `_notesLoaded` or similar to avoid conflicts

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/welcome/_note_gadget.html.erb` — existing partial using `@note` / `@notes`; stays in place, referenced from new `notes/gadget.html.erb`
- `app/assets/javascripts/notes_tabs.js` — simple-theme tab switcher; extend with lazy-load logic
- `NotesController` — has create/update/destroy; add `gadget` as a collection action
- `app/views/welcome/_x_account.html.erb` — reference pattern for inline `<script>` + portalLazy (not used for notes, but layout shape)

### Established Patterns
- AJAX gadget fragments render `layout: false` (see `CalendarsController#get_gadget`)
- Other AJAX gadgets use `$.get(url, {format: 'html'}, callback)` + `.fail()` handler
- Loading placeholder: `<span>Loading...</span>` pattern in portal column gadgets
- Notes CRUD redirects to `root_path(tab: 'notes')` — unchanged

### Integration Points
- `config/routes.rb`: add `collection { get :gadget }` inside `resources :notes`
- `app/controllers/welcome_controller.rb`: remove `@note = Note.new` and `@notes = current_user.notes.active.recent` from `#index`
- `app/views/welcome/_dashboard.html.erb`: replace `render 'note_gadget'` inside `#notes-tab-panel` with a loading placeholder + inline `<script>` for modern/classic
- `app/assets/javascripts/notes_tabs.js`: add lazy-load on first tab activation for simple theme

</code_context>

<specifics>
## Specific Ideas

- For simple theme: `activateTab` in `notes_tabs.js` already fires on every tab click — add a module-level `var notesLoaded = false;` guard so the fetch only fires once, then replace the panel contents via `$('#notes-tab-panel').html(html)`
- For modern/classic: the inline `<script>` should be guarded server-side — only emitted if `use_note && params[:tab].to_s == 'notes'` (same condition that currently controls rendering)
- The `notes/gadget.html.erb` template can be a single line: `<%= render 'welcome/note_gadget' %>` (the partial already accesses `@note`/`@notes` set by the action)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
