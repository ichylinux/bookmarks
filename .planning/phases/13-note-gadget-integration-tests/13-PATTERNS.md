# Phase 13 Pattern Map: Note Gadget + Integration Tests

## Scope Summary

Phase 13 turns the simple-theme Note tab from placeholder markup into the real note gadget. The implementation should stay server-rendered, submit through the existing `POST /notes` route, return to `root_path(tab: 'notes')`, and render only the current user's notes in reverse chronological order.

This phase also folds in the drawer cleanup todos: extract a `drawer_ui?` helper and gate the hamburger, drawer, and overlay so simple-theme pages do not render hidden drawer DOM.

Do not add Rails integration tests. Keep Rails-side rendering/data checks in `WelcomeController` controller tests and put the browser save flow in Cucumber.

## Planned Files and Roles

### Note Gadget Implementation

- `app/controllers/welcome_controller.rb`
  - Add note view data in `index`.
  - Expected shape: `@note = Note.new` and `@notes = current_user.notes.recent`.
  - Always query through `current_user`, never `Note.recent` globally.

- `app/views/welcome/index.html.erb`
  - Keep the existing simple-theme branch and `#notes-tab-panel`.
  - Replace only the placeholder contents inside `#notes-tab-panel` with `render 'note_gadget'`.
  - Do not rename `#notes-tab-panel`, `.simple-tab-panel`, or `data-simple-tab` hooks.

- `app/views/welcome/_note_gadget.html.erb`
  - New dedicated partial for the gadget.
  - Top-level element must be `<section class="note-gadget">`.
  - Contains, in order: `h2` exact text `ノート`, form `.note-gadget-form`, then either `.note-empty` or `.note-list`.
  - Form posts locally/full-page to `notes_path` using `@note`.
  - List renders `.note-item`, `.note-body`, and `.note-timestamp`.

- `app/assets/stylesheets/welcome.css.scss`
  - Add note gadget styles under the existing `.simple { }` scope only.
  - Required selectors: `.note-gadget`, `.note-gadget-form`, `.note-empty`, `.note-list`, `.note-item`, `.note-body`, `.note-timestamp`.
  - Preserve user-entered line breaks with `white-space: pre-wrap` on `.note-body`.

### Drawer Cleanup

- `app/helpers/welcome_helper.rb` or `app/helpers/application_helper.rb`
  - Add `drawer_ui?`.
  - Contract: signed-in users whose `favorite_theme` is not `simple`.
  - Minimize churn by placing it where layout rendering can call it. `favorite_theme` currently lives in `WelcomeHelper`.

- `app/views/layouts/application.html.erb`
  - Replace duplicated drawer eligibility checks with `drawer_ui?`.
  - Gate the hamburger button, `.drawer`, and `.drawer-overlay` with `drawer_ui?`.
  - Keep the simple menu condition explicit: `user_signed_in? && favorite_theme == 'simple'`.

### Tests

- `test/controllers/welcome_controller/welcome_controller_test.rb`
  - Extend existing simple-tab tests with note gadget structure, empty state, reverse chronological rendering, timestamp rendering, and current-user isolation.

- `test/controllers/welcome_controller/layout_structure_test.rb`
  - Extend drawer tests for modern/classic drawer presence and simple drawer absence.
  - Make existing drawer DOM tests set a non-simple theme explicitly.

- `test/controllers/notes_controller_test.rb`
  - Existing coverage already owns `POST /notes` behavior. Do not duplicate controller create semantics here unless needed for regressions.

- `features/04.ノート.feature`
  - New Japanese Cucumber feature for the browser-visible save flow.

- `features/step_definitions/notes.rb`
  - New step definitions that sign in, set simple theme, visit root, activate the Note tab, fill the textarea, save, and assert the redirected Note tab contains the new note.

## Closest Analogs

### `WelcomeController#index`

Current shape is intentionally small:

```ruby
def index
  @portal = current_user.portals.first
end
```

Copy this direct instance-variable setup style. Add only note gadget data:

```ruby
@note = Note.new
@notes = current_user.notes.recent
```

### `NotesController#create`

The note save contract already exists:

```ruby
if @note.save
  redirect_to root_path(tab: 'notes')
else
  redirect_to root_path(tab: 'notes'), alert: @note.errors.full_messages.to_sentence.presence || 'エラーが発生しました'
end
```

Do not introduce AJAX, Turbo, or a new redirect path. The gadget form should submit to this action and rely on the existing redirect back to the Note tab.

### `welcome/index.html.erb`

The simple branch already defines the required mount point:

