# Testing Patterns

**Analysis Date:** 2026-05-23

## Test Frameworks

| Suite | Framework | Run Command |
|-------|-----------|-------------|
| Unit + Integration | Minitest 5.x | `bin/rails test` |
| E2E / Browser | Cucumber + Capybara + Selenium | `bundle exec rake dad:test` |
| Lint | ESLint | `yarn run lint` |

**Full local gate (all three must pass):**
```bash
yarn run lint && bin/rails test && bundle exec rake dad:test
```

**Key gems (`Gemfile`):**
- `minitest ~> 5.0` + `minitest-reporters`
- `cucumber` + `cucumber-rails`
- `capybara` + `selenium-webdriver`
- `webmock` (HTTP stubbing for Minitest + Cucumber)
- `simplecov` (coverage, `require: false` — not auto-loaded)
- `database_cleaner` (present but minimal use; DB state between Cucumber scenarios is managed via explicit `Before` hooks)

## Run Commands

```bash
bin/rails test                    # All Minitest suites (models, controllers, assets, i18n, services)
bin/rails test test/models/       # One subdirectory
bin/rails test test/models/preference_test.rb  # One file
bundle exec rake dad:test         # Cucumber E2E (spawns Rails server + headless Chrome automatically)
# DO NOT use: bundle exec cucumber  (missing server setup)
yarn run lint                     # ESLint on app/assets/javascripts/**/*.js
yarn run lint:fix                 # ESLint auto-fix
yarn run format                   # Prettier write
```

## Test File Organization

```
test/
├── test_helper.rb                # Base setup: fixtures, Devise helpers, support files
├── support/                      # Shared helper methods (class_eval'd into ActiveSupport::TestCase)
│   ├── bookmarks.rb              # bookmark(), bookmark_params(), folder_params()
│   ├── feeds.rb                  # feed_of()
│   ├── mastodon_accounts.rb
│   ├── preferences.rb            # preference_params()
│   ├── users.rb                  # user() → User.first
│   └── webmock.rb                # WebMock setup, RSS feed stubs
├── fixtures/                     # YAML fixtures for all models
│   ├── users.yml
│   ├── bookmarks.yml
│   ├── preferences.yml
│   ├── portals.yml
│   ├── todos.yml
│   ├── notes.yml
│   ├── feeds.yml
│   └── mastodon_accounts.yml
├── models/                       # ActiveSupport::TestCase
├── controllers/                  # ActionDispatch::IntegrationTest
│   └── welcome_controller/       # Subdirectory grouping for complex controllers
├── assets/                       # Contract tests for JS/CSS source (no browser)
├── services/                     # Tests for app/services/ classes
├── i18n/                         # Locale parity and i18n smoke tests
├── helpers/                      # ActionView::TestCase for helpers
└── system/                       # (empty — system tests not in use)

features/
├── 01.ブックマーク.feature        # Cucumber scenarios (Japanese)
├── 02.タスク.feature
├── 03.モダンテーマ.feature
├── 04.ノート.feature
├── 05.Mastodon.feature
├── 06.X.feature
├── 07.設定.feature
├── step_definitions/             # Step implementation (.rb files, Japanese regex)
│   ├── bookmarks.rb
│   ├── preferences.rb
│   └── ...
└── support/
    ├── env.rb                    # require 'daddy/cucumber/rails'
    ├── hooks.rb                  # Before/After hooks (preference reset, WebMock stubs)
    ├── login.rb                  # Login module (World-mixed)
    ├── test_support.rb           # Loads test/support/*.rb into Cucumber World
    └── window_resize.rb          # Browser window helpers + @mobile_portal tag hook
```

## Test Helper Setup

