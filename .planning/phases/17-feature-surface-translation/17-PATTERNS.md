# Phase 17: Feature Surface Translation - Pattern Map

**Mapped:** 2026-05-01  
**Files analyzed:** 39  
**Analogs found:** 39 / 39  
**Scope:** Rails server-rendered ERB + SCSS + Sprockets/jQuery feature surface translation

## Source File List Extracted

Phase 17 modifies existing feature surfaces only. No new app architecture files are required.

### Locale and Model Primitives

- `config/locales/ja.yml`
- `config/locales/en.yml`
- `app/models/bookmark_gadget.rb`
- `app/models/todo_gadget.rb`
- `app/models/todo.rb`
- `app/models/calendar.rb`

### Feature Views and JavaScript

- `app/views/bookmarks/index.html.erb`
- `app/views/bookmarks/_form.html.erb`
- `app/views/bookmarks/show.html.erb`
- `app/views/bookmarks/edit.html.erb`
- `app/views/welcome/_bookmark_gadget.html.erb`
- `app/views/welcome/_note_gadget.html.erb`
- `app/views/welcome/_todo_gadget.html.erb`
- `app/views/welcome/_feed.html.erb`
- `app/views/welcome/_calendar.html.erb`
- `app/views/todos/_actions.html.erb`
- `app/views/todos/_form.html.erb`
- `app/views/todos/_todo.html.erb`
- `app/views/todos/index.html.erb`
- `app/views/preferences/index.html.erb`
- `app/views/feeds/index.html.erb`
- `app/views/feeds/_form.html.erb`
- `app/views/feeds/show.html.erb`
- `app/assets/javascripts/feeds.js`
- `app/views/calendars/get_gadget.html.erb`
- `app/views/calendars/_form.html.erb`
- `app/views/calendars/show.html.erb`
- `app/views/calendars/edit.html.erb`

### Relevant Tests and Cucumber Surfaces

- `test/i18n/locales_parity_test.rb`
- `test/controllers/application_controller_test.rb`
- `test/controllers/preferences_controller_test.rb`
- `test/controllers/bookmarks_controller_test.rb`
- `test/controllers/welcome_controller/welcome_controller_test.rb`
- `test/controllers/todos_controller_test.rb`
- `test/controllers/feeds_controller_test.rb`
- `test/controllers/calendars_controller_test.rb`
- `features/01.ブックマーク.feature`
- `features/02.タスク.feature`
- `features/04.ノート.feature`
- `features/step_definitions/bookmarks.rb`
- `features/step_definitions/todos.rb`
- `features/step_definitions/notes.rb`

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `config/locales/ja.yml` | config | transform | `config/locales/en.yml`, `test/i18n/locales_parity_test.rb` | exact |
| `config/locales/en.yml` | config | transform | `config/locales/ja.yml`, `test/i18n/locales_parity_test.rb` | exact |
| `app/models/bookmark_gadget.rb` | model / gadget | request-response transform | `app/controllers/preferences_controller.rb` for runtime `t(...)`; same file for gadget protocol | role-match |
| `app/models/todo_gadget.rb` | model / gadget | request-response transform | `app/controllers/preferences_controller.rb` for runtime `t(...)`; same file for gadget protocol | role-match |
| `app/models/todo.rb` | model | transform | `app/models/preference.rb` constants + `app/views/preferences/index.html.erb` runtime option translation | role-match |
| `app/models/calendar.rb` | model | transform | `app/controllers/concerns/localization.rb`; current `Calendar#day_of_week` structure | role-match |
| `app/views/bookmarks/index.html.erb` | view | request-response | `app/views/layouts/application.html.erb`, same file current table/breadcrumb structure | exact |
| `app/views/bookmarks/_form.html.erb` | view / form partial | request-response | `app/views/preferences/index.html.erb`, same file current `form_for` structure | exact |
| `app/views/bookmarks/show.html.erb` | view | request-response | `app/views/calendars/show.html.erb`, same file current details table | exact |
| `app/views/bookmarks/edit.html.erb` | view | request-response | `app/views/calendars/edit.html.erb`, same file current action/render pattern | exact |
| `app/views/welcome/_bookmark_gadget.html.erb` | view / gadget partial | request-response | same file current user-content rendering + `app/models/bookmark_gadget.rb` title | exact |
| `app/views/welcome/_note_gadget.html.erb` | view / gadget partial | request-response | `app/views/preferences/index.html.erb` form translation; same file for note content boundary | role-match |
| `app/views/welcome/_todo_gadget.html.erb` | view / gadget partial | request-response + event-driven init | same file current gadget title/init + `app/views/todos/_actions.html.erb` | exact |
| `app/views/welcome/_feed.html.erb` | view / gadget partial | request-response + event-driven AJAX | `app/views/feeds/_form.html.erb` data attribute pattern + same file inline script | role-match |
| `app/views/welcome/_calendar.html.erb` | view / gadget partial | request-response + event-driven AJAX | same file inline script + `app/views/calendars/get_gadget.html.erb` | exact |
| `app/views/todos/_actions.html.erb` | view / partial | event-driven request-response | same file current link/AJAX hook pattern | exact |
| `app/views/todos/_form.html.erb` | view / form partial | event-driven request-response | `app/views/preferences/index.html.erb` select option i18n + same file AJAX submit hooks | exact |
| `app/views/todos/_todo.html.erb` | view / partial | request-response transform | same file current `priority_name` and user title boundary | exact |
| `app/views/todos/index.html.erb` | view | request-response | `app/views/bookmarks/index.html.erb` table/action pattern | exact |
| `app/views/preferences/index.html.erb` | view / form | request-response | same file existing lazy lookup select pattern | exact |
| `app/views/feeds/index.html.erb` | view | request-response | `app/views/bookmarks/index.html.erb` table/action/confirm pattern | exact |
| `app/views/feeds/_form.html.erb` | view / form partial | request-response + event-driven data handoff | same file current `data-url` button pattern | exact |
| `app/views/feeds/show.html.erb` | view | request-response | same file current external feed content boundary | exact |
| `app/assets/javascripts/feeds.js` | javascript | event-driven AJAX | same file namespace pattern + `app/assets/javascripts/todos.js` data reads | exact |
| `app/views/calendars/get_gadget.html.erb` | view / partial | request-response + event-driven AJAX | same file current month/grid structure + Rails locale runtime from `Localization` | role-match |
| `app/views/calendars/_form.html.erb` | view / form partial | request-response | `app/views/feeds/_form.html.erb`, same file current form pattern | exact |
| `app/views/calendars/show.html.erb` | view | request-response | `app/views/bookmarks/show.html.erb`, same file confirm pattern | exact |
| `app/views/calendars/edit.html.erb` | view | request-response | `app/views/bookmarks/edit.html.erb`, same file action/render pattern | exact |
| `test/i18n/locales_parity_test.rb` | test | batch transform | same file current key parity test | exact |
| `test/controllers/application_controller_test.rb` | test | request-response | same file saved-locale integration pattern | exact |
| `test/controllers/preferences_controller_test.rb` | test | request-response | same file ja/en UI assertions | exact |
| `test/controllers/bookmarks_controller_test.rb` | test | request-response | same file breadcrumb assertions + `application_controller_test` locale setup | exact |
| `test/controllers/welcome_controller/welcome_controller_test.rb` | test | request-response | same file note gadget assertions + `application_controller_test` locale setup | exact |
| `test/controllers/todos_controller_test.rb` | test | request-response + XHR | same file authorization/XHR pattern + `preferences_controller_test` option assertions | role-match |
| `test/controllers/feeds_controller_test.rb` | test | request-response | same file CRUD path assertions + `preferences_controller_test` locale setup | role-match |
| `test/controllers/calendars_controller_test.rb` | test | request-response | same file `get_gadget` request pattern + `application_controller_test` locale setup | exact |
| `features/step_definitions/bookmarks.rb` | test / cucumber | browser event-driven | same file current label dependencies | exact |
| `features/step_definitions/todos.rb` | test / cucumber | browser event-driven | same file current label dependencies | exact |
| `features/step_definitions/notes.rb` | test / cucumber | browser event-driven | same file current label dependencies | exact |

