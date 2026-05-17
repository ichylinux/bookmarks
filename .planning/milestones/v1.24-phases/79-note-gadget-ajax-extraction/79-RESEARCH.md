# Phase 79: Note Gadget AJAX Extraction - Research

**Researched:** 2026-05-17
**Domain:** Rails controller action, jQuery AJAX, JS tab loading guard, view partial wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Route: `collection { get :gadget }` inside `resources :notes` → `GET /notes/gadget`
- Action renders with `layout: false` (consistent with `calendars#get_gadget`)
- Authentication: existing `before_action :authenticate_user!` from `ApplicationController` — redirects to sign-in if unauthenticated
- View: `app/views/notes/gadget.html.erb` that renders `render 'welcome/note_gadget'` — new file, existing partial reused
- Simple theme: extend `notes_tabs.js` with a `loaded` flag; on first `activateTab('notes')` call, fire `$.get('/notes/gadget')` and replace `#notes-tab-panel` contents
- Modern/classic theme: inline `<script>` at the bottom of the `#notes-tab-panel` placeholder, server-conditionally emitting JS to fire `$.get('/notes/gadget')` on `$(document).ready` when `params[:tab] == 'notes'`
- Initial placeholder HTML inside `#notes-tab-panel`: `<div class="note-gadget-loading">` with `t('welcome.loading')` text span
- Error handling: `console.warn` only (silent degradation)
- Update `welcome_controller_test.rb` to remove `@note`/`@notes` assigns assertions; add assertions that they are NOT assigned
- Add `test_gadget` to `notes_controller_test.rb` asserting: 200 response, `@note` is a new Note, `@notes` is the user's active notes, no layout rendered
- Existing Cucumber notes scenarios left as-is
- Add NOTE-01, NOTE-02, NOTE-03 to `REQUIREMENTS.md` during this phase

### Claude's Discretion

- Exact i18n key for the loading placeholder text (reuse `welcome.loading` if it exists, or add `notes.gadget.loading`)
- Whether to name the JS `loaded` flag `_notesLoaded` or similar to avoid conflicts

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTE-01 | `NotesController` has a `gadget` action that sets `@note` / `@notes` and renders the note gadget partial as an HTML fragment (`layout: false`) | `CalendarsController#get_gadget` is the direct pattern; `_note_gadget.html.erb` already uses `@note` / `@notes` |
| NOTE-02 | `WelcomeController#index` no longer assigns `@note` or `@notes` — removing those queries from every dashboard page load | Two lines removed from `WelcomeController#index`; welcome test suite has many tests that will need their `#notes-tab-panel` assertions migrated to the gadget endpoint |
| NOTE-03 | On the simple theme, the first click on the notes tab triggers one AJAX request to `notes#gadget`; subsequent clicks use the already-loaded DOM. On modern/classic with `?tab=notes`, the note gadget is fetched immediately on page load | `notes_tabs.js` gets a `var notesLoaded = false` guard; `_dashboard.html.erb` gets an inline `<script>` conditional on `params[:tab] == 'notes'` for modern/classic |
</phase_requirements>

---

## Summary

Phase 79 extracts the note gadget from server-side rendering into an AJAX-fetched HTML fragment. The work is purely an extraction refactor: the existing `_note_gadget.html.erb` partial is untouched, the CRUD actions are untouched, and the visual result is identical for the user. The only changes are (1) where the DB queries happen (`NotesController#gadget` instead of `WelcomeController#index`), (2) how the HTML arrives in the browser (AJAX on first tab visit rather than SSR inline), and (3) the loading placeholder that briefly appears before the gadget content arrives.

The pattern is firmly established in this codebase. `CalendarsController#get_gadget` is an exact structural precedent: a collection action on a resourceful controller, `render layout: false`, returning a plain HTML fragment that replaces a placeholder div. The `_calendar_gadget.html.erb` and `_x_account.html.erb` partials both show the inline-script + `portalLazy.register` pattern for AJAX loading on the desktop portal — though notes uses a simpler mechanism (no `portalLazy` needed, since the notes tab is not a portal column).

