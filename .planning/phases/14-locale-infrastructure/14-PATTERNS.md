# Phase 14: Locale Infrastructure - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 8 (1 new migration, 2 model changes, 1 config change, 1 new concern, 1 controller change, 1 layout change, 2 test files)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `db/migrate/<TS>_add_locale_to_preferences.rb` | migration | schema | `db/migrate/20131025030933_add_column_auth_user_on_feeds.rb` | exact |
| `app/models/preference.rb` | model | CRUD | `app/models/preference.rb` (existing lines 1-28) | exact |
| `config/application.rb` | config | request-response | `config/application.rb` (existing lines 27-35) | exact |
| `app/controllers/concerns/localization.rb` | concern | request-response | `app/models/concerns/gadget.rb` | role-match (concern pattern) |
| `app/controllers/application_controller.rb` | controller | request-response | `app/controllers/application_controller.rb` (existing lines 1-11) | exact |
| `app/views/layouts/application.html.erb` | layout | request-response | `app/views/layouts/application.html.erb` (existing line 2) | exact |
| `test/controllers/application_controller_test.rb` | test | request-response | `test/controllers/preferences_controller_test.rb` | exact (controller test pattern) |
| `test/models/preference_test.rb` | test | CRUD | `test/models/preference_test.rb` (existing lines 1-29) | exact |

---

## Pattern Assignments

### `db/migrate/<TS>_add_locale_to_preferences.rb` (migration, schema)

**Analog:** `db/migrate/20131025030933_add_column_auth_user_on_feeds.rb`

**Migration pattern** (add_column with explicit null: true):
```ruby
class AddLocaleToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :locale, :string, null: true
  end
end
```

**Reference pattern** (lines 1-13 of AddColumnAuthUserOnFeeds):
```ruby
class AddColumnAuthUserOnFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :auth_user, :string
    add_column :feeds, :auth_encrypted_password, :string
    add_column :feeds, :auth_salt, :string
  end

  def down
    remove_column :feeds, :auth_user
    remove_column :feeds, :auth_encrypted_password
    remove_column :feeds, :auth_salt
  end
end
```

**Notes:**
- Use `change` method (Rails 3.1+) for simple add_column; no need for explicit `up`/`down`
- `null: true` explicitly specified (D-02: no DB default)
- No default value clause

---

### `app/models/preference.rb` (model, CRUD)

**Analog:** `app/models/preference.rb` (existing, lines 1-28)

**Constants pattern** (lines 2-14):
```ruby
FONT_SIZE_LARGE = 'large'.freeze
FONT_SIZE_MEDIUM = 'medium'.freeze
FONT_SIZE_SMALL = 'small'.freeze
FONT_SIZES = [
  FONT_SIZE_LARGE,
  FONT_SIZE_MEDIUM,
  FONT_SIZE_SMALL
].freeze
```

**SUPPORTED_LOCALES constant to add** (follows same pattern):
```ruby
SUPPORTED_LOCALES = %w[ja en].freeze
```

**Validation pattern** (line 18):
```ruby
validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true
```

**Locale validation to add** (follows same pattern):
```ruby
validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
```

**default_preference method** (lines 20-26 — no change to this method):
```ruby
def self.default_preference(user)
  ret = self.new(user: user)
  ret.default_priority = Todo::PRIORITY_NORMAL
  ret.theme = "modern"
  ret.use_todo = true
  ret
end
```

**Notes:**
- `SUPPORTED_LOCALES` is the single source of truth (D-03)
- Position: insert SUPPORTED_LOCALES constant after FONT_SIZE_OPTIONS (line 14)
- Validation: add after existing font_size validation (after line 18)
- No change to `default_preference` — locale remains nil on new instances

---

### `config/application.rb` (config, request-response)

**Analog:** `config/application.rb` (existing lines 27-35)

**Existing I18n config** (lines 34-35):
```ruby
I18n.config.enforce_available_locales = true
config.i18n.default_locale = :ja
```

**Available locales to add** (insert after line 35):
```ruby
config.i18n.available_locales = %i[ja en]
```

**Notes:**
- Use inline literal `%i[ja en]` (not `Preference::SUPPORTED_LOCALES`) — Zeitwerk does not load models at boot time (RESEARCH.md Pitfall 1)
- Value matches Preference::SUPPORTED_LOCALES (two-source parallel literals)
- Comment clarifies relationship to model constant if desired

---

### `app/controllers/concerns/localization.rb` (concern, request-response)

**Analog:** `app/models/concerns/gadget.rb` (concern structure pattern)

**Concern shell pattern** (lines 1-3, 20):
```ruby
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  private
  # ... method definitions
end
```