## Pattern Assignments

### Locale Catalogs: `config/locales/ja.yml` and `config/locales/en.yml` (config, transform)

**Analog:** existing locale catalog symmetry and parity test.

**Current namespace pattern**  
Source: `config/locales/ja.yml` lines 27-75 and `config/locales/en.yml` lines 27-75.

```yaml
messages:
  confirm_delete: '%{name} を削除します。よろしいですか？'

preferences:
  saved: 設定を保存しました。
  index:
    theme_options:
      modern: モダン
    submit: 保存

nav:
  home: Home
  preferences: 設定
  bookmarks: ブックマーク
```

```yaml
messages:
  confirm_delete: 'Delete %{name}. Are you sure?'

preferences:
  saved: Preferences saved.
  index:
    theme_options:
      modern: Modern
    submit: Save

nav:
  home: Home
  preferences: Preferences
  bookmarks: Bookmarks
```

**Planner action:** Seed all new keys in both files in the same plan. Use shared absolute namespaces for cross-feature labels (`actions.*`, `messages.*`, `gadgets.*`, `todos.priorities.*`, `date.formats.calendar_month`) and view namespaces for one-off copy (`bookmarks.index.*`, `welcome.note_gadget.*`, `feeds.form.*`, `calendars.get_gadget.*`).

**Parity gate**  
Source: `test/i18n/locales_parity_test.rb` lines 12-23.

```ruby
def test_jaとenのキー集合が一致する
  ja = YAML.load_file(Rails.root.join('config/locales/ja.yml'))['ja']
  en = YAML.load_file(Rails.root.join('config/locales/en.yml'))['en']

  ja_keys = flatten_keys(ja).sort
  en_keys = flatten_keys(en).sort

  only_in_ja = ja_keys - en_keys
  only_in_en = en_keys - ja_keys

  assert_empty only_in_ja, "ja.yml にのみ存在するキー: #{only_in_ja.inspect}"
  assert_empty only_in_en, "en.yml にのみ存在するキー: #{only_in_en.inspect}"
end
```

**Planner action:** Do not create a second parity mechanism. Let this test catch missing keys, and add feature assertions only for representative rendered output.

---