The most important planning consideration is the **welcome controller test suite**. `dashboard_test.rb` has many tests (`test_シンプルテーマのノートパネルにメモフォームが表示される`, `test_モダンテーマのノートパネルが日本語ロケールで表示される`, etc.) that currently assert `.note-gadget` markup exists in the SSR response to `GET /`. After Phase 79 those assertions will fail because the panel will only contain a loading placeholder. These tests must be migrated to a new `notes_controller/gadget_test.rb` that hits `GET /notes/gadget`.

**Primary recommendation:** Model the new action strictly after `CalendarsController#get_gadget`, migrate the content assertions from `dashboard_test.rb` to a new `notes_controller/gadget_test.rb`, and update `_dashboard.html.erb` to replace the two `render 'note_gadget'` calls with a loading placeholder plus theme-conditional inline script.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Serving note gadget HTML fragment | API / Backend (`NotesController#gadget`) | — | Authentication + DB query belong server-side |
| Loading placeholder markup | Frontend Server (SSR via `_dashboard.html.erb`) | — | Panel container must exist in SSR for JS to target |
| AJAX fetch trigger (simple theme) | Browser JS (`notes_tabs.js`) | — | Tab-click event is client-side only |
| AJAX fetch trigger (modern/classic) | Frontend Server (inline `<script>` emitted conditionally) | Browser JS | Server decides whether `?tab=notes` is active; JS fires the request |
| Fragment insertion into DOM | Browser JS (`$.get` callback) | — | Response HTML injected via `.html()` |

---

## Standard Stack

No new packages. This phase uses only what is already installed.

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails (resourceful routing) | 7.2 [VERIFIED: codebase] | `collection { get :gadget }` route | Project standard; matches `calendars#get_gadget` pattern exactly |
| jQuery `$.get` | already loaded [VERIFIED: codebase] | AJAX fetch from `notes_tabs.js` and inline `<script>` | All other AJAX gadgets use `$.get` — established project pattern |

### No Package Legitimacy Audit Required

This phase installs zero external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser (simple theme)
  user clicks "notes" tab
       |
       v
notes_tabs.js activateTab('notes')
  notesLoaded == false?
       |  yes
       v
  $.get('/notes/gadget')
       |
       v
NotesController#gadget
  authenticate_user!
  @note = Note.new
  @notes = current_user.notes.active.recent
  render 'notes/gadget', layout: false
       |
       v
notes/gadget.html.erb
  render 'welcome/note_gadget'   (existing partial, unchanged)
       |
       v
HTML fragment response
       |
       v
$('#notes-tab-panel').html(html)
  notesLoaded = true
  (subsequent clicks: notesLoaded == true → no request)

---

Browser (modern/classic theme, ?tab=notes)
  page load
       |
       v
_dashboard.html.erb
  if use_note && params[:tab] == 'notes'
    emit inline <script>
       |
       v
$(document).ready
  $.get('/notes/gadget')
       |
       v  (same backend path as above)
$('#notes-tab-panel').html(html)
```

### Recommended Project Structure

No new directories required.

```
app/
├── controllers/
│   └── notes_controller.rb        # add gadget action
├── views/
│   ├── notes/                     # NEW directory
│   │   └── gadget.html.erb        # NEW file — one line: render 'welcome/note_gadget'
│   └── welcome/
│       ├── _dashboard.html.erb    # replace render 'note_gadget' with placeholder + script
│       └── _note_gadget.html.erb  # UNCHANGED
├── assets/
│   └── javascripts/
│       └── notes_tabs.js          # add notesLoaded guard + $.get
config/
└── routes.rb                      # add collection { get :gadget } to resources :notes
test/
├── controllers/
│   ├── notes_controller_test.rb   # add test_gadget
│   └── welcome_controller/
│       └── dashboard_test.rb      # remove note-gadget content assertions; add NOT-assigned guards
```

### Pattern 1: Collection Action Returning HTML Fragment (established codebase pattern)

**What:** A controller action on a resourceful controller that sets instance variables and renders a view with `layout: false`.
**When to use:** Whenever a gadget's content is fetched separately from the page that hosts it.

```ruby
# Source: app/controllers/calendars_controller.rb [VERIFIED: codebase]
def get_gadget
  head :not_found and return unless current_user.preference.use_calendar?

  @calendar_gadget = CalendarGadget.new(current_user)
  @calendar_gadget.display_date = Date.parse(params[:display_date])
  render layout: false