**Core concern structure** (full implementation from RESEARCH.md):
```ruby
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  private

  def set_locale(&block)
    I18n.with_locale(resolved_locale, &block)
  end

  def resolved_locale
    [saved_locale, accept_language_match].each do |candidate|
      return candidate.to_sym if candidate && Preference::SUPPORTED_LOCALES.include?(candidate.to_s)
    end
    I18n.default_locale
  end

  def saved_locale
    return nil unless user_signed_in?
    current_user.preference&.locale
  end

  def accept_language_match
    parse_accept_language(request.env['HTTP_ACCEPT_LANGUAGE'])
  end

  def parse_accept_language(header)
    return nil if header.blank?
    header
      .split(',')
      .map { |entry|
        tag, q = entry.strip.split(';q=')
        q_value = q ? q.to_f : 1.0
        [tag.to_s.strip[0, 2], q_value]
      }
      .sort_by { |_, q| -q }
      .find { |tag, _| Preference::SUPPORTED_LOCALES.include?(tag) }
      &.first
  rescue
    nil
  end
end
```

**Key patterns:**
- `around_action :set_locale` wraps entire request (RESEARCH.md Pitfall 2: never use before_action for locale)
- `I18n.with_locale(resolved_locale) { yield }` is atomic, thread-safe pattern
- Whitelist guard `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` BEFORE any I18n.locale= (RESEARCH.md Pitfall 3)
- `parse_accept_language` returns nil on any error (Pitfall 4)
- `current_user.preference&.locale` safely handles new users with no persisted preference (Pitfall 5)

---

### `app/controllers/application_controller.rb` (controller, request-response)

**Analog:** `app/controllers/application_controller.rb` (existing lines 1-11)

**Current ApplicationController** (lines 1-11):
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
```

**Change: add include as first line** (insert after line 1):
```ruby
class ApplicationController < ActionController::Base
  include Localization
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  # ... rest unchanged
end
```

**Notes:**
- `include Localization` registers `around_action :set_locale` via concern's `included` block
- Position: first line after class declaration (before other callbacks, ensures locale wraps everything)
- No other changes to existing methods/callbacks

---

### `app/views/layouts/application.html.erb` (layout, request-response)

**Analog:** `app/views/layouts/application.html.erb` (existing line 2)

**Current layout line 2:**
```erb
<html>
```

**Change to:**
```erb
<html lang="<%= I18n.locale %>">
```

**Notes:**
- `I18n.locale` returns a Symbol (`:ja` or `:en`)
- ERB `<%= %>` automatically calls `.to_s`, so output is `lang="ja"` or `lang="en"` (string)
- Single change location; no other layout files need modification (Devise uses application.html.erb)

---

### `test/controllers/application_controller_test.rb` (test, request-response)

**Analog:** `test/controllers/preferences_controller_test.rb` (controller test pattern)

**Test structure** (from RESEARCH.md Code Examples section 3):
```ruby
require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest

  # Path 1: 保存済みlocaleが'en'のユーザは英語でレンダリングされる
  def test_保存済みlocaleがenのユーザは英語でレンダリングされる
    user.preference.update!(locale: 'en')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'html[lang=?]', 'en'
  end

  # Path 2: Accept-Languageが'en'のリクエストは英語でレンダリングされる
  def test_AcceptLanguageがenのリクエストは英語でレンダリングされる
    user.preference.update!(locale: nil)
    sign_in user
    get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
  end

  # Path 3: 無効なlocaleは無視されてデフォルトの日本語になる
  def test_無効なlocaleは無視されてデフォルトの日本語になる
    user.preference.update!(locale: nil)
    sign_in user
    get root_path, headers: { 'Accept-Language' => 'fr-FR,fr;q=0.9' }
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
  end

  # Path 4: locale未設定かつAcceptLanguage未指定の場合はデフォルト日本語
  def test_locale未設定かつAcceptLanguage未指定の場合はデフォルト日本語
    user.preference.update!(locale: nil)
    sign_in user
    get root_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
  end

end
```

**Test pattern elements** (from preferences_controller_test.rb lines 1-78):
```ruby
require 'test_helper'

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  # Tests use:
  # - user helper (from test/support/users.rb) returns User.first
  # - sign_in user (from Devise::Test::IntegrationHelpers included in test_helper.rb)
  # - get/patch with params and headers
  # - assert_response :success or :redirect
  # - assert_select to check HTML structure