### Model Locale Runtime: `BookmarkGadget`, `TodoGadget`, `Todo`, `Calendar` (model, transform)

**Analogs:** `Localization` runtime locale wrapper, `Preference` constants, existing Todo and Calendar methods.

**Active locale is per request, so model helpers must resolve at call time**  
Source: `app/controllers/concerns/localization.rb` lines 10-18.

```ruby
def set_locale(&block)
  I18n.with_locale(resolved_locale, &block)
end

def resolved_locale
  [saved_locale, accept_language_match].each do |candidate|
    return candidate.to_sym if candidate && Preference::SUPPORTED_LOCALES.include?(candidate.to_s)
  end
  I18n.default_locale
end
```

**Current fixed gadget titles**  
Source: `app/models/bookmark_gadget.rb` lines 4-10 and `app/models/todo_gadget.rb` lines 11-16.

```ruby
def title
  'Bookmark'
end
```

```ruby
def title
  'Todo'
end

def entries
  @todos
end
```

**Planner action:** Change only the fixed title return values to `I18n.t('gadgets.bookmark.title')` and `I18n.t('gadgets.todo.title')`. Do not touch `entries` or gadget ids. Feed/calendar gadget titles are record data and must stay unchanged.

**Current Todo priority constant pitfall**  
Source: `app/models/todo.rb` lines 1-17.

```ruby
module TodoConst
  PRIORITIES = {
    PRIORITY_HIGH = 1 => '高',
    PRIORITY_NORMAL = 2 => '中',
    PRIORITY_LOW = 3 => '低',
  }
end

class Todo < ActiveRecord::Base
  include TodoConst
  include Crud::ByUser

  def priority_name
    PRIORITIES[self.priority]
  end
end
```

**Planner action:** Keep numeric constants. Replace translated labels in constants with a stable key mapping, for example `PRIORITY_KEYS = { PRIORITY_HIGH => :high, ... }`, and resolve labels in `Todo.priority_options` / `#priority_name` with `I18n.t(...)` at runtime. Do not store translated strings or migrate Todo rows.

**Existing select option i18n analog**  
Source: `app/views/preferences/index.html.erb` lines 23-36.

```erb
<th><%= f.label :font_size %></th>
<td><%= f.select :font_size, Preference::FONT_SIZES.map { |size| [t(".font_size_options.#{size}"), size] }, selected: (@user.preference.font_size.presence || Preference::FONT_SIZE_MEDIUM) %></td>
...
<th><%= f.label :default_priority %></th>
<td><%= f.select :default_priority, Todo::PRIORITIES.invert %></td>
```

**Planner action:** The `font_size` line is the model-driven option pattern to copy. Replace `Todo::PRIORITIES.invert` in both `todos/_form` and `preferences/index` with a runtime-localized option method.

**Current Calendar weekday/month and holiday boundary**  
Source: `app/models/calendar.rb` lines 16-19 and 41-49; `app/views/calendars/get_gadget.html.erb` lines 2-13 and 42-44.

```ruby
def day_of_week(index)
  @names ||= %w{ 日 月 火 水 木 金 土 }
  @names[index]
end
```

```ruby
def holiday(date)
  from = display_date.prev_month.beginning_of_month
  to = display_date.next_month.end_of_month
  @holidays_of_month ||= HolidayJp.between(from, to)
  @holidays_of_month.each do |holiday|
    return holiday.name if holiday.date == date
  end

  nil
end
```

```erb
<span><%= @calendar.display_year %>年<%= @calendar.display_month %>月</span>
...
<th class="<%= ['sunday', nil, nil, nil, nil, nil, 'saturday'][i] %>"><%= @calendar.day_of_week(i) %></th>
...
<%= @calendar.holiday(date) %>
```

**Planner action:** Localize weekday and month/year display only. Leave `holiday(date)` behavior unchanged and document Japanese `holiday_jp` names as intentionally external.

---

### ERB Translation Pattern: Feature Views (view, request-response)

**Analogs:** application shell navigation, preferences form, current feature views.

**Absolute key pattern for shared chrome**  
Source: `app/views/layouts/application.html.erb` lines 21-44 and `app/views/common/_menu.html.erb` lines 35-47.

```erb
<button class="hamburger-btn" aria-label="<%= t('nav.menu_aria') %>"></button>
...
<%= link_to t('nav.home'), root_path %>
<%= link_to t('nav.preferences'), preferences_path %>
<%= link_to t('nav.bookmarks'), bookmarks_path %>
<%= link_to t('nav.todos'), todos_path %>
<%= link_to t('nav.calendars'), calendars_path %>
<%= link_to t('nav.feeds'), feeds_path %>
<%= link_to t('nav.sign_out'), destroy_user_session_path, method: 'delete' %>
```

**Lazy lookup pattern for path-specific form copy**  
Source: `app/views/preferences/index.html.erb` lines 15, 24, and 59.

```erb
<%= f.select :theme, { t('.theme_options.modern') => 'modern', t('.theme_options.classic') => 'classic', t('.theme_options.simple') => 'simple' } %>
<%= f.select :font_size, Preference::FONT_SIZES.map { |size| [t(".font_size_options.#{size}"), size] }, selected: (@user.preference.font_size.presence || Preference::FONT_SIZE_MEDIUM) %>
<%= f.submit t('.submit') %>
```