end
```

For notes, the analogous action is simpler (no preference guard needed — the panel is only
rendered server-side when `use_note` is true, so gadget action is only reachable if the
user has navigated to the notes panel):

```ruby
# app/controllers/notes_controller.rb — new action
def gadget
  @note  = Note.new
  @notes = current_user.notes.active.recent
  render layout: false
end
```

### Pattern 2: View Template That Wraps an Existing Partial

```erb
<%# app/views/notes/gadget.html.erb — new file [ASSUMED: single-line approach from CONTEXT.md] %>
<%= render 'welcome/note_gadget' %>
```

The partial `_note_gadget.html.erb` already uses `@note` and `@notes`, which the new
action assigns. No changes to the partial.

### Pattern 3: Loading Placeholder in _dashboard.html.erb

Current code (both simple and modern/classic branches):
```erb
<div id="notes-tab-panel" ...>
  <%= render 'note_gadget' %>
</div>
```

Replacement (both branches — placeholder only, with conditional inline script for modern/classic):
```erb
<%# simple theme branch %>
<div id="notes-tab-panel" class="simple-tab-panel<%= ' simple-tab-panel--hidden' unless notes_active %>" role="tabpanel">
  <div class="note-gadget-loading">
    <span><%= t('welcome.note_gadget.loading') %></span>
  </div>
</div>

<%# modern/classic theme branch — same placeholder, plus conditional inline script %>
<div id="notes-tab-panel" class="welcome-tab-panel<%= ' welcome-tab-panel--hidden' unless notes_active %>" role="tabpanel">
  <div class="note-gadget-loading">
    <span><%= t('welcome.note_gadget.loading') %></span>
  </div>
  <% if notes_active %>
    <script>
      $(document).ready(function() {
        $.get('<%= gadget_notes_path %>', function(html) {
          $('#notes-tab-panel').html(html);
        }).fail(function(xhr) {
          console.warn('note gadget load failed', xhr.status);
        });
      });
    </script>
  <% end %>
</div>
```

### Pattern 4: notes_tabs.js Load-Once Guard

**What:** Module-level boolean prevents re-fetching after the first successful load.
**When to use:** Any time a tab panel's content is loaded lazily from a JS event handler.

```javascript
// app/assets/javascripts/notes_tabs.js [ASSUMED: derived from CONTEXT.md specifics]
$(function() {
  if (!$('body').hasClass('simple')) return;

  var notesLoaded = false;  // NEW: load-once guard

  const $homePanel  = $('#simple-home-panel');
  const $notesPanel = $('#notes-tab-panel');
  const $tabs       = $('button.simple-tab[data-simple-tab]');

  const activateTab = (which) => {
    const isNotes = which === 'notes';
    $tabs.removeClass('simple-tab--active');
    $tabs.filter(`[data-simple-tab="${which}"]`).addClass('simple-tab--active');

    if (isNotes) {
      $homePanel.addClass('simple-tab-panel--hidden');
      $notesPanel.removeClass('simple-tab-panel--hidden');

      // NEW: lazy-load on first visit
      if (!notesLoaded) {
        notesLoaded = true;
        $.get('/notes/gadget', function(html) {
          $notesPanel.html(html);
        }).fail(function(xhr) {
          console.warn('note gadget load failed', xhr.status);
        });
      }
    } else {
      $homePanel.removeClass('simple-tab-panel--hidden');
      $notesPanel.addClass('simple-tab-panel--hidden');
    }
  };

  // rest of file unchanged ...
});
```

Note: `notesLoaded` is set to `true` *before* the `$.get` resolves (synchronously on the
first call), consistent with IMPL-04 pattern from Phase 77 that prevents duplicate
in-flight requests on rapid tab switching.

### Anti-Patterns to Avoid

- **Setting `notesLoaded` inside the `.done()` callback:** If the user clicks the notes
  tab twice before the response arrives, a second request fires. Set the flag synchronously
  before `$.get`, exactly as the portal column lazy loader does.
- **Guarding the gadget action with a preference check:** The calendar gadget does this
  (`head :not_found unless use_calendar?`), but for notes the dashboard already conditionally
  omits `#notes-tab-panel` when `use_note` is false. Adding a guard in the controller is
  harmless but unnecessary — leave it out to keep the action simple.
