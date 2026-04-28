# Phase 6: HTML Structure - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 2 (1 modified layout, 1 new test file)
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `app/views/layouts/application.html.erb` | layout (view) | request-response (SSR) | `app/views/common/_menu.html.erb` | role-match (both are ERB view files; menu partial is the nav link source of truth) |
| `test/controllers/layout_structure_test.rb` | test | request-response | `test/controllers/welcome_controller_test.rb` | exact (same class, same sign_in + get + assert_select pattern) |

---

## Pattern Assignments

### `app/views/layouts/application.html.erb` (layout, request-response)

**Analog:** `app/views/common/_menu.html.erb` (nav link source of truth) + current layout self-reference

**Current layout state** (`app/views/layouts/application.html.erb` lines 1-29 — full file):

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Bookmarks</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/icon.svg" />
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag    'application', media: 'all' %>
    <%= javascript_include_tag 'application' %>
    <script src="https://apis.google.com/js/api.js"></script>

  </head>

  <body class="<%= favorite_theme %>">
    <div id="header">
      <div class="head-box">
        <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
        Bookmarks
      </div>
    </div>

    <div class="wrapper">
      <%= render 'common/menu' if user_signed_in? %>
      <%= yield %>
    </div>
  </body>
</html>
```

**Nav links pattern** (`app/views/common/_menu.html.erb` lines 35-44 — source of truth for all 7 link_to calls):

```erb
<li><%= link_to 'Home', root_path %></li>
<div><%= link_to '設定', preferences_path %></div>
<div><%= link_to 'ブックマーク', bookmarks_path %></div>
<div><%= link_to 'タスク', todos_path %></div>
<div><%= link_to 'カレンダー', calendars_path %></div>
<div><%= link_to 'フィード', feeds_path %></div>
<div><%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %></div>
```

**Auth guard pattern** (`app/views/layouts/application.html.erb` line 25):

```erb
<%= render 'common/menu' if user_signed_in? %>
```

The drawer and overlay must use the same `if user_signed_in?` guard — placed as a block wrapping both elements after `.wrapper` closes.

**Target diff — Edit 1: hamburger button inside `.head-box`** (insert after line 20, before `</div>` on line 21):

```erb
        <button class="hamburger-btn" aria-label="メニュー"></button>
```

Button rules:
- Direct child of `.head-box` (not wrapped in any extra element)
- Empty body — no text, no `<span>` children
- `aria-label` value is `"メニュー"` (Japanese, matching app locale)

**Target diff — Edit 2: drawer + overlay after `.wrapper`** (insert after line 27 `</div>`, before `</body>`):

```erb
    <% if user_signed_in? %>
      <div class="drawer">
        <nav>
          <%= link_to 'Home', root_path %>
          <%= link_to '設定', preferences_path %>
          <%= link_to 'ブックマーク', bookmarks_path %>
          <%= link_to 'タスク', todos_path %>
          <%= link_to 'カレンダー', calendars_path %>
          <%= link_to 'フィード', feeds_path %>
          <%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
        </nav>
      </div>
      <div class="drawer-overlay"></div>
    <% end %>
```

Placement rules:
- After `</div>` closing `.wrapper` (currently line 27) — NOT inside `.wrapper`
- Before `</body>` — making both elements direct children of `<body>`
- `<nav>` element wraps links (semantic HTML; gives Phase 7 stable `.drawer nav` selector)
- `drawer-overlay` is empty — Phase 8 JS wires click-to-close; Phase 7 CSS styles the backdrop

---

### `test/controllers/layout_structure_test.rb` (test, request-response)

**Analog:** `test/controllers/welcome_controller_test.rb` (exact match — same class, same idioms)

**Require + class declaration pattern** (`test/controllers/welcome_controller_test.rb` lines 1-3):

```ruby
require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
```

Copy verbatim, changing class name to `LayoutStructureTest`.

**sign_in + get + assert_response pattern** (`test/controllers/welcome_controller_test.rb` lines 5-10):

```ruby
  def test_トップページ
    sign_in user
    get root_path
    assert_response :success
    assert_equal '/', path
  end
```

**assert_select with CSS attribute selectors** (`test/controllers/welcome_controller_test.rb` lines 12-18):

```ruby
  def test_ブックマークを新しいタブで開く設定がオンのときリンクにtarget_blankが付く
    sign_in user
    user.preference.update!(open_links_in_new_tab: true)
    get root_path
    assert_response :success
    assert_select '#bookmark_gadget a[href=?][target=?][rel=?]', 'www.example.com', '_blank', 'noopener noreferrer', text: 'ブックマーク1'
  end
