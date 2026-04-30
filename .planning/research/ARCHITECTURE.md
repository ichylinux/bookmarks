# Architecture Research

**Domain:** Quick Note Gadget — Rails 8.1 MVC addition to existing personal dashboard
**Researched:** 2026-04-30
**Confidence:** HIGH (all findings derived from direct codebase inspection)

## Standard Architecture

### System Overview

```
Browser
  |
  | GET /  (WelcomeController#index)
  v
ApplicationLayout (app/views/layouts/application.html.erb)
  body class="<%= favorite_theme %>"          <- simple / modern / classic
  |
  +-- render 'common/menu'  [IF simple theme] <- tab nav lives here for simple
  +-- yield
        |
        v
        welcome/index.html.erb               [MODIFY]
          div.tab-nav  (ホーム | ノート)       <- new; only visible in simple theme via CSS
          div.tab-panel#home                  <- wraps existing portal gadget grid
            @portal.portal_columns -> render g.class.name.underscore  (unchanged)
          div.tab-panel#notes                 <- new
            render 'welcome/note_gadget'

        welcome/_note_gadget.html.erb         [NEW]
          form -> POST /notes
          ul   -> @notes (reverse-chron, server-rendered)

Notes resource:
  POST   /notes      -> NotesController#create
  DELETE /notes/:id  -> NotesController#destroy  (optional for MVP)

  Note model: id, user_id, body:text, created_at, updated_at
  User has_many :notes
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `Note` model | Persist per-user note text | `belongs_to :user`, `validates :body, presence: true` |
| `NotesController` | Create (and optionally destroy) notes scoped to `current_user` | Thin controller; inherits `authenticate_user!`; no service layer |
| `WelcomeController#index` | Assign `@notes` alongside `@portal` | Single added line: `@notes = current_user.notes.order(created_at: :desc)` |
| `welcome/_note_gadget` partial | Note input form + list of existing notes | ERB partial; receives `@notes`; follows existing gadget partial placement in `app/views/welcome/` |
| `common/_menu` | Tab navigation for simple theme | Add "ホーム" and "ノート" tab links with `data-tab` attributes |
| `notes.js` | Tab switching behaviour | New file; `window.notes.initTabs()` namespace following `todos.js` pattern |
| `welcome.css.scss` | Tab panel show/hide, active tab styling | Existing file; add `.tab-nav`, `.tab-panel`, `.tab-nav a.active` rules |

## Recommended Project Structure

```
app/
+-- controllers/
|   +-- notes_controller.rb          [NEW] create (+ optional destroy)
+-- models/
|   +-- note.rb                      [NEW] belongs_to :user, validates :body
|   +-- user.rb                      [MODIFY] add has_many :notes
+-- views/
|   +-- welcome/
|   |   +-- index.html.erb           [MODIFY] wrap in tab panels; add notes panel
|   |   +-- _note_gadget.html.erb    [NEW] form + note list
|   +-- common/
|       +-- _menu.html.erb           [MODIFY] add tab nav links (simple theme context)
+-- assets/
    +-- javascripts/
    |   +-- notes.js                 [NEW] window.notes.initTabs(); called from welcome/index
    +-- stylesheets/
        +-- welcome.css.scss         [MODIFY] .tab-nav, .tab-panel, active state rules

config/
+-- routes.rb                        [MODIFY] resources :notes, only: [:create, :destroy]

db/
+-- migrate/
    +-- YYYYMMDDHHMMSS_create_notes.rb  [NEW]

test/
+-- controllers/
|   +-- notes_controller_test.rb     [NEW]
+-- fixtures/
    +-- notes.yml                    [NEW]
```

### Structure Rationale

- **`_note_gadget` partial in `welcome/`**: Follows the established pattern. All gadget partials live under `app/views/welcome/` (`_bookmark_gadget`, `_todo_gadget`, `_feed`, `_calendar`). The note gadget belongs here.
- **`NotesController` as independent resource**: Notes have their own CRUD, not a special action on `WelcomeController`. This keeps `WelcomeController` focused on portal layout state, consistent with the thin-controller convention.
- **`WelcomeController` assigns `@notes`**: The note gadget partial is rendered inside the welcome page view, so assigning `@notes` in `WelcomeController#index` is the direct path. One extra query per homepage load — acceptable for a personal app.
- **`notes.js` dedicated file**: Matches the one-file-per-feature convention (`todos.js`, `bookmarks.js`, `menu.js`). Sprockets `require_tree .` picks it up automatically. Participates in ESLint (`yarn run lint`).
- **No gadget protocol object**: The existing gadget protocol (`BookmarkGadget`, `TodoGadget`) serves the draggable portal grid (`PortalLayout`, `save_state`). The note gadget lives in a separate tab outside the grid — there is nothing to drag or order. Wrapping it in the gadget protocol adds `PortalLayout` complexity with no benefit.