- **Using `render partial:` in the controller:** Use the view file
  (`app/views/notes/gadget.html.erb`) which renders the partial. This matches how
  `CalendarsController` delegates to its view file.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AJAX fragment loading | Custom XHR wrapper | `$.get(url, callback).fail(handler)` | Already used by all other gadget partials in the project |
| Load-once state | Timestamp comparison or DOM inspection | Module-level boolean variable | Simplest reliable pattern; no race condition if set synchronously |
| Authentication check | Explicit `current_user` nil guard in `gadget` action | `before_action :authenticate_user!` from `ApplicationController` | Already inherited; unauthenticated requests redirect to sign-in automatically |

---

## Common Pitfalls

### Pitfall 1: dashboard_test.rb content assertions fail after SSR removal

**What goes wrong:** Many tests in `dashboard_test.rb` do `get root_path(tab: 'notes')` and assert `.note-gadget`, `form.note-gadget-form`, `#notes-tab-panel .note-empty`, etc. After Phase 79, `#notes-tab-panel` only contains the loading placeholder in the SSR response — these assertions will fail.

**Why it happens:** The tests were written when the note gadget was SSR. They are not wrong; they need to move to the gadget endpoint.

**How to avoid:** Migrate all note-content assertions to a new `test/controllers/notes_controller/gadget_test.rb` (or add them to `notes_controller_test.rb`) that hits `GET /notes/gadget` directly. The `dashboard_test.rb` tests for `#notes-tab-panel` should be reduced to structural assertions (panel exists, has loading placeholder) rather than content assertions.

**Warning signs:** A red Minitest run with failures all pointing at `#notes-tab-panel .note-gadget` or `form.note-gadget-form` assertions in `dashboard_test.rb`.

### Pitfall 2: i18n key for loading text does not exist

**What goes wrong:** The CONTEXT.md says use `t('welcome.loading')` but the actual locale file has no generic `welcome.loading` key — each gadget has its own loading key (e.g., `welcome.calendar_gadget.loading`, `welcome.feed.loading`). Using `t('welcome.loading')` raises a `I18n::MissingTranslationData` exception in production (and returns a `[missing ...]` string in test).

**Why it happens:** The locale structure is per-gadget, not global. [VERIFIED: codebase — ja.yml and en.yml confirmed]

**How to avoid:** Add a `loading:` key under `welcome.note_gadget` in both `ja.yml` and `en.yml`. The existing `welcome.note_gadget` namespace is the right home. Example: `welcome.note_gadget.loading: ノートを読み込み中・・・` / `Loading notes...`.

**Warning signs:** `translation missing: ja.welcome.loading` in test output or logs.

### Pitfall 3: `gadget_notes_path` helper does not exist until route is added

**What goes wrong:** ERB in `_dashboard.html.erb` references `gadget_notes_path` before `config/routes.rb` is updated. Boot or request fails.

**Why it happens:** Rails route helpers are generated from `routes.rb`; if the route is not present the helper method does not exist.

**How to avoid:** Add the route before referencing the helper. In a single-plan phase this just means writing routes.rb first in the task sequence.

### Pitfall 4: Missing `app/views/notes/` directory

**What goes wrong:** Rails cannot find `notes/gadget` template — raises `ActionView::MissingTemplate`.