**Planner action:** Use lazy lookup only where YAML paths exactly match the template path. For `_form.html.erb`, keys resolve under `bookmarks.form.*`, `feeds.form.*`, `calendars.form.*`, or `todos.form.*` depending on the partial path, not under the action name. Use absolute keys for shared labels such as `actions.edit`, `actions.delete`, `messages.confirm_delete`, and model code.

**Model attribute label pattern**  
Source: `app/views/bookmarks/index.html.erb` lines 31-33 and `app/views/feeds/_form.html.erb` lines 4-16.

```erb
<th><%= Bookmark.human_attribute_name :title %></th>
<th>URL</th>
<th colspan="2">操作</th>
```

```erb
<th><%= f.label :feed_url %></th>
<td><%= f.text_field :feed_url, class: 'feed_url' %></td>
...
<th><%= f.label :display_count %></th>
<td><%= f.number_field :display_count, class: 'display_count' %></td>
```

**Planner action:** Prefer `f.label` / `Model.human_attribute_name` when the label already maps to `activerecord.attributes.*`. Add feature keys only for non-attribute UI copy: action labels, breadcrumbs, helper text, placeholders, empty/loading/error states.

**Delete confirmation and user-content interpolation pattern**  
Source: `config/locales/ja.yml` line 28, `config/locales/en.yml` line 28, and `app/views/bookmarks/index.html.erb` lines 51-53.

```erb
<td><%= link_to '編集', edit_bookmark_path(b) %></td>
<td>
  <%= link_to '削除', bookmark_path(b), method: 'delete', data: { confirm: t('messages.confirm_delete', name: b.title) } %>
</td>
```

**Planner action:** Translate the sentence, not the interpolated content. Use `name: b.title`, `name: feed.title`, `name: @calendar.title`, or `name: t.title` only as values. Never derive translation keys from user or external content.

---

### Bookmark Surface (views + tests)

**Analogs:** current bookmark breadcrumb tests, layout/preferences I18n tests, bookmark current view structure.

**Current translatable strings and user-content boundary**  
Source: `app/views/bookmarks/index.html.erb` lines 1-24 and 37-53.

```erb
<nav class="breadcrumbs" aria-label="パンくずリスト">
  <ol class="breadcrumbs-list">
    <li class="breadcrumbs-item">
      <%= link_to 'ルート', bookmarks_path, class: 'breadcrumbs-link' %>
      <% unless @parent %>
        <span class="breadcrumbs-item-actions">
          <%= link_to new_bookmark_path(parent_id: nil), class: 'breadcrumbs-create-folder', title: 'フォルダを作成' do %>
            <span class="breadcrumbs-icon">📁</span><span class="breadcrumbs-label">フォルダ</span>
          <% end %>
        </span>
      <% end %>
    </li>
    <% if @parent %>
      <li class="breadcrumbs-item breadcrumbs-current">
        <%= @parent.title %>
      </li>
    <% end %>
```

```erb
<% if b.folder? %>
  <%= link_to b.title, bookmarks_path(parent_id: b.id), class: 'folder-link' %>
<% else %>
  <%= link_to b.title, b.url, target: '_blank' %>
<% end %>
...
<td><%= link_to '編集', edit_bookmark_path(b) %></td>
```

**Planner action:** Translate breadcrumb chrome (`aria-label`, root, create folder, folder/bookmark labels, action headers, edit/delete), but keep `@parent.title`, `b.title`, and `b.url` unchanged.

**Form pattern and submit pitfall**  
Source: `app/views/bookmarks/_form.html.erb` lines 1-33.

```erb
<%= form_for @bookmark do |f| %>
  <table>
    <tr>
      <th><%= f.label :url %></th>
      <td>
        <%= f.text_field :url, placeholder: 'URL（フォルダの場合は空欄）' %>
        <small>URLを空欄にするとフォルダとして作成されます</small>
      </td>
    </tr>
...
        <%= f.select :parent_id,
            options_for_select(
              [['なし（ルート）', nil]] +
              (@available_folders || Bookmark.where(user_id: current_user.id, deleted: false).folders.order(:title))
                      .map { |f| [f.title, f.id] },
              @bookmark.parent_id
            ),
...
  <%= f.submit %>
```

**Planner action:** Use explicit translated submit labels for deterministic bilingual UI. Keep folder option labels from `f.title` as user-created content. The `なし（ルート）` option is app chrome and should translate.

**Existing controller test target**  
Source: `test/controllers/bookmarks_controller_test.rb` lines 96-150.

```ruby
def test_ルートにいる場合のパンくず表示
  sign_in user
  get bookmarks_path

  assert_response :success
  assert_select 'nav.breadcrumbs', count: 1
  assert_select 'a.breadcrumbs-link', text: 'ルート'
  assert_select '.breadcrumbs-label', text: 'フォルダ'
  assert_select '.breadcrumbs-label', text: 'ブックマーク'
end
```

**Planner action:** Convert a small set of these to ja/en locale variants using `user.preference.update!(locale: 'ja'/'en')`. Keep separate assertions that folder titles such as `テストフォルダ` render unchanged.

