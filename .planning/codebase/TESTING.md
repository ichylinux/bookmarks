# Testing Patterns

**Analysis Date:** 2026-04-27

## Overview

The application uses Minitest (Rails default) for unit and controller integration tests, and Cucumber with Capybara for end-to-end browser tests. There are no RSpec files. Test data is managed via YAML fixtures. A shared `test/support/` directory provides helper methods used by both Minitest and Cucumber.

## Test Framework

**Runner:**
- Minitest `~> 5.0` with `minitest-reporters`
- Config: `test/test_helper.rb`

**Assertion Library:**
- Minitest assertions (`assert_response`, `assert_select`, `assert_difference`, `assert_no_difference`, `assert_equal`)

**E2E:**
- Cucumber via `cucumber-rails`
- Capybara with Selenium WebDriver (Chrome)
- Config: `features/support/env.rb` (delegates to `daddy/cucumber/rails`)

**Coverage:**
- SimpleCov available (`gem 'simplecov', require: false`) but not loaded by default in `test_helper.rb`
- CI reporting via `ci_reporter`

**Run Commands:**
```bash
rails test                    # Run all Minitest tests
rails test test/models/       # Run model tests only
rails test test/controllers/  # Run controller tests only
cucumber                      # Run Cucumber features
```

## Test File Organization

**Minitest location:** `test/` — mirrors `app/` structure

```
test/
├── test_helper.rb
├── application_system_test_case.rb
├── controllers/
│   ├── bookmarks_controller_test.rb
│   ├── calendars_controller_test.rb
│   ├── feeds_controller_test.rb
│   ├── preferences_controller_test.rb
│   ├── todos_controller_test.rb
│   ├── two_factor_authentication_controller_test.rb
│   ├── two_factor_setup_controller_test.rb
│   └── welcome_controller_test.rb
├── models/
│   ├── feed_test.rb
│   ├── preference_test.rb
│   └── user_two_factor_test.rb
├── fixtures/
│   ├── users.yml
│   ├── bookmarks.yml
│   ├── feeds.yml
│   ├── todos.yml
│   ├── calendars.yml
│   ├── portals.yml
│   └── preferences.yml
├── support/
│   ├── users.rb
│   ├── bookmarks.rb
│   ├── feeds.rb
│   ├── calendars.rb
│   └── preferences.rb
├── integration/   (empty — .keep only)
├── system/        (empty — .keep only)
├── mailers/       (empty — .keep only)
└── helpers/       (empty — .keep only)
```

**Cucumber location:** `features/`

```
features/
├── 02.タスク.feature
├── step_definitions/
│   ├── todos.rb
│   └── preferences.rb
└── support/
    ├── env.rb
    ├── login.rb
    └── test_support.rb
```

**Naming:**
- Minitest files: `<resource>_controller_test.rb`, `<model>_test.rb`
- Test methods named in Japanese: `def test_一覧`, `def test_他人のブックマークは参照できない`
- Cucumber step definitions use Japanese regex: `もし /^.../`

## Test Structure

**Controller test class:**
```ruby
require 'test_helper'

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def test_一覧
    sign_in user
    get bookmarks_path
    assert_response :success
    assert_equal '/bookmarks', path
  end
end
```

**Model test class:**
```ruby
require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def test_デフォルトのユーザ設定
    p = Preference.default_preference(user)
    assert_equal Todo::PRIORITY_NORMAL, p.default_priority
  end
end
```

**Patterns:**
- No `setup`/`teardown` blocks — test state is set up inline or via memoized support helpers
- `sign_in user` (Devise test helper) called at the start of authenticated tests
- `assert_select` used for HTML structure assertions in controller tests
- `assert_difference` / `assert_no_difference` used to assert DB record count changes

## Authentication in Tests

Devise test helpers are included in the base class:

```ruby
# test/test_helper.rb
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

Tests call `sign_in user` where `user` is the support helper returning `User.first` from fixtures.

## Fixtures and Support Helpers

**Fixtures** (`test/fixtures/*.yml`) provide static seed data for all tests. All fixtures are loaded for every test (`fixtures :all` in `ActiveSupport::TestCase`).

Example fixture (`test/fixtures/users.yml`):
```yaml
1:
  id: 1
  email: user@example.com
  encrypted_password: $2a$10$...
  admin: true
```

**Support helpers** (`test/support/*.rb`) are module-level methods `class_eval`'d into `ActiveSupport::TestCase` at load time. They provide memoized record accessors and param builders:

```ruby
# test/support/users.rb
def user
  assert @_user ||= User.first
  @_user
end

# test/support/bookmarks.rb
def bookmark(user)
  @_bookmarks ||= {}
  assert @_bookmarks[user.id] ||= Bookmark.where(user_id: user.id).not_deleted.first
  @_bookmarks[user.id]
end

def bookmark_params(user)
  { title: 'ブックマーク', url: 'www.example.com' }
end
```

The same `test/support/` files are shared with Cucumber via `features/support/test_support.rb`:

```ruby
module TestSupport
  Dir[File.join(Rails.root, 'test', 'support', '*.rb')].each do |f|
    self.class_eval File.read(f)
  end
end
World(TestSupport)
```

## Cucumber / E2E Tests

Features are written in Japanese Gherkin (`features/02.タスク.feature`). Step definitions use Japanese regex and Capybara DSL:

```ruby
もし /^設定画面で タスクウィジェットを表示する にチェックを入れます。$/ do
  sign_in user
  click_on current_user.email
  click_on '設定'
  check 'タスクウィジェットを表示する'
  click_on '保存'
end
```

Selenium/Chrome is configured in `test/application_system_test_case.rb` (screen size 1400x1400). The `daddy` gem provides `sign_in`, `capture`, and `with_capture` helpers used in step definitions.

## Authorization Testing Pattern

Controller tests assert that cross-user access returns `:not_found`:

```ruby
def test_他人のブックマークは参照できない
  sign_in user
  assert other_bookmark = Bookmark.where('user_id <> ?', user).first

  get bookmark_path(other_bookmark)
  assert_response :not_found
end
```

This pattern appears consistently across `bookmarks_controller_test.rb`, `feeds_controller_test.rb`, and `todos_controller_test.rb` for show, edit, update, and destroy actions.

## Coverage Gaps

- `test/integration/`, `test/system/`, `test/mailers/`, `test/helpers/` directories are empty (`.keep` only)
- No model tests exist for `Bookmark`, `User`, `Todo`, `Calendar`, `Portal`, `PortalLayout`, `BookmarkGadget`, `TodoGadget`
- `FeedTest` and `PreferenceTest` are the only model-level tests
- No tests for `WelcomeController` beyond what exists (portal state save is untested)
- No coverage enforcement threshold configured

---

*Testing analysis: 2026-04-27*