**Why it happens:** The `notes/` view directory does not currently exist (verified: `app/views/notes/` is absent).

**How to avoid:** Create both the directory and `gadget.html.erb` as explicit steps in the plan.

### Pitfall 5: `_note_gadget.html.erb` i18n partial path vs namespace

**What goes wrong:** The partial uses `t('.body_label')` etc., which resolves relative to the partial's template path: `welcome.note_gadget.*`. When rendered from `notes/gadget.html.erb` → `render 'welcome/note_gadget'`, the resolution path is still `welcome.note_gadget.*` (Rails resolves relative keys based on the *partial's own path*, not the caller's path). This means i18n works correctly without any changes.

**Why it happens:** Rails `t('.')` resolution uses the file path of the calling template, and `_note_gadget.html.erb` lives in `app/views/welcome/`, so its relative keys always resolve under `welcome.note_gadget`.

**How to avoid:** No action needed — confirm by understanding Rails' partial i18n scoping. Do not move the partial or change any i18n keys.

---

## Code Examples

### Verified: Route pattern (from routes.rb)

```ruby
# Source: config/routes.rb [VERIFIED: codebase]
# Existing pattern (calendars):
resources :calendars, only: [] do
  collection do
    get :get_gadget
  end
end

# Phase 79 addition (notes):
resources :notes, only: [:create, :update, :destroy] do
  collection do
    get :gadget
  end
end
```

This generates `gadget_notes GET /notes/gadget(.:format) notes#gadget`.

### Verified: layout: false render (from CalendarsController)

```ruby
# Source: app/controllers/calendars_controller.rb [VERIFIED: codebase]
render layout: false
```

No format block needed — the route will respond to HTML by default.

### Verified: Minitest pattern for no-layout assertion

```ruby
# Source: existing notes_controller_test.rb pattern [VERIFIED: codebase]
sign_in @user
get gadget_notes_path
assert_response :success
assert_nil @response.headers['X-Layout']   # layout: false means no layout applied
# OR simply check that full layout elements are absent:
assert_no_match '<html>', response.body
```

The simplest approach: assert that the response body does NOT include the `<html>` tag (which would be present if layout were rendered). Several tests in this project use `assert_select` on response body — that works on raw HTML fragments too.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Server-render note gadget into `_dashboard.html.erb` directly | AJAX-fetch fragment on first tab visit | Phase 79 | Removes two DB queries (`Note.new` and `notes.active.recent`) from every dashboard page load by non-notes-tab users |

**Deprecated/outdated after this phase:**
- `@note = Note.new` in `WelcomeController#index` — removed
- `@notes = current_user.notes.active.recent` in `WelcomeController#index` — removed
- `render 'note_gadget'` inside `#notes-tab-panel` in `_dashboard.html.erb` — replaced with placeholder

---

## Test Impact Analysis

This is the most complex part of the phase. The existing test suite must be audited and split.

### Tests to REMOVE from `dashboard_test.rb`

These currently assert note-gadget markup in the SSR response. After Phase 79 they will fail because the SSR response only contains the loading placeholder:

- `test_シンプルテーマのノートパネルにメモフォームが表示される` — asserts `form.note-gadget-form`, `section.note-gadget`, etc.
- `test_シンプルテーマでメモがないとき空状態を表示する` — asserts `.note-empty`
- `test_シンプルテーマのノートパネルが英語ロケールで表示される` — asserts form labels
- `test_シンプルテーマでメモは新しい順に表示される...` — asserts note list order + badges
- `test_モダンテーマのノートパネルが日本語ロケールで表示される` — asserts form + empty state
- `test_モダンテーマのノートパネルが英語ロケールで表示される` — asserts form + empty state
- `test_クラシックテーマのノートパネルが日本語ロケールで表示される` — asserts form + empty state
- `test_クラシックテーマのノートパネルが英語ロケールで表示される` — asserts form + empty state
- `test_ノートパネルには他ユーザーのメモが表示されない` — asserts note body in response

### Tests to KEEP in `dashboard_test.rb` (with possible minor updates)

