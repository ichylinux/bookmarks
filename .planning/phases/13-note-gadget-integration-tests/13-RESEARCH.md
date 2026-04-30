---
phase: 13
phase_name: Note Gadget + Integration Tests
status: complete
date: 2026-04-30
---

# Phase 13 Research: Note Gadget + Integration Tests

## Summary

Phase 13 should complete the server-rendered simple-theme Note tab by replacing the placeholder in `app/views/welcome/index.html.erb` with a dedicated `app/views/welcome/_note_gadget.html.erb` partial. The existing foundation is already aligned: `app/models/note.rb` has `Note.recent`, `app/controllers/notes_controller.rb` persists notes through full-page `POST /notes`, and `config/routes.rb` exposes create-only notes routing.

The safest implementation is small and conventional:

- `WelcomeController#index` in `app/controllers/welcome_controller.rb` should set `@note = Note.new` and `@notes = current_user.notes.recent`.
- `app/views/welcome/index.html.erb` should render `_note_gadget` inside `#notes-tab-panel` only inside the existing `favorite_theme == 'simple'` branch.
- `_note_gadget.html.erb` should contain a local/full-page Rails form, a reverse-chronological list, a deterministic empty state, and readable timestamps.
- Tests should be split exactly as the Phase 13 context decides: `WelcomeController` controller tests for HTML/data/isolation, and Cucumber for the browser save flow. Do not add `test/integration/` tests.
- Fold the drawer cleanup todos into this phase as a separate layout cleanup task: introduce `drawer_ui?`, use it for non-simple drawer UI, and assert simple pages do not render drawer DOM.

## Implementation Findings

### Welcome Controller Data

`app/controllers/welcome_controller.rb` currently only assigns `@portal`. Phase 13 should extend `index` to prepare the note gadget data:

```ruby
def index
  @portal = current_user.portals.first
  @note = Note.new
  @notes = current_user.notes.recent
end
```

Use `current_user.notes.recent`, not `Note.recent`, `Note.all`, or a global query. This satisfies NOTE-02 ordering and NOTE-03 user isolation with one query shape. Do not introduce pagination or filtering; `REQUIREMENTS.md` explicitly keeps pagination out of scope.

### Partial and Mount Point

`app/views/welcome/index.html.erb` already has the stable simple-only mount point:

- `#simple-home-panel` contains the portal grid.
- `#notes-tab-panel` currently contains placeholder copy.
- Modern/classic themes use the `else` branch and render only the original portal.

Replace the placeholder under `#notes-tab-panel` with:

```erb
<%= render 'note_gadget' %>
```

Keep the surrounding `#notes-tab-panel` id and `simple-tab-panel` classes stable because `app/assets/javascripts/notes_tabs.js`, existing controller tests, and the Cucumber flow should target that DOM contract.

### Form Shape

Use `form_with model: @note, url: notes_path, local: true` in `app/views/welcome/_note_gadget.html.erb`. This gives Rails CSRF handling and preserves the Phase 11 full-page POST contract in `app/controllers/notes_controller.rb`.

Recommended markup contract:

- Wrap the gadget in a scoped container, for example `.note-gadget`.
- Use `f.text_area :body`, preferably with an explicit label for stable Capybara access.
- Use a Save button with stable text. Existing UI has Japanese submit labels such as `保存`, while Phase 12 tab labels are currently English `Home` / `Note`; pick one submit copy and assert it through selectors rather than fragile surrounding text. `保存` fits existing preferences UI in `app/views/preferences/index.html.erb`.
- Avoid client-side JS, autosave, rich text, inline editing, and pagination.

Example shape for the planner to implement:

```erb
<section class="note-gadget">
  <h2>ノート</h2>
  <%= form_with model: @note, url: notes_path, local: true, html: { class: 'note-gadget-form' } do |f| %>
    <%= f.label :body, 'メモ' %>
    <%= f.text_area :body, rows: 4 %>
    <%= f.submit '保存' %>
  <% end %>
  ...
</section>
```

### List, Empty State, and Timestamp

`app/models/note.rb` exposes `scope :recent, -> { order(created_at: :desc) }`, so the view should assume `@notes` is already ordered. Render each note with body text and a readable timestamp.

Recommended list contract:

- If `@notes.empty?`, show exact empty-state copy from `ROADMAP.md`: `メモはまだありません`.
- Otherwise render a list container such as `.note-list` with each note as `.note-item`.
- Render the note body with standard ERB escaping (`<%= note.body %>`), not `raw`.
- Use a deterministic timestamp format, for example `note.created_at.strftime('%Y-%m-%d %H:%M')`. This is readable, stable in controller tests, and avoids locale-dependent full date strings.

Fixtures in `test/fixtures/notes.yml` currently lack `created_at` and `updated_at`. Phase 13 tests that assert ordering or timestamps should either add explicit fixture timestamps or create records inline with fixed timestamps inside the test. Inline records are safest for order assertions because the current fixture file is minimal and already used by `test/models/note_test.rb`.

### CSS Scope

Add note gadget styles only in `app/assets/stylesheets/welcome.css.scss` under the existing `.simple { }` block. Keep selectors class-based and scoped:

- `.simple .note-gadget`
- `.simple .note-gadget-form`
- `.simple .note-list`
- `.simple .note-item`
- `.simple .note-timestamp`
- `.simple .note-empty`

Do not add note styles to `common.css.scss` or theme-independent selectors. This preserves the v1.3 theme isolation rule from `.planning/STATE.md`.

## Test Strategy

Follow the user decisions in `.planning/phases/13-note-gadget-integration-tests/13-CONTEXT.md`: controller tests for Rails-side structure/data/isolation, Cucumber for the full browser save flow, and no new `test/integration/` files.

### WelcomeController Controller Tests

Extend `test/controllers/welcome_controller/welcome_controller_test.rb`.

Required coverage:

- Simple theme renders the real note gadget inside `#notes-tab-panel`.
- The gadget includes one note form posting to `notes_path`, a textarea for `note[body]`, and a Save button.
- When the current user has no notes, the empty-state text `メモはまだありません` appears.
- Current user's notes render in reverse chronological order.
- Another user's notes do not render.

Recommended tactics:

- Set `user.preference.update!(theme: 'simple')` before sign-in, matching existing tests.
- Use inline `Note.create!` records for ordering/isolation rather than relying on current `notes.yml` timestamps.
- Delete or isolate current user's existing fixture notes in empty-state tests, for example `user.notes.delete_all`, so the current `notes(:one)` fixture does not make the empty state nondeterministic.
- Assert order by comparing the positions of body strings in `response.body`, or by selecting `.note-item` nodes and comparing text order if `assert_select` returns a reliable sequence.
- Keep non-simple tab absence assertions in `test/controllers/welcome_controller/layout_structure_test.rb`.

Suggested controller assertions:

- `assert_select '#notes-tab-panel .note-gadget', count: 1`
- `assert_select 'form.note-gadget-form[action=?][method=?]', notes_path, 'post'`
- `assert_select 'textarea[name=?]', 'note[body]', count: 1`
- `assert_select 'input[type=submit][value=?]', '保存', count: 1`
- `assert_select '.note-empty', text: 'メモはまだありません'`
- `assert_includes response.body, newer_note.body`
- `assert_not_includes response.body, other_user_note.body`

### NotesController Tests

`test/controllers/notes_controller_test.rb` already covers create success, blank body failure, auth guard, `user_id` override rejection, max-length failure, and create-only routing. Phase 13 should not duplicate these assertions except as regression coverage in the test run.

The Cucumber save-flow scenario should prove the full request cycle; `NotesController` unit-style behavior should remain in `notes_controller_test.rb`.

### Cucumber Save Flow

Add a Cucumber feature under `features/`, likely `features/04.ノート.feature`, with Japanese Gherkin matching existing feature style.

Required browser flow:

1. Sign in as the fixture user.
2. Set the user's preference theme to `simple` in the step definition before visiting root.
3. Visit `root_path`.
4. Click the Note tab button.
5. Fill `note[body]` or the label-backed textarea with a unique note body.
6. Click Save.
7. Assert the browser returned to `root_path` with `tab=notes` in the query.
8. Assert `#notes-tab-panel` is visible and contains the new note near the top of the list.

Add step definitions under `features/step_definitions/notes.rb`. Follow existing patterns in `features/step_definitions/todos.rb` and `features/step_definitions/modern_theme.rb`: call `sign_in user`, use Capybara `visit`, `click_on`, `fill_in`, `within`, `has_selector?`, and `capture` / `with_capture` only where useful.