```

**Key patterns:**
- Class name: `ApplicationControllerTest < ActionDispatch::IntegrationTest`
- Japanese test method names: `def test_保存済みlocaleがenのユーザは英語でレンダリングされる`
- `user.preference.update!(locale: 'en')` — modify fixture preference
- `sign_in user` — authenticate
- `get root_path, headers: { 'Accept-Language' => ... }` — set request headers
- `assert_select 'html[lang=?]', 'en'` — verify HTML attribute (VERI18N-01 requirement I18N-04)

---

### `test/models/preference_test.rb` (test, CRUD)

**Analog:** `test/models/preference_test.rb` (existing lines 1-29)

**Existing test file** (lines 1-29):
```ruby
require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase

  def test_デフォルトのユーザ設定
    p = Preference.default_preference(user)

    assert_equal Todo::PRIORITY_NORMAL, p.default_priority
    assert_equal true, p.use_todo?
    assert_nil p.font_size
  end

  def test_文字サイズは選択肢のみ有効
    p = Preference.default_preference(user)

    Preference::FONT_SIZES.each do |font_size|
      p.font_size = font_size
      assert p.valid?, "#{font_size} should be valid"
    end

    p.font_size = nil
    assert p.valid?, 'nil should fall back at render time'

    p.font_size = 'extra-large'
    assert_not p.valid?
  end

end
```

**Locale validation test to add** (follows same pattern as `test_文字サイズは選択肢のみ有効`, lines 13-26):
```ruby
def test_localeはsupported_localesのみ有効
  p = Preference.default_preference(user)

  Preference::SUPPORTED_LOCALES.each do |locale|
    p.locale = locale
    assert p.valid?, "#{locale} should be valid"
  end

  p.locale = nil
  assert p.valid?, 'nil locale should be valid (未指定を許可)'

  p.locale = 'fr'
  assert_not p.valid?, "'fr' should be invalid"

  p.locale = 'zh'
  assert_not p.valid?, "'zh' should be invalid"
end
```

**Notes:**
- Add new test method at end of PreferenceTest class (before final `end`)
- Japanese method name: `test_localeはsupported_localesのみ有効`
- Mirrors existing FONT_SIZES test structure exactly
- Tests valid locales (from SUPPORTED_LOCALES), nil (allowed), and invalid locales ('fr', 'zh')

---

## Shared Patterns

### Locale Whitelist Validation (All Files Reading/Writing Locale)

**Source:** `app/models/preference.rb` + `app/controllers/concerns/localization.rb`

**Apply to:** All locale-handling code (model validation + concern resolution)

**Pattern:**
```ruby
# Model write-time guard
validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true

# Controller read-time guard (resolution pipeline)
Preference::SUPPORTED_LOCALES.include?(candidate.to_s)  # check BEFORE I18n.with_locale
```

**Rationale:** Two-layer defense (D-04). Whitelist check must occur before any `I18n.locale=` or `I18n.with_locale` call (RESEARCH.md Pitfall 3).

### Test Data Helpers (Controller + Model Tests)

**Source:** `test/test_helper.rb` + `test/support/users.rb`

**Apply to:** All new tests

**Pattern** (lines 1-4 of test/support/users.rb):
```ruby
def user
  assert @_user ||= User.first
  @_user
end
```

**Usage in tests:**
```ruby
user.preference.update!(locale: 'en')  # Modify fixture
sign_in user                           # Authenticate
get root_path                          # Make request
assert_select 'html[lang=?]', 'en'    # Verify output
```

**Notes:**
- `user` helper returns fixture user 1 (memoized)
- `sign_in user` from `Devise::Test::IntegrationHelpers` (already included in test_helper.rb line 18)
- Fixtures are pre-loaded (test_helper.rb line 9: `fixtures :all`)

---

## No Analog Found

All 8 files have close analogs in the existing codebase. No files lack patterns to reference.

---

## Metadata

**Analog search scope:**
- `db/migrate/` — migration patterns
- `app/models/` — Preference model constants/validations
- `app/models/concerns/` — concern structure
- `app/controllers/` — ApplicationController structure
- `app/views/layouts/` — layout file
- `test/controllers/` — Minitest controller test patterns
- `test/models/` — Minitest model test patterns
- `test/support/` — test helpers
- `config/` — application configuration
- `test/test_helper.rb` — test infrastructure

**Files scanned:** 15+ codebase files read and analyzed

**Pattern extraction date:** 2026-05-01

**Key insights from analogs:**
1. **Preference model** (FONT_SIZES pattern) provides exact template for SUPPORTED_LOCALES constant and validation
2. **Migration patterns** show `change` method preferred over `up`/`down` in modern Rails
3. **Concern structure** (Gadget module) establishes Rails pattern for `extend ActiveSupport::Concern`
4. **Controller test structure** (PreferencesControllerTest) provides exact template for integration tests with `sign_in`, `get`, `assert_select`
5. **Test helper** (users.rb) provides `user` memoized helper for test data
6. **ApplicationController** shows minimal structure — only `protect_from_forgery`, `before_action :authenticate_user!`, and `configure_permitted_parameters`

---