These test panel visibility, CSS class toggling, and theme switching — structural concerns unaffected by AJAX extraction:

- `test_シンプルテーマでuse_noteがfalseのときノートパネルが表示されない` — OK (asserts `count: 0`)
- `test_シンプルテーマでウェルカムにホームとノートのパネルが表示される` — OK (asserts panel exists, not content)
- `test_シンプルテーマでtab_notesクエリのときノートパネルが非表示クラスでホームが隠される` — OK
- `test_シンプルテーマで不正なtabクエリはホームを表示する` — OK
- `test_モダンテーマでuse_noteがfalseのときノートパネルが表示されない` — OK
- `test_モダンテーマでルートではノートパネルが隠れtab_notesで表示される` — OK
- `test_モダンテーマで不正なtabクエリはホームを表示する` — OK
- `test_クラシックテーマでuse_noteがfalseのときノートパネルが表示されない` — OK
- `test_クラシックテーマでルートではノートパネルが隠れtab_notesで表示される` — OK
- `test_クラシックテーマで不正なtabクエリはホームを表示する` — OK

Additionally, two tests should be UPDATED to assert a loading placeholder is present instead of the note-gadget form:
- `test_シンプルテーマでtab_notesクエリのときノートパネルが非表示クラスでホームが隠される` — currently asserts visibility only; add assert that `.note-gadget-loading` is present
- Similar for modern/classic notes-active tests

### New tests to ADD to `notes_controller_test.rb` (or a `notes_controller/gadget_test.rb` file)

Corresponding to the removed dashboard tests — covering the gadget endpoint directly:

- `test_gadget_returns_note_gadget_html` — 200, no `<html>` tag, has `.note-gadget`
- `test_gadget_assigns_new_note` — `@note` is a `Note` with `new_record? == true`
- `test_gadget_assigns_active_notes` — `@notes` equals current user's active notes
- `test_gadget_unauthenticated_redirects` — GET `/notes/gadget` without sign-in → redirect to sign-in
- `test_gadget_empty_notes_state` — when no notes, contains `.note-empty`
- `test_gadget_locale_ja` — Japanese labels
- `test_gadget_locale_en` — English labels
- `test_gadget_does_not_include_other_users_notes` — isolation test

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `notesLoaded` is set synchronously before `$.get` fires (not in `.done()`) | Code Examples — notes_tabs.js | If set in callback, rapid double-click causes two in-flight requests |
| A2 | The inline `<script>` for modern/classic is guarded by `notes_active` (i.e., `use_note && params[:tab] == 'notes'`) | Architecture Patterns — Pattern 3 | If guard is missing, AJAX fires on every page load even when notes tab is not active |
| A3 | `welcome.note_gadget.loading` is the i18n key to add (rather than a generic `welcome.loading`) | Common Pitfalls — Pitfall 2 | Generic key does not exist; adding per-gadget key is the established pattern |

---

## Environment Availability

Step 2.6: SKIPPED — this phase has no external dependencies. All tools (Rails, jQuery, Ruby) are already present and confirmed working (tri-suite green at Phase 78 close).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (`ActionDispatch::IntegrationTest`) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/notes_controller_test.rb` |
| Full suite command | `bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTE-01 | `NotesController#gadget` returns 200 fragment with note gadget markup | integration | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ (extend existing) |
| NOTE-01 | Unauthenticated request to `/notes/gadget` redirects to sign-in | integration | `bin/rails test test/controllers/notes_controller_test.rb` | ✅ (extend existing) |
| NOTE-02 | `WelcomeController#index` does not assign `@note` or `@notes` | integration | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` | ✅ (update existing) |
| NOTE-03 | `#notes-tab-panel` in SSR contains loading placeholder, not `.note-gadget` | integration | `bin/rails test test/controllers/welcome_controller/dashboard_test.rb` | ✅ (update existing) |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/notes_controller_test.rb test/controllers/welcome_controller/dashboard_test.rb`
- **Per wave merge:** `yarn run lint && bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` — all green before phase complete

### Wave 0 Gaps