Selector recommendations:

- Click `button.simple-tab[data-simple-tab="notes"]` rather than relying only on visible tab text, because existing Phase 12 implementation uses English `Note` despite some older planning docs referencing Japanese labels.
- Fill `textarea[name="note[body]"]` or the label-backed field.
- Scope assertions with `within '#notes-tab-panel'` to avoid matching text elsewhere.
- Check ordering with `.note-item:first-child` containing the saved body if the implementation uses list items.

Do not add `test/integration/` tests. `test/integration/` is intentionally empty and the user explicitly rejected that path for Phase 13.

## Drawer Cleanup Findings

Two pending UI todos are explicitly folded into Phase 13:

- `.planning/todos/pending/2026-04-30-extract-drawer-ui-helper.md`
- `.planning/todos/pending/2026-04-30-gate-drawer-blocks-on-theme.md`

Current state in `app/views/layouts/application.html.erb`:

- Header user email and hamburger are gated by `user_signed_in? && favorite_theme != 'simple'`.
- Simple top menu render is gated by `user_signed_in? && favorite_theme == 'simple'`.
- `.drawer` and `.drawer-overlay` are gated only by `user_signed_in?`, so simple-theme pages still render hidden drawer DOM.

Recommended implementation:

- Add `drawer_ui?` to `app/helpers/welcome_helper.rb` or `app/helpers/application_helper.rb`.
- Prefer `ApplicationHelper` if treating it as layout-wide UI state. `favorite_theme` currently lives in `WelcomeHelper`, but Rails exposes helpers broadly in views in this app; the planner should verify helper availability. If in doubt, move neither method and add `drawer_ui?` next to `favorite_theme` in `WelcomeHelper` to minimize churn.
- Define it as:

```ruby
def drawer_ui?
  user_signed_in? && favorite_theme != 'simple'
end
```

- Replace the header hamburger condition with `drawer_ui?`.
- Replace the drawer block condition with `drawer_ui?`.
- Keep the simple menu condition as `user_signed_in? && favorite_theme == 'simple'` or make it explicit with a separate helper only if the planner wants symmetry. Do not use `!drawer_ui?` alone for the simple menu, because unauthenticated pages would then satisfy the inverse.

Update or add layout tests in `test/controllers/welcome_controller/layout_structure_test.rb`:

- Modern theme still renders `button.hamburger-btn`, `.drawer`, and `.drawer-overlay`.
- Classic theme still renders drawer UI if `favorite_theme != 'simple'`.
- Simple theme does not render `button.hamburger-btn`, `.drawer`, or `.drawer-overlay`.
- Simple theme still renders the normal simple menu via `common/menu`.
- Existing tests that assert `body > div.drawer` should set theme to `modern` or `classic` explicitly so they do not depend on fixture/default preference behavior.

This drawer cleanup is independent of note gadget behavior and should be a separate plan task or separate plan file to keep regressions easy to isolate.

## Risks and Pitfalls

- User isolation: never query notes globally. Use `current_user.notes.recent` in `app/controllers/welcome_controller.rb` and test that `User.find(2)` notes are absent.
- Reverse chronological ordering: `Note.recent` orders only by `created_at DESC`. If two records share the same timestamp, order can be nondeterministic. Tests should use distinct fixed timestamps.
- Fixture determinism: `test/fixtures/notes.yml` currently has no timestamps. Ordering and timestamp tests need explicit inline records or fixture timestamp updates.
- Empty state: existing fixture `notes(:one)` belongs to user 1, so an empty-state test for `user` must remove or avoid that record.
- Full-page POST redirect: `app/controllers/notes_controller.rb` already redirects to `root_path(tab: 'notes')`; Cucumber must assert the redirected page lands on the Note tab and shows the new note.
- Simple-theme-only rendering: note gadget markup should exist only in the simple branch of `app/views/welcome/index.html.erb`; modern/classic should still have no `#notes-tab-panel`.
- CSS leakage: all note gadget CSS belongs under `.simple { }` in `app/assets/stylesheets/welcome.css.scss`.
- Cucumber selectors: avoid brittle text-only tab selectors because the implementation currently uses English `Home` / `Note` labels while some planning docs mention Japanese labels. Prefer `data-simple-tab`.
- Flash/validation failures: Phase 13 does not need to change `NotesController#create`; blank/long body failures already redirect back to `tab: 'notes'` with alert coverage in `test/controllers/notes_controller_test.rb`.
- Drawer helper placement: `drawer_ui?` is layout-wide, but `favorite_theme` is currently in `app/helpers/welcome_helper.rb`. Place the helper where it is actually available to `app/views/layouts/application.html.erb` and avoid moving existing helpers unless tests show availability problems.