```

The `assert_select 'selector[attr=?]', value` form is the project standard for attribute matching.

**`user` helper** (`test/support/users.rb` lines 1-4):

```ruby
def user
  assert @_user ||= User.first
  @_user
end
```

Available in all `ActionDispatch::IntegrationTest` classes via `test/support/*.rb` class_eval in `test_helper.rb`. Use `user` directly — do not redefine.

**Devise sign_in availability** (`test/test_helper.rb` lines 17-19):

```ruby
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

`sign_in user` is available in all integration tests with no additional setup.

**preference update pattern for theme** (`test/controllers/welcome_controller_test.rb` lines 13-14):

```ruby
    user.preference.update!(open_links_in_new_tab: true)
```

For Phase 6 tests, apply theme: `user.preference.update!(theme: 'modern')` before `sign_in user`.

**Target test file structure:**

```ruby
require 'test_helper'

class LayoutStructureTest < ActionDispatch::IntegrationTest

  def test_モダンテーマでハンバーガーボタンが表示される
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
  end

  def test_デフォルトテーマでもハンバーガーボタンが存在する
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn', count: 1
  end

  def test_モダンテーマでドロワーが存在する
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'div.drawer', count: 1
    assert_select 'div.drawer-overlay', count: 1
  end

  def test_ドロワーに全ナビリンクが含まれる
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select '.drawer a[href=?]', root_path
    assert_select '.drawer a[href=?]', preferences_path
    assert_select '.drawer a[href=?]', bookmarks_path
    assert_select '.drawer a[href=?]', todos_path
    assert_select '.drawer a[href=?]', calendars_path
    assert_select '.drawer a[href=?]', feeds_path
    assert_select '.drawer a[href=?]', destroy_user_session_path
  end

  def test_非ログイン時はドロワーが存在しない
    get root_path
    assert_response :redirect
  end

end
```

---

## Shared Patterns

### Auth Guard for Layout Elements
**Source:** `app/views/layouts/application.html.erb` line 25
**Apply to:** Drawer `<div>` and overlay `<div>` in the layout edit

```erb
<%= render 'common/menu' if user_signed_in? %>
```

The guard for drawer/overlay uses the block form:
```erb
<% if user_signed_in? %>
  ...
<% end %>
```

Note: The hamburger button itself is NOT guarded — it renders unconditionally in the header (the header is always visible). Only drawer and overlay are inside the guard.

### Nav Link Helpers with method: delete
**Source:** `app/views/common/_menu.html.erb` line 44
**Apply to:** Logout link in drawer nav

```erb
<%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %>
```

This is the exact call to reproduce. Do not use a form, do not hardcode the path, do not use `:delete` symbol vs string `'delete'` (both work, but match the existing file's style).

### Integration Test Class Structure
**Source:** `test/controllers/welcome_controller_test.rb` lines 1-3, `test/test_helper.rb` lines 17-19
**Apply to:** `test/controllers/layout_structure_test.rb`

```ruby
require 'test_helper'

class LayoutStructureTest < ActionDispatch::IntegrationTest
  # sign_in, user helper, assert_select all available with no additional includes
end
```

### Japanese Method Names in Tests
**Source:** `test/controllers/welcome_controller_test.rb` lines 5, 12, 20 (and throughout the test suite)
**Apply to:** All test methods in `layout_structure_test.rb`

```ruby
def test_トップページ      # welcome_controller_test.rb line 5
def test_一覧             # bookmarks_controller_test.rb line 5
def test_ブックマークを新しいタブで開く設定がオンのときリンクにtarget_blankが付く  # line 12
```

All test method names are in Japanese after `test_`. Follow this convention for all 5 test methods.

---

## No Analog Found

None — both files have strong analogs in the codebase.

---

## Metadata

**Analog search scope:** `app/views/layouts/`, `app/views/common/`, `test/controllers/`, `test/support/`, `test/test_helper.rb`
**Files scanned:** 7 (application.html.erb, _menu.html.erb, welcome_controller_test.rb, bookmarks_controller_test.rb, test_helper.rb, users.rb support file)
**Pattern extraction date:** 2026-04-29