- [ ] `app/views/notes/` directory and `app/views/notes/gadget.html.erb` — created in first implementation task
- [ ] `config/locales/ja.yml` and `config/locales/en.yml` — need `welcome.note_gadget.loading` key added

*(No test framework gaps — existing Minitest infrastructure covers all requirements)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `before_action :authenticate_user!` inherited from `ApplicationController` — already present |
| V3 Session Management | no | No session changes |
| V4 Access Control | yes | `current_user.notes.active.recent` scoped to current user — same as existing CRUD |
| V5 Input Validation | no | Gadget action is read-only; no params consumed |
| V6 Cryptography | no | No crypto changes |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated access to note data | Information Disclosure | `authenticate_user!` redirects to sign-in; already in `ApplicationController` |
| Cross-user data leakage | Information Disclosure | `current_user.notes.active.recent` — scoped to authenticated user, same pattern as `set_note` private method |

No new attack surface is introduced. The gadget action is a read-only view of data already accessible via the dashboard.

---

## Open Questions

1. **Loading text for `note-gadget-loading` placeholder**
   - What we know: Per-gadget loading keys exist (`welcome.feed.loading`, `welcome.calendar_gadget.loading`, `welcome.x_account.loading`). There is no generic `welcome.loading` key.
   - What's unclear: CONTEXT.md says "with `t('welcome.loading')` text span" — this key does not exist.
   - Recommendation: Add `welcome.note_gadget.loading` to both locale files. Japanese: `ノートを読み込み中・・・`, English: `Loading notes...` — consistent with the existing per-gadget pattern. This is within Claude's Discretion per CONTEXT.md.

2. **Variable name for the load-once flag in notes_tabs.js**
   - What we know: CONTEXT.md says "module-level `var notesLoaded = false`" or similar.
   - What's unclear: The CONTEXT.md offers `_notesLoaded` as an alternative naming.
   - Recommendation: Use `var notesLoaded` (no underscore prefix) — the IIFE scope already provides isolation; the underscore convention is not used elsewhere in `notes_tabs.js`.

---

## Sources

### Primary (HIGH confidence)

- `app/controllers/notes_controller.rb` [VERIFIED: codebase] — existing CRUD actions
- `app/controllers/welcome_controller.rb` [VERIFIED: codebase] — `@note`/`@notes` assignments to remove
- `app/controllers/calendars_controller.rb` [VERIFIED: codebase] — `get_gadget` action pattern
- `app/views/welcome/_note_gadget.html.erb` [VERIFIED: codebase] — partial to be reused unchanged
- `app/views/welcome/_dashboard.html.erb` [VERIFIED: codebase] — two `render 'note_gadget'` calls to replace
- `app/assets/javascripts/notes_tabs.js` [VERIFIED: codebase] — `activateTab` function to extend
- `config/routes.rb` [VERIFIED: codebase] — current `resources :notes, only: [:create, :update, :destroy]`
- `config/locales/ja.yml` [VERIFIED: codebase] — confirmed no `welcome.loading` generic key exists
- `test/controllers/welcome_controller/dashboard_test.rb` [VERIFIED: codebase] — tests that need migration
- `test/controllers/notes_controller_test.rb` [VERIFIED: codebase] — tests to extend
- `app/views/welcome/_x_account.html.erb` [VERIFIED: codebase] — `$.get` + `.fail` pattern
- `app/views/welcome/_calendar_gadget.html.erb` [VERIFIED: codebase] — `portalLazy.register` + `$.get` pattern

### Secondary (MEDIUM confidence)

- CONTEXT.md Phase 79 decisions — derived from project-specific discussion

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all patterns verified in codebase
- Architecture: HIGH — established patterns (`CalendarsController#get_gadget`) directly applicable
- Pitfalls: HIGH — test migration impact verified by reading all affected test files
- Test impact: HIGH — all dashboard_test.rb note tests enumerated; migration plan is concrete

**Research date:** 2026-05-17
**Valid until:** Stable — no external dependencies; valid until codebase changes