```erb
<div id="notes-tab-panel" class="simple-tab-panel<%= ' simple-tab-panel--hidden' unless notes_active %>" role="tabpanel">
  <h2>ノート</h2>
  <p>ここにメモの一覧と入力欄が表示されます。</p>
</div>
```

Replace the placeholder heading/paragraph with the partial render. Keep the panel id, class, and `notes_active` behavior exactly.

### `_todo_gadget.html.erb`

The portal gadget analog renders a small partial with a stable wrapper and nested gadget content:

```erb
<div id="<%= gadget.gadget_id %>" class="gadget todo">
  ...
  <div class="title"><%= gadget.title %></div>
  <ol>
    <%= render 'todos/actions' %>
    <% gadget.entries.each do |todo| %>
      <%= render todo %>
    <% end %>
  </ol>
</div>
```

The note gadget is not a draggable portal gadget, but should copy the same idea: a dedicated partial owns the feature-specific markup and keeps `welcome/index` as the mounting shell.

### `todos/_form.html.erb`

Existing forms use Rails helpers and simple submit controls:

```erb
<%= form_with model: @todo, html: {class: 'todo'} do |f| %>
  ...
  <%= f.submit '登録', onclick: 'todos.create_todo(this); return false;' %>
<% end %>
```

For notes, use the same Rails helper family but no JavaScript interception:

```erb
form_with model: @note, url: notes_path, local: true, html: { class: 'note-gadget-form' }
```

Required copy from the UI spec: label `メモ`, submit `保存`.

### `application.html.erb`

Current layout duplicates the theme gate and leaves drawer DOM signed-in-only:

```erb
<% if user_signed_in? && favorite_theme != 'simple' %>
  ...
  <button class="hamburger-btn" aria-label="メニュー"></button>
<% end %>
...
<% if user_signed_in? %>
  <div class="drawer">
  ...
  <div class="drawer-overlay"></div>
<% end %>
```

Phase 13 should centralize the non-simple signed-in condition:

```ruby
def drawer_ui?
  user_signed_in? && favorite_theme != 'simple'
end
```

Then use `drawer_ui?` for the hamburger and drawer DOM.

### `welcome_helper.rb`

Current helper pattern is direct and defensive:

```ruby
def favorite_theme
  return 'modern' unless user_signed_in?
  return 'modern' unless current_user.preference.present?
  return current_user.preference.theme.presence || 'modern'
end
```

Copy the small predicate style for `drawer_ui?`. Do not use `!drawer_ui?` as the simple menu condition because unauthenticated users would satisfy the inverse.

### `welcome.css.scss`

Simple-tab styles are scoped under `.simple`:

```scss
.simple {
  .simple-tabstrip { ... }
  .simple-tab { ... }
  .simple-tab-panel--hidden {
    display: none;
  }
  #notes-tab-panel {
    h2 { ... }
    p { ... }
  }
}
```

Add note gadget selectors inside this same `.simple` block. Avoid global selectors and avoid adding note UI styles to other stylesheets.

### Welcome Controller Tests

Current tests are `ActionDispatch::IntegrationTest` with Devise sign-in and `assert_select`:

```ruby
user.preference.update!(theme: 'simple')
sign_in user
get root_path(tab: 'notes')
assert_response :success
assert_select '#simple-home-panel.simple-tab-panel--hidden', count: 1
assert_select '#notes-tab-panel.simple-tab-panel--hidden', count: 0
```

Copy this setup style. Add assertions for:

- `#notes-tab-panel .note-gadget`
- `.note-gadget h2`, text `ノート`
- `form.note-gadget-form[action=?][method=?]`, `notes_path`, `post`
- `textarea[name=?]`, `note[body]`
- `input[type=submit][value=?]`, `保存`
- `.note-empty`, text `メモはまだありません`
- `.note-list .note-item`
- `.note-body`
- `.note-timestamp`

### Layout Structure Tests

Current drawer tests assert hamburger/drawer presence by selector:

```ruby
user.preference.update!(theme: 'modern')
sign_in user
get root_path
assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
assert_select 'div.drawer', count: 1
assert_select 'div.drawer-overlay', count: 1
```

Extend this file, not a new integration test folder. Add simple-theme absence assertions:

- `assert_select 'button.hamburger-btn', count: 0`
- `assert_select 'div.drawer', count: 0`
- `assert_select 'div.drawer-overlay', count: 0`
- Assert the simple authenticated menu still renders if there is a stable selector in `common/menu`.

### `notes_controller_test.rb`

This file already covers create behavior:

- successful create increments `Note.count`
- redirects to `root_path(tab: 'notes')`
- body belongs to signed-in user
- blank/too-long bodies do not create
- unauthenticated POST redirects
- `user_id` param cannot override current user
- only `POST /notes` is routed