**Cucumber dependency**  
Source: `features/step_definitions/bookmarks.rb` lines 20-23.

```ruby
もし /^登録ボタンをクリックしてブックマークを保存すると、トップページに表示されるようになります。$/ do
  click_on '登録する'
  visit '/'
```

**Planner action:** If bookmark submit becomes an explicit Japanese key such as `ブックマークを追加`, update this step. Do not rely on Rails default `登録する` after Phase 17.

---

### Welcome Gadget Surfaces (views + tests)

**Analogs:** current welcome partials and welcome controller tests.

**Bookmark gadget user content boundary**  
Source: `app/views/welcome/_bookmark_gadget.html.erb` lines 1-24.

```erb
<% bookmark_link_html_options = current_user.preference.open_links_in_new_tab? ? { target: '_blank', rel: 'noopener noreferrer' } : {} %>
<div id="<%= gadget.gadget_id %>" class="gadget">
  <div>
    <div class="title"><%= gadget.title %></div>
...
              <span class="folder-name"><%= item.title %></span>
...
                <li><%= link_to bookmark.title, bookmark.url, bookmark_link_html_options %></li>
```

**Planner action:** `gadget.title` for `BookmarkGadget` localizes via model. Folder/bookmark names and URLs are user content and stay unchanged.

**Note gadget current fixed copy**  
Source: `app/views/welcome/_note_gadget.html.erb` lines 1-15.

```erb
<section class="note-gadget">
  <h2>ノート</h2>
  <%= form_with model: @note, url: notes_path, local: true, html: { class: 'note-gadget-form' } do |f| %>
    <%= f.label :body, 'メモ' %>
    <%= f.text_area :body, rows: 4 %>
    <%= f.submit '保存' %>
  <% end %>
  <% if @notes.empty? %>
    <p class="note-empty">メモはまだありません</p>
  <% else %>
...
          <div class="note-body"><%= note.body %></div>
```

**Planner action:** Translate heading, body label, submit, and empty state. Do not translate `note.body`. Keep timestamp format out of scope unless the plan intentionally adds date localization coverage.

**Todo gadget current title/action integration**  
Source: `app/views/welcome/_todo_gadget.html.erb` lines 1-16 and `app/views/todos/_actions.html.erb` lines 1-4.

```erb
<div id="<%= gadget.gadget_id %>" class="gadget todo">
  <script>
    $(document).ready(function() {
      todos.init('#<%= gadget.gadget_id %>');
    });
  </script>

  <div>
    <div class="title"><%= gadget.title %></div>
    <ol>
      <%= render 'todos/actions' %>
```

```erb
<li class="todo_actions" data-authenticity_token="<%= form_authenticity_token %>">
  <span style="float: left;"><%= link_to '完了', delete_todos_path, onclick: 'todos.delete_todos(this); return false;' %></span>
  <span style="float: right;"><%= link_to '新しいタスク',  new_todo_path, onclick: 'todos.new_todo(this); return false;' %></span>
</li>
```

**Planner action:** Localize `TodoGadget#title` and action labels. Preserve the `onclick` hooks and `data-authenticity_token` attribute.

**Welcome tests to extend**  
Source: `test/controllers/welcome_controller/welcome_controller_test.rb` lines 65-84 and 121-131.

```ruby
def test_シンプルテーマのノートパネルにメモフォームが表示される
  user.preference.update!(theme: 'simple', use_note: true)
  sign_in user
  get root_path(tab: 'notes')
  assert_response :success
  assert_select '#notes-tab-panel .note-gadget h2', text: 'ノート', count: 1
  assert_select 'input[type=submit][value=?]', '保存', count: 1
end
```

```ruby
assert_includes response.body, own_note.body
assert_not_includes response.body, '他ユーザーの秘密メモ 13-02'
```

**Planner action:** Add representative ja/en gadget assertions here. Retain user-content assertions to guard the translation boundary.

---

### Todo Surface and Priority Labels (model + views + tests)

**Analogs:** current Todo AJAX partials, preference select option pattern, Cucumber todo label dependencies.

**Current Todo form and display pattern**  
Source: `app/views/todos/_form.html.erb` lines 1-14 and `app/views/todos/_todo.html.erb` lines 1-3.

```erb
<%= form_with model: @todo, html: {class: 'todo'} do |f| %>
  <table>
    <tr>
      <td><%= f.select :priority, Todo::PRIORITIES.invert %></td>
      <td><%= f.text_field :title %></td>
      <td>
        <% if @todo.new_record? %>
          <%= f.submit '登録', onclick: 'todos.create_todo(this); return false;' %>
        <% else %>
          <%= f.submit '更新', onclick: 'todos.update_todo(this); return false;' %>
        <% end %>
```

```erb
<li data-id="<%= todo.id %>" data-url="<%= edit_todo_path(todo) %>">
  <span class="<%= "priority_#{todo.priority}" %> center"><%= todo.priority_name %></span>
  <span><%= todo.title %></span>
</li>
```

**Planner action:** Replace priority options with `Todo.priority_options`; translate submit labels; keep todo title unchanged; keep numeric `todo.priority` class and stored value unchanged.