## Recommended Plan Breakdown

### Plan 13-01: Server-Rendered Note Gadget

Files:

- `app/controllers/welcome_controller.rb`
- `app/views/welcome/index.html.erb`
- `app/views/welcome/_note_gadget.html.erb`
- `app/assets/stylesheets/welcome.css.scss`

Actions:

- Add `@note` and `@notes = current_user.notes.recent` in `WelcomeController#index`.
- Replace the Note tab placeholder with `render 'note_gadget'`.
- Build `_note_gadget.html.erb` with textarea, Save button, list, empty state, body, and timestamp.
- Add simple-scoped CSS only.

Verification:

- `bin/rails test test/controllers/notes_controller_test.rb`
- Manual browser smoke if desired: simple theme root, Note tab, form visible.

### Plan 13-02: WelcomeController Note Gadget Tests

Files:

- `test/controllers/welcome_controller/welcome_controller_test.rb`
- optionally `test/fixtures/notes.yml` if choosing explicit fixture timestamps over inline records

Actions:

- Add structure tests for the form, textarea, Save button, list container, and empty state.
- Add data tests for reverse chronological rendering.
- Add isolation test proving another user's notes are not displayed.
- Keep tests under the existing welcome controller test namespace and style.

Verification:

- `bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb`
- `bin/rails test test/controllers/notes_controller_test.rb`

### Plan 13-03: Cucumber Full Save Flow

Files:

- `features/04.ノート.feature`
- `features/step_definitions/notes.rb`

Actions:

- Add one browser scenario for the full note capture cycle.
- Sign in, set simple theme, open root, switch to Note tab, enter unique text, save, assert `tab=notes`, assert note visible in `#notes-tab-panel`.
- Scope selectors to the Note panel and use `data-simple-tab` for tab activation.

Verification:

- `cucumber features/04.ノート.feature`

### Plan 13-04: Drawer Helper and Theme Gate Cleanup

Files:

- `app/helpers/application_helper.rb` or `app/helpers/welcome_helper.rb`
- `app/views/layouts/application.html.erb`
- `test/controllers/welcome_controller/layout_structure_test.rb`

Actions:

- Add `drawer_ui?`.
- Gate hamburger and drawer DOM with `drawer_ui?`.
- Keep simple menu rendering authenticated and simple-theme-only.
- Update/add layout tests for modern/classic drawer presence and simple drawer absence.

Verification:

- `bin/rails test test/controllers/welcome_controller/layout_structure_test.rb`

### Phase Gate

Run:

```bash
bin/rails test test/controllers/welcome_controller/ test/controllers/notes_controller_test.rb
cucumber features/04.ノート.feature
```

If time allows before marking the milestone complete, run `bin/rails test` and the full `cucumber` suite because this phase touches layout markup and feature-level browser paths.

## Validation Architecture

Use a three-layer validation shape:

1. Model/controller foundation already covered by earlier phases: `test/models/note_test.rb` verifies ownership predicates and `Note.recent`; `test/controllers/notes_controller_test.rb` verifies POST create, redirect, invalid payloads, auth, and parameter ownership.
2. Welcome rendering contract in Minitest: `test/controllers/welcome_controller/welcome_controller_test.rb` should verify the server-rendered DOM, current-user data projection, ordering, empty state, and isolation. `test/controllers/welcome_controller/layout_structure_test.rb` should verify theme/layout boundaries and drawer cleanup.
3. Browser request cycle in Cucumber: one end-to-end feature should prove the user-visible happy path from simple-theme Note tab through full-page save redirect back to the Note tab with the new note visible.

This split keeps fast deterministic checks in Minitest and reserves Cucumber for the behavior that only a browser flow can prove: tab interaction plus the complete POST/redirect/render cycle.
