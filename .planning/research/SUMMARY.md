# Project Research Summary

**Project:** Bookmarks v1.3 — Quick Note Gadget
**Domain:** Server-rendered note-taking tab embedded in an existing Rails personal dashboard
**Researched:** 2026-04-30
**Confidence:** HIGH

## Executive Summary

The Quick Note Gadget is a focused addition to an existing Rails 8.1 personal bookmark app: a textarea-plus-list note-taking panel accessible via a new "ノート" tab on the simple theme welcome page. All four research areas converge on the same conclusion — no new dependencies are needed, and the implementation is a direct application of patterns already proven in this codebase. The todos gadget (AJAX partial swap, per-user scoping via `Crud::ByUser`, soft-delete) serves as the closest template; the note gadget follows the same structure but starts with a simpler full-page POST/redirect approach before optionally adding AJAX.

The recommended approach is a standard Rails MVC addition: a `notes` table migration, a `Note` model scoped to `current_user`, a thin `NotesController` with `create` (and optionally `destroy`), a `_note_gadget` partial in `app/views/welcome/`, and tab switching via jQuery `show()`/`hide()` with a `?tab=notes` query param to survive redirects. The tab UI must be strictly scoped to the simple theme — both in the ERB view (`<% if favorite_theme == 'simple' %>`) and in CSS (`.simple { .tab-nav { ... } }`). No service objects, no gadget protocol, no Turbo, no ActionText.

The primary risks are security (user ownership not enforced from day one, or `user_id` permitted in strong params), theme leakage (tab HTML or CSS visible on modern/classic themes), and tab state loss after the POST/redirect cycle. All three are easily prevented by following the existing controller patterns in the codebase and adding the `tab` query param to the redirect. Research found no ambiguities — every decision has a clear answer grounded in the existing code.

## Key Findings

### Recommended Stack

No new gems or npm packages are required. The entire feature is built on Rails 8.1 ActiveRecord (migration + model), `form_with` (server-rendered form), ERB partials (gadget partial), jQuery with rails-ujs (tab switching + optional AJAX), and SCSS scoped under `.simple` (tab styles). The Sprockets asset pipeline picks up new `.js` and `.css.scss` files automatically via `require_tree .`.

**Core technologies:**
- Rails ActiveRecord 8.1.3: `Note` model and migration — already installed, plain `text` column, no ActionText needed
- `form_with(local: true)`: standard form POST for note creation — consistent with bookmarks and preferences forms
- jQuery 4.6.1 + rails-ujs: tab switching and optional AJAX submission — already loaded globally
- ERB partials (`_note_gadget.html.erb`): note form and list rendering — consistent with all other gadget partials
- SCSS in `welcome.css.scss`: tab nav and panel styles — existing file, scoped under `.simple`

### Expected Features

**Must have (table stakes — v1.3 launch):**
- Migration: `notes` table with `user_id`, `body` (text, not null), timestamps, index on `(user_id, created_at)`
- `Note` model: `belongs_to :user`, `validates :body, presence: true`, `Crud::ByUser` scope
- "ホーム" and "ノート" tab links on the simple theme welcome page
- Textarea + Save button form (standard POST)
- Reverse-chronological note list showing body text and timestamp
- Empty-state message ("メモはまだありません") when no notes exist
- Per-user data isolation enforced in all queries and on destroy

**Should have (add when core is confirmed):**
- Delete note from list (per-row destroy link with confirm dialog)
- Auto-clear textarea after save (only relevant if AJAX submission is added)

**Defer (v2+):**
- Inline edit of existing notes — doubles action surface
- Note categories or tags — schema complexity not justified at this scale
- Full-text search — not needed while the list is short enough to scan

### Architecture Approach

The note gadget lives in a dedicated tab panel outside the draggable portal grid, so it does not participate in the gadget protocol (`Portal`, `PortalLayout`, `save_state`). `WelcomeController#index` assigns `@notes = current_user.notes.order(created_at: :desc)` (one extra query per homepage load). A dedicated `NotesController` handles `create` and `destroy` via standard `resources :notes` routing. Tab state survives the POST/redirect cycle via a `?tab=notes` query param read by `notes.js` on `$(document).ready`.

**Major components:**
1. `Note` model (`app/models/note.rb`) — `belongs_to :user`, body validation, user-scoped queries
2. `NotesController` (`app/controllers/notes_controller.rb`) — `create` + optional `destroy`; inherits `authenticate_user!`; merges `user_id` from `current_user` outside `permit`
3. `WelcomeController#index` (modified) — adds `@notes` assignment alongside existing `@portal`
4. `welcome/_note_gadget.html.erb` (new) — `form_with` textarea + `<ul>` of notes with timestamp
5. `welcome/index.html.erb` (modified) — wraps portal grid in `div.tab-panel#home`; adds `div.tab-panel#notes` inside `<% if favorite_theme == 'simple' %>`
6. `common/_menu.html.erb` (modified) — adds tab nav links with `data-tab` attributes
7. `notes.js` (new) — `window.notes.initTabs()`; reads `URLSearchParams` to restore tab on load
8. `welcome.css.scss` (modified) — `.simple { .tab-nav { } .tab-panel { } }` styles