**Index table has an existing unrelated behavior smell**  
Source: `app/views/todos/index.html.erb` lines 1-12.

```erb
<th><%= Todo.human_attribute_name :priority %></th>
<th><%= Todo.human_attribute_name :title %></th>
...
<td><%= t.title %></td>
...
<%= link_to '削除', todo_path(t), method: 'delete', confirm: t('messages.confirm_delete', name: t.title) %>
```

**Planner action:** Translate delete label, but avoid broadening Phase 17 into correcting the apparent priority-column row mismatch unless the plan explicitly scopes it as a separate bug fix.

**Cucumber dependencies**  
Source: `features/02.タスク.feature` lines 5-13 and `features/step_definitions/todos.rb` lines 18-37 and 49-55.

```gherkin
シナリオ: タスクウィジェットを使用する
  * 設定画面で タスクウィジェットを表示する にチェックを入れます。
  * ポータルに Todo というウィジェットが表示されます。
  * 新しいタスク をクリックしてタスクを追加します。
  * 空白のまま 登録 をクリックするとタスクの入力が終了します。
```

```ruby
もし /^ポータルに (.*?) というウィジェットが表示されます。$/ do |name|
  click_on 'Bookmarks'
  assert has_selector?('#todo .title', text: name)
end

within 'form.todo' do
  fill_in 'todo[title]', with: '新しいタスクの内容'
  click_on '登録'
end
```

**Planner action:** Update Japanese feature text/steps if Japanese labels intentionally change (`Todo` -> `タスク`, `新しいタスク` -> `タスクを追加`, `登録` -> a specific create label). Keep Cucumber as browser smoke coverage; use Minitest for detailed ja/en assertions.

---

### Feed Surface and Server-Fed JavaScript Messages (views + JS + tests)

**Analogs:** existing Sprockets namespace style, existing `data-url` handoff, jQuery `.data(...)` reads.

**Current form-side data attribute handoff**  
Source: `app/views/feeds/_form.html.erb` lines 1-19.

```erb
<%= form_for @feed do |f| %>
...
<%= f.button 'フィードから取得', onclick: 'feeds.get_feed_title(this); return false;', 'data-url': url_for(action: 'get_feed_title') %>
...
<td colspan="2"><%= f.submit %></td>
```

**Current JS namespace and hardcoded alerts**  
Source: `app/assets/javascripts/feeds.js` lines 1-33.

```javascript
// Sprockets bundle: share namespace for load order (no new globals).
window.feeds = window.feeds || {};
// NOTE: `feeds` is a snapshot of the window.feeds reference at parse time.
// window.feeds remains the authoritative global; never reassign it in another
// file or the alias here will become stale.
const feeds = window.feeds;

feeds.get_feed_title = function(button) {
  const form = $(button).closest('form');

  const url = form.find('input[name*="feed_url"]').val();
  if (url === '') {
    alert('フィードURLを先に入力してください。');
    return;
  }
...
  $.post($(button).data('url'), params, (title) => {
    if ($.trim(title) === '') {
      alert('フィードを取得できませんでした。');
      return;
    }
```

**Planner action:** Preserve namespace and callback style. Add translated attributes such as `data-feed-url-required-message` and `data-feed-fetch-failed-message` to the button, then read them with `$(button).data('feedUrlRequiredMessage')` and `$(button).data('feedFetchFailedMessage')`. Do not introduce `i18n-js`, globals, imports, or a JS translation registry.

**Existing jQuery data read pattern**  
Source: `app/assets/javascripts/todos.js` lines 60-72.

```javascript
todos.delete_todos = function(trigger) {
  const ol = $(trigger).closest('ol');
  const url = $(trigger).attr('href');

  const params = {};
  params.format = 'html';
  params.authenticity_token = $(trigger).closest('.todo_actions').data('authenticity_token');
  params.todo_id = [];
  ol.find('li.selected').each(function() {
    params.todo_id.push($(this).data('id'));
  });

  $.post(url, params, function () {
```

**Planner action:** `feeds.js` can copy this local element `.data(...)` style. There is no existing translated `data-*` message exact analog; the closest local analog is data-driven JS behavior.

**Feed index user/external boundary**  
Source: `app/views/feeds/index.html.erb` lines 1-24 and `app/views/feeds/show.html.erb` lines 1-7.

```erb
<%= link_to '追加', new_feed_path %>
...
<div>1件も登録されていません。</div>
...
<th>サイト名</th>
<th>表示件数</th>
<th>フィードURL</th>
...
<td><%= feed.title %></td>
<td class="center"><%= feed.display_count %></td>
<td><div class="feed_url"><%= feed.feed_url %></div></td>
<td><%= link_to '編集', edit_feed_path(feed) %></td>
```

```erb
<div class="title"><%= link_to @feed.title, @feed.url, link_opts %></div>
<ol>
  <% @feed.entries.each do |e| %>
    <li><%= link_to e.title, e.url, link_opts %></li>
  <% end %>
</ol>
```

**Planner action:** Translate fixed labels and empty state. Preserve feed record fields and fetched entry titles/URLs.

**Welcome feed inline AJAX pattern**  
Source: `app/views/welcome/_feed.html.erb` lines 1-18.