Treat it as the lower-level contract. Phase 13 should rely on it and add Welcome/Cucumber coverage for rendering and browser flow.

### Cucumber Feature and Steps

Existing feature style uses Japanese Gherkin and `*` steps:

```gherkin
# language: ja

機能: タスク

  シナリオ: タスクウィジェットを使用する
    * 設定画面で タスクウィジェットを表示する にチェックを入れます。
    * ポータルに Todo というウィジェットが表示されます。
```

Existing step definitions use direct Capybara and Minitest assertions:

```ruby
sign_in user
visit '/preferences'
click_on '保存'
assert has_selector?('#todo .title', text: name)
within 'form.todo' do
  fill_in 'todo[title]', with: '新しいタスクの内容'
end
```

For note steps, copy this style:

- Set `user.preference.update!(theme: 'simple')`.
- `sign_in user`.
- `visit root_path`.
- Activate with `find('button.simple-tab[data-simple-tab="notes"]').click`.
- Fill by label `メモ` or selector `textarea[name="note[body]"]`.
- Click `保存`.
- Assert `current_path == root_path` and query includes `tab=notes` or assert via `URI.parse(current_url).query`.
- Use `within '#notes-tab-panel'` and assert `.note-item:first-child .note-body` contains the saved text.

## Established Patterns to Copy Exactly

- Keep simple-theme tab markup exclusive to `favorite_theme == 'simple'`.
- Keep modern/classic out of the note gadget path; they should not render `#notes-tab-panel`.
- Use `params[:tab].to_s == 'notes'` to decide the initial active tab.
- Preserve `button.simple-tab[data-simple-tab="home"]` and `button.simple-tab[data-simple-tab="notes"]`.
- Preserve `#simple-home-panel`, `#notes-tab-panel`, and `.simple-tab-panel--hidden`.
- Use Rails form helpers and a full-page POST for note creation.
- Use `notes_path` and the existing `NotesController#create` redirect to `root_path(tab: 'notes')`.
- Render note bodies with escaped ERB output, not `raw`.
- Format timestamps deterministically with `created_at.strftime('%Y-%m-%d %H:%M')`.
- Put note styles under `.simple { }` in `welcome.css.scss`.
- Use `assert_select` for controller-rendered HTML structure.
- Use Cucumber only for the browser save flow.
- Use helper predicates for layout gates once a condition appears in multiple places.

## Required Data Flow

1. Signed-in user requests `GET /` or `GET /?tab=notes`.
2. `WelcomeController#index` loads:
   - `@portal = current_user.portals.first`
   - `@note = Note.new`
   - `@notes = current_user.notes.recent`
3. `app/views/welcome/index.html.erb` checks `favorite_theme`.
4. For the simple theme:
   - It computes `notes_active = (params[:tab].to_s == 'notes')`.
   - It renders tab buttons and both panels.
   - `#notes-tab-panel` renders `_note_gadget`.
5. `_note_gadget` renders:
   - `form_with model: @note, url: notes_path, local: true`
   - `textarea[name="note[body]"]`
   - submit `保存`
   - empty state if `@notes.empty?`, otherwise `@notes` as newest-first items.
6. User submits the form.
7. `NotesController#create` builds `Note.new(note_params)`.
8. `note_params` permits only `:body` and merges `user_id: current_user.id`.
9. On success, controller redirects to `root_path(tab: 'notes')`.
10. The welcome page re-renders with `notes_active == true`, making `#notes-tab-panel` visible and showing the newly saved note at the top via `current_user.notes.recent`.

## Testing Patterns

### Minitest Controller Rendering Tests

Use `WelcomeController::WelcomeControllerTest` for note gadget checks:

- Setup simple theme before sign-in: `user.preference.update!(theme: 'simple')`.
- Sign in with `sign_in user`.
- Use `get root_path` or `get root_path(tab: 'notes')`.
- Assert HTML with `assert_select`.
- For empty state, remove current user's fixture notes first, because `notes.yml` has `one` assigned to `user_id: 1`.
- For ordering, create inline notes with distinct fixed timestamps.
- For isolation, create an inline note for `User.find(2)` and assert it is absent from `response.body` or `#notes-tab-panel`.

Suggested order test tactic:

```ruby
older = user.notes.create!(body: '古いメモ', created_at: Time.zone.local(2026, 4, 29, 9, 0), updated_at: Time.zone.local(2026, 4, 29, 9, 0))
newer = user.notes.create!(body: '新しいメモ', created_at: Time.zone.local(2026, 4, 30, 9, 0), updated_at: Time.zone.local(2026, 4, 30, 9, 0))
get root_path(tab: 'notes')
assert response.body.index(newer.body) < response.body.index(older.body)
```