### Critical Pitfalls

1. **Tab UI leaks into non-simple themes** — Wrap all tab HTML in `<% if favorite_theme == 'simple' %>` in the view; wrap all tab CSS under `.simple { }` in `welcome.css.scss`. Do not add any tab styles to `common.css.scss`.

2. **Note ownership not enforced** — Scope every query to `current_user.id` from the first line of code. Never permit `user_id` in strong params; merge it from `current_user.id` explicitly (pattern from `todos_controller.rb`).

3. **CSRF token broken on note form** — Use `form_with(local: true)` for the standard form POST. Do not copy the `authenticity_token: form_authenticity_token` inline pattern from `collect_portal_layout_params()` — that is a legacy approach.

4. **Tab state lost after POST/redirect** — Redirect to `root_path(tab: 'notes')` after a successful note save. Read `URLSearchParams` in `notes.js` on DOM ready to trigger the correct tab. This is the simplest and most testable option.

5. **`user_id` accepted via mass assignment** — Never include `user_id` in `permit(...)`; set it via `ret.merge(user_id: current_user.id)` after building the permitted params hash (exact pattern from `todo_params` in `todos_controller.rb`).

## Implications for Roadmap

Based on research, all four files agree on a natural dependency chain. The suggested phase structure maps directly to the build order recommended in ARCHITECTURE.md.

### Phase 1: Data Layer

**Rationale:** Everything depends on the `notes` table and `Note` model existing. No view or controller work is testable without this. Zero risk of cascading changes — the migration is additive.
**Delivers:** `notes` table migration (with index on `user_id, created_at`), `Note` model with `belongs_to :user` and body validation, `has_many :notes` on `User`, `resources :notes, only: [:create, :destroy]` in routes
**Addresses:** FEATURES.md — migration + Note model (P1), per-user isolation foundation
**Avoids:** Pitfall 2 (ownership) and Pitfall 3 (mass assignment) must be baked in here, not retrofitted

### Phase 2: Controller + Backend Tests

**Rationale:** Controller logic (create, scoping, auth guard, redirect) is fully testable without any view changes. Verifying the backend before wiring views prevents debugging a mixed signal from view + controller issues simultaneously.
**Delivers:** `NotesController#create` (and `#destroy` shell), fixtures (`notes.yml`), `notes_controller_test.rb` covering auth, scoping, validation failure, and redirect
**Addresses:** FEATURES.md — `NotesController` create action (P1); PITFALLS.md — Pitfalls 2, 3, and 5 all verified by tests before any view code exists
**Avoids:** Pitfall 3 (mass assignment); Pitfall 5 (CSRF) — test the form POST before calling it done

### Phase 3: Welcome Page Tab UI

**Rationale:** Tab UI is the entry point to all note features. The `WelcomeController#index` change and the view restructuring must happen before the note gadget partial is visible. This phase also locks in the theme isolation decision.
**Delivers:** `WelcomeController#index` with `@notes` assigned; `welcome/index.html.erb` restructured into `#home` and `#notes` tab panels inside `<% if favorite_theme == 'simple' %>`; `common/_menu.html.erb` tab nav links; `notes.js` with `window.notes.initTabs()` and `URLSearchParams` tab restore; `welcome.css.scss` tab styles scoped under `.simple`
**Addresses:** FEATURES.md — tab links (P1); STACK.md — jQuery tab switching pattern
**Avoids:** Pitfall 1 (theme leakage — CSS and HTML both scoped to simple); Pitfall 6 (tab state — query param approach implemented from the start); Pitfall 7 (note form only visible in simple theme view)

### Phase 4: Note Gadget Partial + Integration Tests

**Rationale:** With the backend verified and the tab scaffold in place, the `_note_gadget` partial is the final assembly step. Integration tests confirm the full request cycle: load page, see tab, save note, return to note tab, see note in list.
**Delivers:** `welcome/_note_gadget.html.erb` with textarea form and reverse-chronological note list; empty-state message; timestamp per note; Cucumber/integration tests for the full flow; "looks done but isn't" checklist items verified
**Addresses:** FEATURES.md — textarea + save (P1), reverse-chronological list (P1), empty state (P1), timestamp (P1)
**Avoids:** Pitfall 4 (N+1 — verify single SELECT in development log); Pitfall 5 (CSRF — submit form and confirm no 422); XSS — confirm `<script>` content renders as escaped text

