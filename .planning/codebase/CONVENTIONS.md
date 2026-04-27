# Coding Conventions

**Analysis Date:** 2026-04-27

## Overview

**JavaScript (Sprockets):** リンター/フォーマッタの手順はルート `README.md` の JavaScript セクションを正とする。

This is a Rails 8.1 application written in Ruby 3.4 with no RuboCop configuration present. Conventions are implied by Rails defaults and the `daddy` gem (a proprietary scaffolding/CRUD library). Business logic lives primarily in models with lightweight controllers; service objects are not used.

## JavaScript (Sprockets 第一者スクリプト)

第一者 `app/assets/javascripts/**/*.js` は jQuery 前提。次を守る:

- jQuery コールバックで**要素**として `this` を使う箇所（`$(this)` や `.each` 等）は**アロー関数にせず** `function` を使う。
- `this` を使わない短いコールバック（例: `$.get` / `$.post` のデータ受け取り）はアロー関数にしてよい。
- グローバルに載る名前空間（例: ガジェット用オブジェクト）は `window.name = window.name || {}` と `const name = window.name` など、意図が読み取れる形にする。新たな `window` 汚染を増やさない。
- 束縛は原則 `const` または `let`（`var` 禁止; ESLint `no-var` 準拠。例外は当該行 `eslint-disable-next-line` と理由 1 行）。
- ESLint はリポジトリルートの `eslint.config.mjs`（対象: `app/assets/javascripts/**/*.js`、`@eslint/js` recommended ＋ Prettier 連携）。代表ルールは `no-var`（error）。実行: `yarn run lint`。

## Naming Conventions

**Models:**
- `PascalCase` singular class names matching Rails convention: `Bookmark`, `BookmarkGadget`, `TodoGadget`, `PortalLayout`
- Module-based constants are defined in a companion module with a `Const` suffix and then `include`d: `FeedConst` included in `Feed`, `TodoConst` included in `Todo`
- File: `snake_case` matching the class name — `bookmark_gadget.rb`, `portal_layout.rb`

**Controllers:**
- `PascalCase` plural resource name: `BookmarksController`, `FeedsController`, `PreferencesController`
- Nested namespacing mirrors URL structure: `Users::OmniauthCallbacksController`, `Users::TwoFactorAuthenticationController`
- File: `app/controllers/bookmarks_controller.rb`, `app/controllers/users/two_factor_authentication_controller.rb`

**Views:**
- Directory matches controller name (plural snake_case): `app/views/bookmarks/`, `app/views/feeds/`
- Partials prefixed with `_`: `_form.html.erb`, `_todo.html.erb`, `_actions.html.erb`
- Shared partials live in `app/views/common/`: `_menu.html.erb`
- Widget partials for the portal live in `app/views/welcome/`: `_bookmark_gadget.html.erb`, `_feed.html.erb`, `_todo_gadget.html.erb`, `_calendar.html.erb`

**Routes:**
- Standard `resources` declarations for all CRUD resources
- Custom actions declared with `member` or `collection` blocks
- Named route helpers follow Rails defaults (`bookmarks_path`, `edit_bookmark_path`, etc.)

**Test methods:**
- Method names written in Japanese: `def test_一覧`, `def test_他人のブックマークは参照できない`
- Cucumber step definitions also written in Japanese regex: `もし /^設定画面で.../`

## Ruby Style

No `.rubocop.yml` is present. Observed style from source files:

- Two-space indentation throughout
- Single-quoted strings preferred for simple literals
- `private` keyword used to separate public from private methods in models and controllers
- Guard clauses used in validations (`return unless`, `return if`)
- `!` bang methods used for raising versions: `save!`, `update!`, `destroy_logically!`
- Inline comments in Japanese where explanations are warranted
- `snake_case` for all methods, variables, and symbols
- `SCREAMING_SNAKE_CASE` for constants: `PRIORITY_HIGH`, `PRIORITY_NORMAL`, `DEFAULT_DISPLAY_COUNT`

## ERB/View Patterns

- Forms use `form_for @resource` (Rails classic style, not `form_with`)
- `_form.html.erb` partials are shared between `new` and `edit` views
- Tables used for form layout (not `div`-based): `<table><tr><th>label</th><td>field</td></tr></table>`
- `link_to` with a block for icon+label links:
  ```erb
  <%= link_to path, class: 'css-class', title: 'tooltip' do %>
    <span class="icon">emoji</span><span class="label">text</span>
  <% end %>
  ```
- Conditional CSS classes applied inline: `class="<%= 'folder' if b.folder? %>"`
- I18n used for attribute names: `Bookmark.human_attribute_name :title`
- Confirmation dialogs via `data: { confirm: t('messages.confirm_delete', name: ...) }`
- JavaScript responses use `.js.erb` templates: `app/views/todos/update.js.erb`
- Emoji used as inline UI icons in view templates

## Business Logic Organization

**Models carry domain logic.** No service objects exist. Logic is layered as:

1. **Constants module** — defined adjacent to or above the model class, `include`d into the model:
   - `app/models/feed.rb` defines `FeedConst` then `class Feed < ApplicationRecord; include FeedConst`
   - `app/models/todo.rb` defines `TodoConst` then `class Todo < ActiveRecord::Base; include TodoConst`

2. **`Crud::ByUser` concern** — included in `Bookmark`, `Feed`, `Todo`. Provides `readable_by?`, `creatable_by?`, `updatable_by?`, `deletable_by?` authorization predicates used in controllers and tests.

3. **Model-level factory/default methods** — class methods that build unsaved default objects:
   - `Preference.default_preference(user)` in `app/models/preference.rb`

4. **Logical deletion** — soft-delete pattern via a `deleted` boolean column. Models expose `destroy_logically!` (`update!(deleted: true)`). Scopes like `not_deleted` are provided (via `Crud::ByUser` or explicitly).

5. **Controllers are thin** — actions do minimal work: fetch records via `before_action :preload_<resource>`, authorize via `readable_by?`, call `save!`/`destroy_logically!`, then redirect.

6. **Callbacks used sparingly in models:**
   - `before_save :set_display_count` in `Feed`
   - `before_create :generate_otp_secret_if_missing` in `User`
   - `after_save :create_default_portal` in `User`

## Authorization Pattern

Resource ownership authorization is done through the `Crud::ByUser` mixin. Controllers call `readable_by?(current_user)` inside a `before_action` preload method and respond with `head :not_found` on failure:

```ruby
def preload_bookmark
  @bookmark = Bookmark.find(params[:id])
  unless @bookmark.readable_by?(current_user)
    head :not_found and return
  end
end
```

## Strong Parameters

Strong parameters are defined in a private `<resource>_params` method in each controller. Post-permit transformation is done inline before returning the hash (e.g., converting empty string URL to `nil` in `BookmarksController#bookmark_params`).

---

*Convention analysis: 2026-04-27*