## Architectural Patterns

### Pattern 1: Thin Controller, Direct AR Query

**What:** `NotesController` queries `Note` directly scoped via `current_user.notes`. No service object, no gadget wrapper.
**When to use:** Any simple per-user resource with no complex business rules.
**Trade-offs:** Fits established app conventions exactly; no added abstraction layer.

**Example:**
```ruby
class NotesController < ApplicationController
  def create
    @note = current_user.notes.build(note_params)
    if @note.save
      redirect_to root_path(tab: 'notes')
    else
      @portal = current_user.portals.first
      @notes  = current_user.notes.order(created_at: :desc)
      render 'welcome/index'
    end
  end

  private

  def note_params
    params.require(:note).permit(:body)
  end
end
```

### Pattern 2: Tab Panels via CSS Show/Hide (No SPA, No AJAX)

**What:** Two `div.tab-panel` elements rendered server-side inside `welcome/index.html.erb`. JavaScript on `$(document).ready` hides all panels and shows the active one based on a `data-tab` query param or default.
**When to use:** Simple two-tab UI in a server-rendered app with Sprockets/jQuery. Avoids Turbo or fetch complexity.
**Trade-offs:** Full page content loads on every request. Fine for a personal dashboard with small data volumes. Keeps JS minimal and fully within the existing jQuery pattern.

**Example:**
```javascript
// app/assets/javascripts/notes.js
window.notes = window.notes || {};
const notes = window.notes;

notes.initTabs = function() {
  const $tabLinks = $('.tab-nav a[data-tab]');
  const $panels   = $('.tab-panel');

  $tabLinks.on('click', function(e) {
    e.preventDefault();
    const target = $(this).data('tab');
    $tabLinks.removeClass('active');
    $(this).addClass('active');
    $panels.hide();
    $('#' + target).show();
  });

  // Restore tab from query param on page load (e.g. after note save redirect)
  const params = new URLSearchParams(window.location.search);
  const active = params.get('tab') || 'home';
  $tabLinks.filter('[data-tab="' + active + '"]').trigger('click');
};
```

### Pattern 3: Standard POST + Redirect (Non-AJAX)

**What:** The note form uses a standard HTML form POST. On success, redirect to `root_path(tab: 'notes')` so the notes tab re-activates via `initTabs`.
**When to use:** MVP. Consistent with the app's general non-AJAX forms (bookmarks, preferences, calendars all use standard redirects).
**Trade-offs:** Full page reload on save. Acceptable for a personal note tool. Can be upgraded to AJAX submit in a later phase if the reload feels disruptive.

## Data Flow

### Request Flow — Note Creation

```
User fills textarea, clicks Save
    |
    | POST /notes  {note: {body: "..."}}
    v
ApplicationController#authenticate_user!  (existing before_action)
    |
    v
NotesController#create
    |
    +-- current_user.notes.build(note_params)
    +-- @note.save
    |
    +-- success -> redirect_to root_path(tab: 'notes')
    |
    +-- failure -> @portal = ..., @notes = ..., render 'welcome/index'
```

### Request Flow — Welcome Page (with Notes tab)

```
GET /  (or GET /?tab=notes after redirect)
    v
WelcomeController#index
    @portal = current_user.portals.first      (existing)
    @notes  = current_user.notes              (NEW — 1 extra query)
                .order(created_at: :desc)
    v
welcome/index.html.erb
    div.tab-nav  (ホーム | ノート)
    div.tab-panel#home   -> portal gadget grid (existing, unchanged)
    div.tab-panel#notes  -> render 'welcome/note_gadget',
                               notes: @notes
    v
notes.js#initTabs()  (DOM ready: read ?tab=, show correct panel)
```

### Key Data Flows