```erb
<script>
  $(document).ready(function() {
    $.get('<%= feed_path(gadget) %>', {format: 'html'}, function(html) {
      $('#feed_<%= gadget.id %>').html(html);
    })
    .fail(function(xhr, status, error) {
      $('#feed_<%= gadget.id %>').find('ol li span').first().text('フィードを取得できませんでした。(' + xhr.status + ')');
    });
  });
</script>
...
<span style="line-height: <%= gadget.display_count * 1.5 %>em;">フィードを取得中・・・</span>
```

**Planner action:** Prefer server-rendered `data-*` on the gadget container for loading/failure copy, or use `to_json` if writing JS string literals. Preserve the fetched `gadget.title` as record data.

---

### Calendar Surface (model + views + tests)

**Analogs:** current calendar gadget rendering, calendar controller `get_gadget` request test, localization runtime.

**Calendar gadget loading and title boundary**  
Source: `app/views/welcome/_calendar.html.erb` lines 1-13.

```erb
<div id="<%= gadget.gadget_id %>" class="gadget">
  <div>
    <div class="title"><%= gadget.title %></div>
    <div style="line-height: 30em;">
      <script>
        $(document).ready(function() {
          $.get('<%= url_for controller: 'calendars', action: 'get_gadget', id: gadget.id, display_date: gadget.display_date %>', {format: 'html'}, function(html) {
            $('#<%= gadget.gadget_id %>').find('div').last().replaceWith(html);
          });
        });
      </script>
      <span><%= gadget.title %>を取得中・・・</span>
```

**Planner action:** Translate the loading sentence and interpolate `gadget.title` unchanged. Do not translate calendar record titles.

**Current month/weekday partial**  
Source: `app/views/calendars/get_gadget.html.erb` lines 1-14.

```erb
<table class="calendar">
  <caption>
    <%= link_to '<<',
          {controller: 'calendars', action: 'get_gadget', id: @calendar.id, display_date: @calendar.display_date - 1.month},
          onclick: 'calendars.get_gadget(this); return false;' %>
    <span><%= @calendar.display_year %>年<%= @calendar.display_month %>月</span>
    <%= link_to '>>',
          {controller: 'calendars', action: 'get_gadget', id: @calendar.id, display_date: @calendar.display_date + 1.month},
          onclick: 'calendars.get_gadget(this); return false;' %>
  </caption>
  <tr>
    <% 7.times do |i| %>
      <th class="<%= ['sunday', nil, nil, nil, nil, nil, 'saturday'][i] %>"><%= @calendar.day_of_week(i) %></th>
```

**Planner action:** Use Rails I18n date data for weekday labels and add `date.formats.calendar_month` for caption formatting. If adding `title`/`aria-label` to `<<` and `>>`, localize those labels under `calendars.get_gadget.previous_month` / `next_month`. Keep glyph text unchanged unless accessibility labels are added.

**Show/edit actions**  
Source: `app/views/calendars/show.html.erb` lines 1-9 and `app/views/calendars/edit.html.erb` lines 1-5.

```erb
<div class="actions">
  <%= link_to '編集', edit_calendar_path(@calendar) %>
  <%= link_to '削除', calendar_path(@calendar), method: 'delete', data: {confirm: t('messages.confirm_delete', name: @calendar.title)} %>
</div>
...
<td><%= @calendar.title %></td>
```

```erb
<div class="actions">
  <%= link_to '参照', calendar_path(@calendar) %>
</div>

<%= render 'form' %>
```

**Planner action:** Translate action labels and submit labels. Preserve `@calendar.title`.

**Calendar test analog**  
Source: `test/controllers/calendars_controller_test.rb` lines 119-125.

```ruby
def test_ガジェットの取得
  calendar = calendar(user)
  sign_in user

  get get_gadget_calendar_path(calendar), params: { display_date: Date.today.strftime('%Y-%m-%d') }
  assert_response :success
  assert_equal "/calendars/#{calendar.id}/get_gadget", path
end
```

**Planner action:** Extend this with stable `display_date` and ja/en assertions for month/year and weekdays. Add an explicit assertion that a known `holiday_jp` holiday name remains Japanese if using a stable date fixture.

---

### Controller Integration Tests With Locale Preference

**Analogs:** application and preferences controller tests.

**Saved locale request pattern**  
Source: `test/controllers/application_controller_test.rb` lines 5-20 and 41-58.

```ruby
def test_保存済みlocaleがenのユーザは英語でレンダリングされる
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'html[lang=?]', 'en'
end
```

```ruby
def test_chromeはen_localeでHomeとPreferencesとMenuariaを含む
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'a', text: 'Home'
  assert_select 'a', text: 'Preferences'
  assert_select 'button.hamburger-btn[aria-label=?]', 'Menu'
end
```

**Representative ja/en UI assertion pattern**  
Source: `test/controllers/preferences_controller_test.rb` lines 153-183.