Also assert timestamp strings:

```ruby
assert_includes response.body, newer.created_at.strftime('%Y-%m-%d %H:%M')
```

### Minitest Drawer/Layout Tests

Use `WelcomeController::LayoutStructureTest` for drawer cleanup:

- Modern signed-in page renders hamburger, drawer, and overlay.
- Classic signed-in page renders hamburger, drawer, and overlay.
- Simple signed-in page renders no hamburger, no drawer, no overlay.
- Simple signed-in page still renders the authenticated simple menu.
- Existing tests that assert drawer structure should set `theme: 'modern'` to avoid accidental dependency on fixture defaults.

### Cucumber Browser Save Flow

Add one focused feature, likely `features/04.ノート.feature`.

Scenario shape:

```gherkin
# language: ja

機能: ノート

  シナリオ: シンプルテーマのノートタブからメモを保存する
    * シンプルテーマでサインインします。
    * ルートページでノートタブを開きます。
    * メモに 新しいノート本文 と入力して保存します。
    * ノートタブに 新しいノート本文 が表示されます。
```

Step definition style should follow `todos.rb` and `modern_theme.rb`:

- Use `sign_in user`.
- Use Capybara `visit`, `find`, `fill_in`, `click_on`, `within`.
- Use `assert has_selector?`.
- Use `capture` or `with_capture` only where useful for existing visual trace style.

Prefer stable selectors:

- `button.simple-tab[data-simple-tab="notes"]`
- `textarea[name="note[body]"]`
- `#notes-tab-panel`
- `.note-item:first-child .note-body`

## Drawer Helper and Gate Patterns

Implement one predicate:

```ruby
def drawer_ui?
  user_signed_in? && favorite_theme != 'simple'
end
```

Use it for:

- Header user email and hamburger area if keeping those coupled to drawer UI.
- `.drawer`.
- `.drawer-overlay`.

Do not use it for:

- Simple authenticated menu by inversion. Keep `user_signed_in? && favorite_theme == 'simple'`.
- Unauthenticated layout behavior.

Expected rendering contract after cleanup:

- Modern signed-in: hamburger exists, drawer exists, overlay exists.
- Classic signed-in: hamburger exists, drawer exists, overlay exists.
- Simple signed-in: simple menu exists, hamburger absent, drawer absent, overlay absent.
- Signed-out: existing Devise redirect behavior remains unchanged for root.

## Executor Risks

- User isolation risk: querying `Note.recent` globally will leak other users' notes. Always use `current_user.notes.recent`.
- Ordering risk: records with equal `created_at` can order nondeterministically. Tests must create distinct timestamps.
- Fixture risk: `test/fixtures/notes.yml` already gives user 1 a note, so empty-state tests need cleanup or a user with no notes.
- Timestamp risk: locale-dependent helpers can make tests brittle. Use `%Y-%m-%d %H:%M`.
- HTML escaping risk: note bodies are user input. Render with `<%= note.body %>` and CSS `white-space: pre-wrap`; do not use `raw` or `html_safe`.
- Redirect risk: changing `NotesController#create` is unnecessary and can break existing tests. Preserve `root_path(tab: 'notes')`.
- Theme isolation risk: note gadget markup must not render for modern/classic. Existing layout tests already assert no `#notes-tab-panel` for those themes.
- CSS leakage risk: note styles outside `.simple { }` violate the UI spec and may affect portal gadgets.
- Selector brittleness risk: tab visible labels are English `Home` / `Note`, while note copy is Japanese. Cucumber should use `data-simple-tab` for tab activation.
- Drawer regression risk: replacing signed-in drawer gates with `drawer_ui?` must not hide modern/classic drawer links.
- Helper placement risk: `drawer_ui?` must be callable from `application.html.erb`. If adding it to `WelcomeHelper` fails in layout context, move or duplicate appropriately in `ApplicationHelper` rather than changing layout behavior.
- Test location risk: do not add `test/integration/`; the phase decision explicitly keeps Rails-side checks in controller tests.

## Recommended Verification Commands

Run focused checks first:

```bash
bin/rails test test/controllers/welcome_controller/welcome_controller_test.rb
bin/rails test test/controllers/welcome_controller/layout_structure_test.rb
bin/rails test test/controllers/notes_controller_test.rb
cucumber features/04.ノート.feature
```

Then, if time allows before closing the phase:

```bash
bin/rails test
cucumber
```