1. **Tab activation on redirect:** `root_path(tab: 'notes')` carries a query param. `notes.initTabs()` reads `URLSearchParams` on `$(document).ready` and triggers click on the matching tab link. No server-side tab state needed.
2. **Note list refresh:** Server-rendered in `_note_gadget` on every page load. New note appears after the save-and-redirect cycle. No polling or WebSockets.
3. **User scoping:** `current_user.notes` association. `Note` has `user_id` foreign key. `User has_many :notes`. No global scope — consistent with how all other resources in this app are scoped (manual convention from `.planning/codebase/ARCHITECTURE.md`).

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Personal use (1-3 users) | Current approach — no changes needed |
| Multi-user (10-1k users) | Add index on `notes(user_id, created_at)` — include in the migration from the start |
| Many notes per user | Add `limit(50)` in `WelcomeController#index` query — not needed for MVP |

### Scaling Priorities

1. **First bottleneck:** `@notes` grows large for a prolific user. Mitigation: add `.limit(50)` to the query before it becomes an issue. Index on `(user_id, created_at)` keeps this fast.
2. **Not a concern:** Tab switching is pure CSS/JS — zero server overhead.

## Anti-Patterns

### Anti-Pattern 1: Adding Note Actions to WelcomeController

**What people do:** Put `create_note`, `destroy_note` actions directly in `WelcomeController` to "keep notes close to the welcome page."
**Why it's wrong:** Violates REST conventions. Bloats a controller already responsible for portal layout state. Routes become non-standard and harder to test in isolation.
**Do this instead:** Use a dedicated `NotesController` with standard `resources :notes` routing.

### Anti-Pattern 2: Wrapping Note in the Gadget Protocol

**What people do:** Create a `NoteGadget` plain Ruby object following the `BookmarkGadget` / `TodoGadget` pattern and register it via `Portal#get_gadgets`.
**Why it's wrong:** The gadget protocol exists for the draggable portal grid (`PortalLayout` rows, `save_state` AJAX, column ordering). Notes live in a fixed tab outside the grid. There is nothing to drag or reorder. Using the gadget protocol adds `PortalLayout` rows and `Portal` complexity with no benefit.
**Do this instead:** Render the note gadget partial directly in `welcome/index.html.erb` inside the `#notes` tab panel. Assign `@notes` in `WelcomeController#index`.

### Anti-Pattern 3: AJAX-First Note Submission in MVP

**What people do:** Wire the note form to submit via `$.post` and re-render the list in place.
**Why it's wrong:** Adds JS error handling complexity for a personal tool where sub-second response is not required. Deviates from the app's standard form-POST-and-redirect pattern without a user-visible benefit at MVP stage.
**Do this instead:** Standard form POST with redirect to `root_path(tab: 'notes')`. Add AJAX in a later phase if reload feels disruptive.

### Anti-Pattern 4: Tab State in Session or Database

**What people do:** Store the active tab server-side (session hash or new preference column) so the tab persists across requests without a query param.
**Why it's wrong:** Over-engineering for two tabs. Adds a round-trip or a schema change for trivial benefit.
**Do this instead:** Pass `tab: 'notes'` as a query param in the redirect URL. Restore from `URLSearchParams` in `notes.js`. Stateless, no extra storage.

## Integration Points

### New vs Modified Files — Complete List

| File | Status | What Changes |
|------|--------|--------------|
| `app/models/note.rb` | NEW | `belongs_to :user`, `validates :body, presence: true` |
| `app/controllers/notes_controller.rb` | NEW | `create` action; optional `destroy` |
| `app/views/welcome/_note_gadget.html.erb` | NEW | Form (`note[body]` textarea + submit) + `<ul>` of notes |
| `db/migrate/*_create_notes.rb` | NEW | `user_id`, `body:text`, timestamps; index on `(user_id, created_at)` |
| `config/routes.rb` | MODIFY | Add `resources :notes, only: [:create, :destroy]` |
| `app/models/user.rb` | MODIFY | Add `has_many :notes` |
| `app/views/welcome/index.html.erb` | MODIFY | Wrap portal grid in `div.tab-panel#home`; add `div.tab-panel#notes` rendering `_note_gadget` |
| `app/views/common/_menu.html.erb` | MODIFY | Add tab nav links with `data-tab` attributes above existing dropdown nav |
| `app/assets/javascripts/notes.js` | NEW | `window.notes.initTabs()` called from welcome/index on DOM ready |
| `app/assets/stylesheets/welcome.css.scss` | MODIFY | `.tab-nav`, `.tab-panel` (default hidden), `.tab-nav a.active` |
| `app/controllers/welcome_controller.rb` | MODIFY | Add `@notes = current_user.notes.order(created_at: :desc)` in `#index` |
| `test/controllers/notes_controller_test.rb` | NEW | Auth, scoping, create, optional destroy tests |
| `test/fixtures/notes.yml` | NEW | Fixture rows for test assertions |