```ruby
def test_設定画面が日本語ロケールで日本語表示される
  user.preference.update!(locale: 'ja')
  sign_in user
  get preferences_path

  assert_response :success
  assert_select 'html[lang=?]', 'ja'
  assert_select 'th', text: 'テーマ'
  assert_select 'option', text: 'モダン'
  assert_select 'input[type=submit][value=?]', '保存'
end

def test_設定画面が英語ロケールで英語表示される
  user.preference.update!(locale: 'en')
  sign_in user
  get preferences_path

  assert_response :success
  assert_select 'html[lang=?]', 'en'
  assert_select 'th', text: 'Theme'
  assert_select 'option', text: 'Modern'
  assert_select 'input[type=submit][value=?]', 'Save'
end
```

**Planner action:** Copy this pattern for feature surfaces rather than asserting every translated string. Use representative ja/en assertions plus user-content invariants.

## Shared Patterns

### Rails I18n Catalog Parity

**Source:** `config/locales/ja.yml`, `config/locales/en.yml`, `test/i18n/locales_parity_test.rb`  
**Apply to:** all new Phase 17 keys

- Add keys to both locale files in the same plan.
- Keep key sets exactly symmetric.
- Prefer shared namespaces for reused labels and feature namespaces for one-off view copy.
- Keep language selector native labels (`自動`, `日本語`, `English`) unchanged per Phase 15 precedent.

### `t(...)` and Lazy Lookup Conventions

**Source:** `app/views/layouts/application.html.erb`, `app/views/preferences/index.html.erb`

- Use absolute keys for shared copy and model-level code: `t('nav.*')`, `t('messages.confirm_delete')`, `I18n.t('gadgets.*')`, `I18n.t('todos.priorities.*')`.
- Use lazy lookup only when the path is obvious and exact: `t('.submit')` in `preferences/index` resolves under `preferences.index.submit`.
- Partial lazy lookup must account for partial path. A `bookmarks/_form.html.erb` key resolves under `bookmarks.form.*`.

### User/External Content Interpolation

**Source:** `messages.confirm_delete` usage in bookmarks/calendar/feed/todo views

- Translate UI sentences and labels only.
- Interpolate user/external values unchanged: bookmark titles, folder names, note bodies, todo titles, feed titles/entries, calendar titles.
- Never build translation keys from user or external content.
- Japanese `holiday_jp` names are external regional data and intentionally remain Japanese.

### Sprockets and jQuery `data-*` Message Pattern

**Source:** `app/assets/javascripts/feeds.js`, `app/views/feeds/_form.html.erb`, `app/assets/javascripts/todos.js`

- Keep first-party JS in existing global namespaces: `window.feeds = window.feeds || {}; const feeds = window.feeds;`.
- Supply JS-visible prose from ERB-rendered `data-*` attributes on the relevant button/container.
- Read data with jQuery camelCase keys, e.g. `data-feed-url-required-message` -> `.data('feedUrlRequiredMessage')`.
- No `i18n-js`, no `window.I18n`, no import maps/bundlers, no new global translation registry.
- If inline JS literals are unavoidable, use Rails escaping via `to_json`.

### Cucumber Label Dependencies

**Source:** `features/step_definitions/bookmarks.rb`, `features/step_definitions/todos.rb`, `features/step_definitions/notes.rb`

- Existing browser steps click visible Japanese labels such as `保存`, `登録`, `新しいタスク`, and expect `Todo`.
- Update Cucumber only where the Japanese visible label intentionally changes.
- Keep Cucumber as smoke coverage for interactions; put detailed bilingual copy assertions in Minitest.
- Run with `bundle exec rake dad:test`, not `bundle exec cucumber`.

### Verification Gate

**Source:** `CLAUDE.md`

Phase completion requires:

1. `yarn run lint`
2. `bin/rails test`
3. `bundle exec rake dad:test`

If `dad:test` fails, rerun once because the suite currently has known scenario-order flakiness around preference state. A repeated failure is a real regression.

## No Analog Found / Thin Analog Areas

| Area | Reason | Planner Guidance |
|------|--------|------------------|
| Translated `data-*` JS messages | Existing app has `data-url`, `data-id`, and `data-authenticity_token`, but no translated message attribute yet | Copy the local data handoff style; use research-recommended data message names and jQuery camelCase reads |
| Calendar month localization via `l(date, format: ...)` | No existing app use of `l(...)`, `date.formats.*`, or `date.abbr_day_names` was found | Add `date.formats.calendar_month` to both locale files and rely on Rails I18n date data |
| Model-level `I18n.t` in plain gadget objects | Existing translations are mostly controller/view-level; gadget title change is new | Use absolute keys and resolve at method call time inside `title` |

## Planner Checklist

- Seed locale keys first and keep parity green.
- Add runtime model helpers for gadget titles, Todo priority labels, and Calendar weekday/month formatting before view rewrites.
- Translate fixed feature chrome only; preserve user/external content byte-for-byte.
- Feed JavaScript-visible strings from ERB-rendered attributes, not a JS i18n runtime.
- Add representative ja/en Minitest coverage per surface.
- Update Cucumber labels only when Japanese visible labels intentionally change.
- Keep Phase 18 surfaces (Devise/auth pages and milestone-wide audit) out of scope.

## Metadata

**Analog search scope:** `app/models`, `app/views`, `app/assets/javascripts`, `config/locales`, `test`, `features`, `.planning/codebase`  
**Files scanned:** 39 source/test files plus Phase 17 context, research, and UI spec  
**Pattern extraction date:** 2026-05-01