**`test/test_helper.rb`:**
```ruby
require 'daddy/test_help'
# ...
class ActiveSupport::TestCase
  fixtures :all
  Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |f|
    self.class_eval File.read(f)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

All files in `test/support/` are `class_eval`'d into `ActiveSupport::TestCase`, making their methods available globally in all Minitest tests.

**Cucumber World modules (`features/support/`):**
- `Login` module — mixed in via `World(Login)`, provides `sign_in(user)` and `current_user`
- `TestSupport` module — loads all `test/support/*.rb` files, providing `user`, `bookmark`, `preference_params`, etc. in step definitions

## Fixture Patterns

Fixtures use YAML with explicit `id:` values for fixtures that need stable IDs (user `1`, `2`, `3`), and named fixtures for association lookups:

```yaml
# test/fixtures/users.yml
1:
  id: 1
  email: user@example.com
  encrypted_password: $2a$10$...   # pre-hashed, password is "testtest"
  otp_secret: KCWJDXNH2EJIHB7NUZL42TFZYDRWERPB
  otp_required_for_login: false

twitter_user:
  email: dummy_00000000-0000-0000-0000-000000000001@example.com
  x_user_name: twitter_test_user
  provider: twitter2
  uid: fixture_twitter_uid
  oauth2_token: fixture_oauth2_token  # plain text — support_unencrypted_data: true in test.rb
```

**Important:** Fixtures bypass ActiveRecord callbacks and encryption. `config/environments/test.rb` sets `config.active_record.encryption.support_unencrypted_data = true` so fixture plain-text values are readable alongside encrypted values.

**Primary test user:** `user` helper method returns `User.first` (fixture id: 1, email: `user@example.com`, password: `testtest`).

**Accessing named fixtures in model tests:**
```ruby
u = users(:twitter_user)   # standard Rails fixture accessor
```

## Common Minitest Patterns

**Controller (integration) test structure:**
```ruby
require 'test_helper'

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def test_一覧
    sign_in user           # Devise helper — signs in User.first
    get bookmarks_path
    assert_response :success
    assert_equal '/bookmarks', path
  end

  def test_他人のブックマークは参照できない
    sign_in user
    assert other_bookmark = Bookmark.where('user_id <> ?', user).first
    get bookmark_path(other_bookmark)
    assert_response :not_found
  end
end
```

**Model test structure:**
```ruby
require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  def test_文字サイズは選択肢のみ有効
    p = Preference.default_preference(user)
    Preference::FONT_SIZES.each do |font_size|
      p.font_size = font_size
      assert p.valid?, "#{font_size} should be valid"
    end
    p.font_size = 'extra-large'
    assert_not p.valid?
  end
end
```

**Asset contract test structure** (no browser — reads source file directly):
```ruby
require 'test_helper'

class PortalLazyJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_lazy.js').read
  end

  test 'window.portalLazy namespace is declared at top level' do
    assert_includes @source, 'window.portalLazy = window.portalLazy || {};'
  end
end
```

Both `def test_name` and `test 'description' do` syntaxes are used. Domain tests prefer `def test_<日本語>`, contract/regression tests often use `test 'English description' do`.

## Mocking and HTTP Stubbing

**WebMock** (`test/support/webmock.rb`):
```ruby
WebMock.disable_net_connect!(allow_localhost: true)
# allow_localhost: true permits Capybara's embedded Puma + Selenium ChromeDriver

# Pre-stub fixture feed URLs:
WebMock.stub_request(:get, /slashdot/).to_return(status: 200, body: STUB_RSS_BODY, ...)
```

**Faraday test adapter** (for service tests — no WebMock needed):
```ruby
stubs = Faraday::Adapter::Test::Stubs.new
stubs.get(%r{/2/users/\w+/following}) { [200, {'Content-Type' => 'application/json'}, body.to_json] }
conn = Faraday.new { |f| f.adapter :test, stubs }
result = XClient.new(connection: conn).fetch_following(user: users(:twitter_user))
```

**Singleton method injection** (for Faraday.new in controllers — see `BookmarksControllerTest`):
```ruby
def with_faraday_new(fake_conn)
  singleton = Faraday.singleton_class
  singleton.send(:alias_method, :__bookmarks_test_original_new, :new)
  singleton.send(:define_method, :new) { |*_args, &_block| fake_conn }
  yield
ensure
  singleton.send(:alias_method, :new, :__bookmarks_test_original_new)
  singleton.send(:remove_method, :__bookmarks_test_original_new)
end
```

**Cleanup in tests with side effects:** Use `ensure` blocks to restore state:
```ruby
def test_twitter_from_omniauth_creates_user
  # ...
ensure
  User.where(uid: 'brand-new-uid-999', provider: 'twitter').delete_all
end
```

## Cucumber Patterns

**Feature files:** Written in Japanese with `# language: ja` header. Numbered by domain area (e.g., `01.ブックマーク.feature`).

**Step definitions:** Japanese regex with `もし` (Given/When), `ならば` (Then):
```ruby
もし /^ブックマーク管理画面を開き、ブックマーク追加用のアイコンをクリックします。$/ do
  sign_in user
  visit bookmarks_path
  find('a.breadcrumbs-action-btn[title="ブックマークを追加"]').click
end
```

**`capture` helper:** Called at the end of most step definitions — takes a screenshot saved to `features/reports/images/`.

**`Before` hook** (runs before every scenario, resets preference state):
```ruby
Before do
  Capybara.reset_sessions!
  instance_variable_set(:@_current_user, nil)
  MastodonAccount.delete_all
  XAccount.delete_all
  pref = user.preference
  pref.update!(theme: "modern", use_note: false, use_todo: false,
               use_calendar: true, locale: "ja", portal_column_count: 3)
end
```

**Tagged hooks** for optional feature setup:
```ruby
Before('@mastodon_gadget') do
  MastodonAccount.create!(...)
  @_mastodon_stub_lookup = WebMock.stub_request(:get, /ruby\.social\/.../).to_return(...)
end

After('@mastodon_gadget') do
  WebMock.remove_request_stub(@_mastodon_stub_lookup) if @_mastodon_stub_lookup
end
```

Available Cucumber tags: `@mastodon_gadget`, `@x_gadget`, `@mobile_portal`

**Login in Cucumber:** `sign_in user` (from `Login` module) — visits `/users/sign_in`, fills credentials, handles 2FA TOTP if enabled. Password for fixture users is always `testtest`.

**Window resizing for mobile tests:**
```ruby
Before('@mobile_portal') { resize_browser_window(390, 844) }
After('@mobile_portal')  { resize_browser_window(1280, 800) }
```

## Known Flakiness

`bundle exec rake dad:test` exhibits intermittent scenario-order-dependent failures:

- **Root cause:** Scenarios share DB state. The `Before` hook resets the fixture user's preference, but the reset was not always present historically, and state from one scenario can affect another.
- **Specific symptoms seen:** `Unable to find checkbox "タスクを表示する"`, missing `.todo_actions` on `/`, missing `#notes-tab-panel`.
- **Mitigation:** Re-run once on failure. A consistent failure across two runs is a real regression. A failure that disappears on re-run is a known pre-existing flake.
- **Current fix:** The `Before` hook in `features/support/hooks.rb` explicitly resets `use_note`, `use_todo`, `theme`, `locale`, and `portal_column_count` before each scenario.

## Test Types by Directory

| Directory | Base Class | Purpose |
|-----------|-----------|---------|
| `test/models/` | `ActiveSupport::TestCase` | Model validations, business logic |
| `test/controllers/` | `ActionDispatch::IntegrationTest` | HTTP request/response, HTML assertions |
| `test/assets/` | `ActiveSupport::TestCase` | CSS/JS source contract tests (regex on source files) |
| `test/services/` | `ActiveSupport::TestCase` | Service classes with Faraday stubs |
| `test/i18n/` | `ActiveSupport::TestCase` | Locale key parity, translation smoke tests |
| `test/helpers/` | `ActionView::TestCase` | View helpers |
| `features/` | Cucumber + Capybara | Full E2E browser tests |

## Coverage

`simplecov` gem is present (`require: false`) but not auto-loaded. No coverage enforcement configured. Run manually if needed by requiring simplecov before test_helper.

---

*Testing analysis: 2026-05-23*