### Unchanged Files (confirmed safe)

| File | Why Unchanged |
|------|---------------|
| `app/assets/javascripts/application.js` | `require_tree .` picks up `notes.js` automatically |
| `app/assets/stylesheets/application.css` | `require_tree .` picks up `welcome.css.scss` changes automatically |
| `app/helpers/welcome_helper.rb` | `favorite_theme` unchanged — tab nav is inside the simple-theme `_menu` partial |
| `app/views/layouts/application.html.erb` | No changes needed — layout already conditionally renders `_menu` for simple theme |
| `app/models/portal.rb`, `app/models/portal_layout.rb` | Note gadget does not participate in the portal grid |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `WelcomeController` -> `Note` | Direct AR query via `current_user.notes` | One query added to `#index`; no coupling to `NotesController` |
| `NotesController` -> `WelcomeController` | `redirect_to root_path(tab: 'notes')` on success | One-way; `NotesController` calls no `WelcomeController` methods |
| `welcome/index.html.erb` -> `_note_gadget` | `render 'welcome/note_gadget'` with `@notes` in scope | Follows existing gadget partial rendering convention |
| `notes.js` -> `_menu` tab links | Reads `data-tab` attribute on `<a>` elements | Loose coupling via HTML attribute contract |
| Simple theme tab styles | `.simple .tab-nav`, `.simple .tab-panel` in `welcome.css.scss` | Consistent with `.simple` scoping in `themes/simple.css.scss` |

## Recommended Build Order

Dependencies drive this sequence:

1. **Migration + `Note` model + `User has_many :notes`** — everything else depends on the `notes` table existing and the association being valid. Test with `bundle exec rails db:migrate`.

2. **`config/routes.rb`** — add `resources :notes, only: [:create, :destroy]`. Required before controller tests can route.

3. **`NotesController`** — `create` action (and optional `destroy`). Verify scoping (`current_user.notes.build`) and auth (`authenticate_user!` inherited). Testable without any view changes.

4. **`test/fixtures/notes.yml` + `test/controllers/notes_controller_test.rb`** — verify create scoping, auth guard, validation failure. Green tests confirm the backend is correct before wiring views.

5. **`WelcomeController#index`** — add `@notes = current_user.notes.order(created_at: :desc)`. One line. Confirm existing welcome tests still pass.

6. **`welcome/_note_gadget.html.erb`** — note form and list partial. Can be developed and visually checked immediately since `@notes` is now assigned.

7. **`welcome/index.html.erb`** — wrap existing portal content in `div.tab-panel#home`; add `div.tab-panel#notes` rendering the partial. Confirm existing portal functionality is unchanged.

8. **`common/_menu.html.erb`** — add tab nav links (`data-tab="home"`, `data-tab="notes"`) above the existing dropdown. Simple theme context ensures they appear correctly.

9. **`notes.js`** — `window.notes.initTabs()` function; wire via `$(document).ready` call in `welcome/index.html.erb`. Tab switching is now functional.

10. **`welcome.css.scss`** — `.tab-nav`, `.tab-panel` (hidden by default, shown by JS), `.tab-nav a.active` styles. Visual polish; iterate after functionality is confirmed.

11. **Welcome controller integration tests** — assert `#notes` tab panel present in response, note list partial renders, tab nav links exist, scoping correct. Follows pattern of existing `welcome_controller_test.rb`.

Steps 3 and 6 are independent of each other and can proceed in parallel once step 1 is complete.

## Sources

- Direct inspection: `app/controllers/welcome_controller.rb`, `app/views/welcome/`, `app/views/common/_menu.html.erb`, `app/views/layouts/application.html.erb`
- Direct inspection: `.planning/codebase/ARCHITECTURE.md` (gadget protocol, portal flow, `Crud::ByUser` pattern, user-scoping conventions)
- Direct inspection: `app/assets/javascripts/todos.js` (namespace and jQuery pattern)
- Direct inspection: `app/assets/stylesheets/themes/simple.css.scss` (simple theme CSS scoping approach)
- Direct inspection: `test/controllers/welcome_controller/welcome_controller_test.rb`, `test/controllers/todos_controller_test.rb` (test conventions)
- Direct inspection: `config/routes.rb` (existing resource routing patterns)
- Direct inspection: `app/models/todo.rb`, `app/models/crud/by_user.rb` (per-user model pattern)

---
*Architecture research for: Quick Note Gadget (v1.3)*
*Researched: 2026-04-30*