### Phase 5: Delete Note (P2)

**Rationale:** Delete is a per-row action that depends on the list existing. Deferred to P2 because it adds a destroy action and a confirm dialog without affecting MVP completeness. Low complexity — can be a fast follow after Phase 4 is confirmed working.
**Delivers:** `NotesController#destroy` fully wired; per-row delete link in `_note_gadget`; soft-delete consistent with `Crud::ByUser`; destroy test in `notes_controller_test.rb`
**Addresses:** FEATURES.md — delete note (P2)
**Avoids:** Pitfall 2 (ownership on destroy — `readable_by?(current_user)` guard)

### Phase Ordering Rationale

- Phases 1 and 2 are ordered by strict dependency: the table must exist before the controller can be written; the controller must be tested before views are added.
- Phases 3 and 4 are separated because the tab scaffold (Phase 3) is pure structural work that does not depend on note-specific content, while the gadget partial (Phase 4) fills in the note-specific content. This separation makes it easy to verify theme isolation before any note HTML is in the DOM.
- Phase 5 is isolated because delete is a P2 feature that depends only on the list (Phase 4) being complete.
- All four research files agree on this ordering. There are no circular dependencies.

### Research Flags

Phases with standard, well-documented patterns — skip deeper research:
- **Phase 1 (Data Layer):** Standard Rails migration. The exact migration syntax is already in STACK.md. No research needed.
- **Phase 2 (Controller):** Direct replication of `todos_controller.rb` pattern. All code samples verified from codebase.
- **Phase 3 (Tab UI):** jQuery `show()`/`hide()` with `URLSearchParams`. Pattern is proven in this codebase. No research needed.
- **Phase 4 (Gadget Partial):** ERB + Rails form helpers. Standard patterns throughout the app.
- **Phase 5 (Delete):** Direct replication of todo delete pattern. No research needed.

No phase requires a `/gsd-research-phase` deep-dive. All patterns are established within this codebase.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct codebase inspection; no new dependencies; todos gadget is a complete, working reference |
| Features | HIGH | Scope tightly defined by PROJECT.md; feature table derived from existing gadget comparisons in the codebase |
| Architecture | HIGH | All component boundaries verified by reading the actual source files; build order derives from import/render dependencies |
| Pitfalls | HIGH | All pitfalls identified from direct inspection of affected files; no speculation |

**Overall confidence:** HIGH

### Gaps to Address

No significant gaps were found. The following minor decisions can be deferred to implementation:

- **AJAX vs full-page POST for note create:** Research recommends full-page POST for MVP (simpler, consistent with bookmarks/preferences), with AJAX as a P2 option. The decision does not affect Phase 1 or 2. Confirm during Phase 4 based on perceived UX.
- **Note list limit:** Research recommends `.limit(50)` from day one, but the exact number is not critical. Confirm during Phase 2 controller implementation.
- **Tab nav placement in `_menu.html.erb`:** The exact DOM position of tab links relative to the existing dropdown is a visual detail. Confirm during Phase 3 by visual inspection in the browser.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `app/controllers/todos_controller.rb`, `app/controllers/bookmarks_controller.rb`, `app/controllers/welcome_controller.rb` — controller patterns, scoping, params
- Direct codebase inspection: `app/assets/javascripts/todos.js`, `app/views/welcome/_todo_gadget.html.erb` — XHR partial pattern, jQuery namespace convention
- Direct codebase inspection: `app/assets/stylesheets/themes/simple.css.scss`, `app/assets/stylesheets/welcome.css.scss` — CSS scoping under `.simple`
- Direct codebase inspection: `app/views/welcome/index.html.erb`, `app/views/common/_menu.html.erb`, `app/views/layouts/application.html.erb` — view structure and theme switching
- Direct codebase inspection: `db/schema.rb`, `config/routes.rb`, `app/models/crud/by_user.rb` — schema, routing, user-scoping concerns
- Rails 8.1 guides (form helpers, ActiveRecord migrations) — confirmed standard patterns match existing app usage

### Secondary (MEDIUM confidence)
- `.planning/codebase/STACK.md` (analysed 2026-04-27) — confirmed Sprockets + jQuery 4 + rails-ujs pipeline, no Turbo/Stimulus
- `.planning/codebase/ARCHITECTURE.md` — gadget protocol description, `Crud::ByUser` pattern, portal layout flow
- `.planning/PROJECT.md` — milestone scope definition (simple theme only, no Turbo constraint)

---
*Research completed: 2026-04-30*
*Ready for roadmap: yes*
