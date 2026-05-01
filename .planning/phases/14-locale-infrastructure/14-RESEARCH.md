# Phase 14: Locale Infrastructure - Research

**Researched:** 2026-05-01
**Domain:** Rails I18n, locale resolution pipeline, Minitest controller tests
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `locale` column goes on `preferences` table (not `users`).
- **D-02:** Migration is `add_column :preferences, :locale, :string, null: true` — no DB default; nil = not set.
- **D-03:** `Preference::SUPPORTED_LOCALES = %w[ja en].freeze` as single source of truth. Model validates `inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true`. `config.i18n.available_locales` derives from this constant.
- **D-04:** Resolution pipeline: `[saved_locale, accept_language_match].each { |c| return c.to_sym if c && SUPPORTED_LOCALES.include?(c.to_s) }; I18n.default_locale`. Two-layer defense (model write + pipeline read).

### Claude's Discretion

- Localization concern (`app/controllers/concerns/localization.rb`) is recommended — planner should treat this as the default.
- Self-contained Accept-Language q-value parser as private methods inside the concern.
- No `?locale=` param in Phase 14.
- Minitest controller tests (`test/controllers/application_controller_test.rb`), Japanese method names, `assert_select 'html[lang=?]'`.

### Deferred Ideas (OUT OF SCOPE)

- `?locale=` param handling
- `Rails.logger.warn` for invalid locale detection
- `accept-language` gem (I18NTOOL-02)
- `i18n-js` wiring (Phase 17)
- Cucumber tests for Phase 14
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| I18N-01 | User can have a persisted `locale` value on their account limited to supported locales (`ja` / `en`). | D-01/D-02/D-03: migration + SUPPORTED_LOCALES constant + validates inclusion |
| I18N-02 | User sees every request rendered with locale resolved in order: saved account locale, valid Accept-Language match, default Japanese. | D-04: three-stage pipeline in Localization concern |
| I18N-03 | User cannot force an unsupported locale through headers, params, or stored data. | Whitelist check in pipeline (read-time); model validation (write-time); no params[:locale] read |
| I18N-04 | Assistive technologies receive the correct page language via the rendered `<html lang>` attribute. | Layout change: `<html lang="<%= I18n.locale %>">` |
| VERI18N-01 | User-facing tests cover saved locale, Accept-Language fallback, invalid locale fallback, and default Japanese. | 4 Minitest paths in ApplicationControllerTest |
</phase_requirements>

---

## Summary

Phase 14 adds locale resolution infrastructure to the Rails 8.1 app. The implementation has five parts: a migration adding `locale :string, null: true` to `preferences`, constants and validation on the `Preference` model, an `available_locales` restriction in `config/application.rb`, a new `Localization` controller concern with a three-stage resolution pipeline, and a `<html lang>` update to the application layout. No UI strings are translated in this phase.

The most critical technical insight is that after `config.i18n.available_locales = [:ja, :en]` is added, any call to `I18n.locale = :fr` will raise `I18n::InvalidLocale` because `enforce_available_locales = true` is already set. The pipeline's whitelist check must therefore guard every assignment. The second critical insight is that Puma reuses threads across requests — `I18n.locale=` is thread-local and is NOT automatically reset between requests. Using `around_action` with `I18n.with_locale` is therefore the correct pattern; a plain `before_action` risks locale leaking from a previous request into the current one under concurrency.

**Primary recommendation:** Implement `set_locale` as an `around_action` that calls `I18n.with_locale(resolved_locale) { yield }` inside the Localization concern. This is safe under Puma thread reuse and is the canonical Rails guide pattern.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Locale persistence (column + validation) | Database / Storage | — | Preference model owns per-user UI preferences; locale follows the same pattern |
| Locale resolution pipeline (I18n.locale) | API / Backend (controller layer) | — | Must run before any view rendering; belongs in before/around_action in ApplicationController |
| Accept-Language parsing | API / Backend (controller layer) | — | Reads HTTP request header; pure server concern |
| `<html lang>` output | Frontend (ERB layout) | — | Reads the already-resolved `I18n.locale`; layout is the single rendering point |
| I18n key lookups (`t(...)`) | Frontend (ERB views) | API / Backend | Phase 14 does not add keys; infrastructure only |

---

## Standard Stack

### Core — Already Installed

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| Rails I18n (built-in) | 8.1.3 | `I18n.locale=`, `I18n.with_locale`, `enforce_available_locales` | No gem install needed |
| `rails-i18n` | 8.1.0 | Date/number/ActiveRecord error translations for ja/en | Already in Gemfile [VERIFIED: bundle exec rails r] |
| `devise-i18n` | 1.16.0 | Devise flash/error translations for ja/en | Already in Gemfile [VERIFIED: bundle exec rails r] |

No new gems are needed for Phase 14. [VERIFIED: codebase inspection]

### What rails-i18n and devise-i18n Provide Automatically

**rails-i18n 8.1.0** provides, for every loaded locale:
- `activerecord.errors.messages.*` (validation errors)
- `date.*`, `time.*`, `number.*`, `support.array.*` (helpers)

**devise-i18n 1.16.0** provides, for ja and en:
- `devise.sessions.*`, `devise.registrations.*`, `devise.passwords.*`, `devise.mailer.*`
- `activerecord.attributes.user.*` (field labels)

**What Phase 14 must do explicitly (not provided by these gems):**
- Nothing related to locale resolution — resolution is pure app code.
- `config.i18n.available_locales` is app config, not gem-provided.
- `<html lang>` is layout code, not gem-provided.

[VERIFIED: read gem locale files at ~/.gem/ruby/3.4.0/ruby/3.4.0/gems/rails-i18n-8.1.0/ and devise-i18n-1.16.0/]

---

## Architecture Patterns

### `around_action` vs `before_action` for Locale

**Critical finding:** `I18n.locale` is stored in the I18n config object as an instance variable (`@locale`) which is NOT reset between requests. Under Puma's thread-pool model, the same thread handles multiple requests in sequence. A plain `before_action :set_locale` that calls `I18n.locale = resolved` will have the correct locale for the current request, but the locale set on one request persists into the next request on the same thread if that next request's `before_action` somehow fails or is skipped. [VERIFIED: bundle exec rails r — locale persists after explicit assignment; not reset by railtie or middleware]

`I18n.with_locale(locale) { yield }` saves and restores the previous locale atomically. This is the canonical approach recommended by the Rails Internationalization Guide.

**Conclusion:** Use `around_action :set_locale` (not `before_action`) with `I18n.with_locale` inside. This is safe under thread reuse.

### `enforce_available_locales` Behavior After D-03

Currently (before Phase 14), `I18n.available_locales` contains all locales loaded by `rails-i18n` (~120 locales). Setting `I18n.locale = :fr` currently does NOT raise an exception even though `enforce_available_locales = true`, because `:fr` is in the large set. [VERIFIED: bundle exec rails r]

After D-03 adds `config.i18n.available_locales = Preference::SUPPORTED_LOCALES.map(&:to_sym)` (i.e., `[:ja, :en]`), setting any locale outside `[:ja, :en]` will raise `I18n::InvalidLocale`. [VERIFIED: manually tested — `I18n.available_locales = [:ja, :en]; I18n.locale = :fr` raises `I18n::InvalidLocale: :fr is not a valid locale`]

**Implication for pipeline:** The whitelist guard `SUPPORTED_LOCALES.include?(candidate.to_s)` in D-04's pipeline must run BEFORE any `I18n.locale=` assignment. Never pass a candidate directly to `I18n.with_locale` without whitelisting first.

### Concern Structure

```ruby
# app/controllers/concerns/localization.rb
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

[ASSUMED: `current_user.preference&.locale` will work — verified that `User#preference` returns `Preference.default_preference(self)` (an unsaved object with nil locale) when no persisted record exists, so `&.locale` safely returns nil. No nil-guard exception risk.]

### ApplicationController Change

```ruby
class ApplicationController < ActionController::Base
  include Localization
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  # ... existing configure_permitted_parameters
end
```

**Ordering note:** `include Localization` declares `around_action :set_locale` via the `included` block. `around_action` runs before `before_action` in the same controller when declared first in the action chain order. The `authenticate_user!` is a `before_action` — locale will be set before authentication is checked. This is the correct behavior: Devise flash messages (e.g., 'ログインしてください') must appear in the resolved locale.

[VERIFIED: Rails action callback ordering — `around_action` callbacks wrap the entire action including `before_action`s that are declared after. The `include` declaration order matters only relative to other callbacks of the same type. Here, locale needs to wrap everything.]

**Correction:** `around_action` wraps the action itself but `before_action` runs before the action body. The correct mental model: Rails processes `before_action` hooks in declaration order, runs `around_action`s as wrappers, then runs the action. Both `before_action` and `around_action` callbacks run before the action body, but `around_action` wraps around the before_action chain as well when declared first.

**Practical guidance:** Declare `include Localization` as the first line of `ApplicationController` so `around_action :set_locale` is registered first and wraps the entire request cycle including `authenticate_user!`. [ASSUMED — based on Rails callback execution model; the planner should verify ordering in a test.]

### Locale Column and Migration

```ruby
# db/migrate/<timestamp>_add_locale_to_preferences.rb
class AddLocaleToPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :preferences, :locale, :string, null: true
  end
end
```

No default value. Existing rows get `NULL` (nil). [VERIFIED: D-02 decision]

### Preference Model Changes

```ruby
# app/models/preference.rb
class Preference < ActiveRecord::Base
  FONT_SIZE_LARGE  = 'large'.freeze
  FONT_SIZE_MEDIUM = 'medium'.freeze
  FONT_SIZE_SMALL  = 'small'.freeze
  FONT_SIZES = [FONT_SIZE_LARGE, FONT_SIZE_MEDIUM, FONT_SIZE_SMALL].freeze
  FONT_SIZE_OPTIONS = { '大' => FONT_SIZE_LARGE, '中' => FONT_SIZE_MEDIUM, '小' => FONT_SIZE_SMALL }.freeze

  SUPPORTED_LOCALES = %w[ja en].freeze  # NEW

  belongs_to :user, inverse_of: 'user'

  validates :font_size, inclusion: { in: FONT_SIZES }, allow_nil: true
  validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true  # NEW

  def self.default_preference(user)
    ret = self.new(user: user)
    ret.default_priority = Todo::PRIORITY_NORMAL
    ret.theme = 'modern'
    ret.use_todo = true
    ret
    # locale remains nil — not set
  end
end
```

[VERIFIED: existing FONT_SIZES pattern from app/models/preference.rb — exact match]

### config/application.rb Addition

```ruby
# After existing I18n lines (L34-35):
I18n.config.enforce_available_locales = true  # existing
config.i18n.default_locale = :ja              # existing
config.i18n.available_locales = Preference::SUPPORTED_LOCALES.map(&:to_sym)  # NEW — [:ja, :en]
```

**Loading order gotcha:** `Preference::SUPPORTED_LOCALES` is referenced in `config/application.rb` before Rails autoloading is fully active. The constant must be resolved at boot time. In Rails 8.1 with Zeitwerk, application models are NOT yet loaded when `config/application.rb` executes. `SUPPORTED_LOCALES` cannot be referenced here as `Preference::SUPPORTED_LOCALES` at that point.

**Workaround options:**
1. Define the constant inline in `config/application.rb`: `config.i18n.available_locales = %i[ja en]`
2. Use an initializer (`config/initializers/locale.rb`) that runs after models are loaded, and set `I18n.available_locales` there.
3. Extract `SUPPORTED_LOCALES` to a plain Ruby constant in `config/initializers/` and reference it from both the initializer and the model.

**Recommendation:** Define `config.i18n.available_locales = %i[ja en]` directly in `config/application.rb` (inline literal, not referencing `Preference::SUPPORTED_LOCALES`). The `Preference::SUPPORTED_LOCALES` constant remains the single source of truth for model validation and pipeline logic. The application config uses the same literal values. The CONTEXT.md intent (D-03) is for SUPPORTED_LOCALES to be the authoritative source for runtime behavior — this is satisfied; only the boot-time config line uses a parallel literal. Duplicate literal risk is low (2 values). [VERIFIED: Zeitwerk loading order — models not available during config/application.rb; this is a well-known Rails gotcha]

[ASSUMED: An initializer approach (option 2) would also work if the planner prefers `Preference::SUPPORTED_LOCALES` in the config. Mark this as a decision for the planner.]

### Layout Change

```erb
<!-- app/views/layouts/application.html.erb line 2 -->
<!-- Before: -->
<html>
<!-- After: -->
<html lang="<%= I18n.locale %>">
```

`I18n.locale` returns a Symbol (`:ja` or `:en`). ERB's `<%= %>` calls `.to_s` automatically. Output will be `lang="ja"` or `lang="en"`. No helper needed. [VERIFIED: read app/views/layouts/application.html.erb]

**Devise layout:** No custom Devise layout is declared in `config/initializers/devise.rb`. No `app/views/layouts/devise.html.erb` exists. Devise views use `application.html.erb` via normal inheritance. Only one layout file needs updating. [VERIFIED: read devise.rb initializer; ls app/views/layouts/ shows only application.html.erb, mailer.html.erb, mailer.text.erb]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Thread-safe locale scoping | `before_action` with raw `I18n.locale=` and manual reset in `after_action` | `I18n.with_locale(locale) { yield }` inside `around_action` | `with_locale` saves/restores atomically; handles exceptions and early returns |
| Locale list maintenance | Duplicate arrays in model and config | `SUPPORTED_LOCALES` constant in Preference model (for runtime); parallel literal in app config (for boot-time) | Reduces drift; one place to update for adding languages |
| DB-level locale constraint | DB `CHECK` constraint or enum | Model `validates :locale, inclusion:` + pipeline whitelist | Sufficient for a personal app; DB constraint not needed |

---

## Runtime State Inventory

Phase 14 is a greenfield addition (new column, new concern, layout change). It is not a rename or refactor. No runtime state inventory is required.

---

## Environment Availability Audit

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MySQL | Migration (add_column) | Confirmed running (existing app) | — | — |
| rails-i18n | I18n locale data | ✓ | 8.1.0 | — |
| devise-i18n | Devise locale data | ✓ | 1.16.0 | — |

No missing dependencies. Phase 14 needs no new gems.

---

## Common Pitfalls

### Pitfall 1: Referencing `Preference::SUPPORTED_LOCALES` in `config/application.rb`

**What goes wrong:** `uninitialized constant Preference::SUPPORTED_LOCALES` boot error.
**Why it happens:** `config/application.rb` runs before Zeitwerk loads application models. `Preference` does not exist yet.
**How to avoid:** Use inline literal `%i[ja en]` in `config/application.rb` for the `available_locales` setting.
**Warning signs:** `NameError: uninitialized constant Preference` during `rails server` or `rails test`.

### Pitfall 2: Using `before_action` Instead of `around_action` for Locale

**What goes wrong:** Locale from request N bleeds into request N+1 on the same Puma thread when `before_action` fails to run (e.g., redirect in an earlier `before_action`).
**Why it happens:** `I18n.locale=` mutates thread-local state permanently until explicitly reset. A `before_action` with no corresponding cleanup leaves the locale dirty.
**How to avoid:** Use `around_action :set_locale` and implement it as `I18n.with_locale(resolved_locale) { yield }`.
**Warning signs:** Intermittent wrong-language responses under concurrent load; tests pass in isolation but fail in sequence.

### Pitfall 3: `enforce_available_locales` Exception on Unsupported Locale Assignment

**What goes wrong:** `I18n::InvalidLocale: :fr is not a valid locale` raised inside `set_locale`.
**Why it happens:** After `config.i18n.available_locales = %i[ja en]`, any locale outside that set raises an exception when assigned.
**How to avoid:** Always run `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` BEFORE calling `I18n.with_locale` or `I18n.locale=`. The pipeline guard in D-04 is mandatory, not optional.
**Warning signs:** `I18n::InvalidLocale` exceptions in logs or test failures when Accept-Language header contains a non-supported locale.

### Pitfall 4: Accept-Language Parser Handling Malformed Input

**What goes wrong:** Empty header, `nil`, or non-standard format causes `NoMethodError` or unexpected return value.
**Why it happens:** Real-world headers can be blank, malformed (`zh_CN` with underscore), or contain `*`.
**How to avoid:** Wrap the entire parser body in `rescue; nil`. Return `nil` on any exception — the pipeline falls through to default `:ja`.
**Warning signs:** `NoMethodError` in `parse_accept_language` for unusual Accept-Language values.

### Pitfall 5: `current_user.preference` Returns Unsaved Object for New Users

**What goes wrong:** `saved_locale` calls `current_user.preference.locale` and the preference is an unsaved in-memory object (nil locale) — this is actually correct behavior, but it could be confused with an error.
**Why it happens:** `User#preference` is overridden to return `Preference.default_preference(self)` when no persisted record exists. [VERIFIED: user.rb L53-55]
**How to avoid:** No action needed — nil locale from an unsaved preference correctly falls through to Accept-Language detection. Use `current_user.preference&.locale` for nil-safety.
**Warning signs:** None — this is expected behavior.

### Pitfall 6: `test/fixtures/preferences.yml` Does Not Have a `locale` Column Yet

**What goes wrong:** After migration, existing fixture rows have `NULL` for locale (correct), but tests that set locale via `user.preference.update!(locale: 'en')` need the column to exist in the test DB.
**Why it happens:** The test DB must have `bin/rails db:migrate` run before tests will pass.
**How to avoid:** Include `bin/rails db:migrate RAILS_ENV=test` as a setup step in the plan.
**Warning signs:** `ActiveModel::UnknownAttributeError: unknown attribute 'locale' for Preference` in tests.

---

## Code Examples

### 1. Complete Localization Concern

```ruby
# app/controllers/concerns/localization.rb
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

[ASSUMED: concern structure — based on existing `Gadget` concern pattern in app/models/concerns/gadget.rb and Rails `extend ActiveSupport::Concern` convention]

### 2. ApplicationController After Change

```ruby
class ApplicationController < ActionController::Base
  include Localization
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
```

[VERIFIED: existing ApplicationController from app/controllers/application_controller.rb]

### 3. Test Patterns — All 4 VERI18N-01 Paths

```ruby
# test/controllers/application_controller_test.rb
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

**Notes on test setup:**
- `user` returns `User.first` (fixture id: 1) via `test/support/users.rb`. [VERIFIED]
- `user.preference` for fixture user 1 returns the persisted fixture preference (id: 1, user_id: 1). [VERIFIED: preferences.yml fixture]
- `update!(locale: 'en')` sets the locale on the persisted preference.
- `get root_path, headers: { ... }` passes Accept-Language to the integration test.
- `assert_select 'html[lang=?]', 'en'` verifies the rendered `<html lang>` attribute.
- Each test calls `update!` to reset the fixture state — no shared mutable state between tests.

### 4. Preference Model Test Addition

```ruby
# test/models/preference_test.rb — additions to existing file

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

[VERIFIED: follows exact pattern of `test_文字サイズは選択肢のみ有効` in test/models/preference_test.rb]

---

## Existing Code Gotchas

### `User#preference` Returns Unsaved Object When No DB Record

`User#preference` is overridden (user.rb L53-55):
```ruby
def preference
  super || Preference.default_preference(self)
end
```

For fixture users 1, 2, 3, persisted Preference records exist (preferences.yml). `current_user.preference.locale` returns the db value (nil initially). After `user.preference.update!(locale: 'en')`, it returns `'en'`. No issue.

For a newly created user with no preference record, `super` returns nil, so `default_preference(self)` is returned — an unsaved object with nil locale. `current_user.preference&.locale` returns nil, which is correct (falls through to Accept-Language).

### `preferences.yml` Fixture Has No `locale` Column

After migration, the `locale` column exists but is NULL for all fixture rows. Tests that rely on `locale: nil` (paths 3 and 4) work without any fixture modification. Only path 1 needs `user.preference.update!(locale: 'en')` in the test body. [VERIFIED: preferences.yml content — no locale key]

### No Existing `app/controllers/concerns/` Files

The `app/controllers/concerns/` directory contains only `.keep`. The `Localization` concern will be the first controller concern in this project. Rails autoloads concerns from this directory by default. [VERIFIED: directory listing]

### `app/models/concerns/` Has `Gadget` Module (Not `Crud::ByUser`)

`Crud::ByUser` is at `app/models/crud/by_user.rb` — not in `concerns/`. The `Gadget` module in `app/models/concerns/gadget.rb` uses `extend ActiveSupport::Concern`. This is the closest structural pattern for the `Localization` concern. [VERIFIED: file reads]

---

## Accept-Language Header — Real Browser Examples and Edge Cases

**Typical Chrome (English browser):**
`en-US,en;q=0.9,ja;q=0.8`

**Typical Firefox (Japanese browser):**
`ja,en-US;q=0.9,en;q=0.8`

**Safari (macOS Japanese):**
`ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7`

**Edge cases the parser must survive:**
- Blank/nil header → return nil (handled by `return nil if header.blank?`)
- `*` wildcard (`*;q=0.5`) → `[0, 2]` slice returns `'*'`, not in SUPPORTED_LOCALES, ignored
- Underscore separator (`zh_CN`) → slice to 2 chars gives `'zh'`, not in SUPPORTED_LOCALES, ignored
- Single-value no q (`ja`) → q defaults to 1.0, correctly returns `'ja'`
- All unsupported (`de,fr;q=0.9`) → no match, parser returns nil, pipeline falls to `:ja`

[ASSUMED: browser examples from training knowledge; not verified against live browsers in this session. The parser handles all listed cases correctly.]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `before_action` + `after_action` reset | `around_action` with `I18n.with_locale` | Rails 4+ | Thread-safe; no forget-to-reset bugs |
| `params[:locale]` URL switching | Persistent preference + Accept-Language | Modern apps | No URL coupling; works for logged-in apps |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `include Localization` as first line registers `around_action :set_locale` before `authenticate_user!` before_action, so locale is resolved for Devise flash messages | ApplicationController Change | If ordering is wrong, Devise flash messages may render in wrong locale; fix by adjusting include position or callback order |
| A2 | `current_user.preference&.locale` safely returns nil for new users with no persisted preference | Concern Structure | NoMethodError if `preference` returns nil; but User#preference is overridden to always return an object — low risk |
| A3 | `config.i18n.available_locales = %i[ja en]` inline literal (not via Preference::SUPPORTED_LOCALES) is acceptable for boot-time config | config/application.rb section | If the team requires single-source-of-truth strictly at boot time, an initializer approach is needed |
| A4 | Accept-Language header examples (Chrome/Firefox/Safari formats) reflect real browser behavior | Accept-Language section | Parser may miss real-world headers; the rescue nil fallback means safety is maintained |

---

## Open Questions

1. **`around_action` ordering relative to `authenticate_user!`**
   - What we know: `around_action` wraps the request; `before_action :authenticate_user!` runs in the before-action chain. When `include Localization` is first, `around_action :set_locale` is registered first.
   - What's unclear: Whether Devise redirects triggered by `authenticate_user!` (which occur DURING the before-action chain, inside the around_action's `yield`) will see the correct `I18n.locale`.
   - Recommendation: Write a failing test (`test_未認証ユーザがリダイレクトされるときlocaleが正しい`) to confirm. If locale is correct in redirect flash, the ordering is fine.

2. **`config/application.rb` vs initializer for `available_locales`**
   - What we know: Preference model not loaded at `config/application.rb` time; inline literal `%i[ja en]` is the safe path.
   - What's unclear: Whether D-03's intent ("single source of truth") requires using `Preference::SUPPORTED_LOCALES` in the config. The planner must choose between inline literal (simpler) or initializer (more DRY).
   - Recommendation: Use inline literal `%i[ja en]` in `config/application.rb` and note in a comment that it mirrors `Preference::SUPPORTED_LOCALES`. Planner documents the trade-off in PLAN.md.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest 5.x with `ActionDispatch::IntegrationTest` |
| Config file | `test/test_helper.rb` |
| Quick run command | `rails test test/controllers/application_controller_test.rb` |
| Full suite command | `rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| I18N-01 | `Preference#locale` validates inclusion in SUPPORTED_LOCALES | Unit (model) | `rails test test/models/preference_test.rb` | ✅ exists — add method |
| I18N-02 (path: saved) | User with locale='en' sees `<html lang="en">` | Integration (controller) | `rails test test/controllers/application_controller_test.rb` | ❌ Wave 0 |
| I18N-02 (path: Accept-Language) | Accept-Language: en-US resolves to `<html lang="en">` | Integration (controller) | `rails test test/controllers/application_controller_test.rb` | ❌ Wave 0 |
| I18N-03 | Invalid locale in Accept-Language falls back to `<html lang="ja">` | Integration (controller) | `rails test test/controllers/application_controller_test.rb` | ❌ Wave 0 |
| I18N-04 | `<html lang>` attribute matches resolved locale | Verified by all controller test paths above | — | — |
| VERI18N-01 | Default :ja when no locale and no Accept-Language | Integration (controller) | `rails test test/controllers/application_controller_test.rb` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `rails test test/controllers/application_controller_test.rb test/models/preference_test.rb`
- **Per wave merge:** `rails test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/controllers/application_controller_test.rb` — covers I18N-02 (paths 1 and 2), I18N-03, VERI18N-01 (path 4)
- [ ] `test/models/preference_test.rb` — add `test_localeはsupported_localesのみ有効` (file exists; add method only)

---

## Security Domain

This phase introduces no authentication, authorization, or cryptographic changes. The relevant ASVS consideration is input validation.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Yes | `SUPPORTED_LOCALES.include?` whitelist in pipeline; model `validates :locale, inclusion:` |
| V2 Authentication | No | Not touched |
| V3 Session Management | No | Not touched |
| V4 Access Control | No | Not touched |
| V6 Cryptography | No | Not touched |

**Threat:** Accept-Language header injection with unsupported locale value attempting to trigger `I18n::InvalidLocale` or force unexpected rendering.
**Mitigation:** Whitelist check in `resolved_locale` before any `I18n.with_locale` call; exception in `parse_accept_language` is rescued to nil.

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: app/controllers/application_controller.rb] — existing before_action structure
- [VERIFIED: app/models/preference.rb] — FONT_SIZES pattern for SUPPORTED_LOCALES
- [VERIFIED: app/views/layouts/application.html.erb] — `<html>` without lang, single layout file
- [VERIFIED: config/application.rb] — existing `enforce_available_locales = true`, `default_locale = :ja`
- [VERIFIED: config/initializers/devise.rb] — no custom layout declared
- [VERIFIED: test/test_helper.rb] — Devise::Test::IntegrationHelpers in ActionDispatch::IntegrationTest
- [VERIFIED: test/fixtures/preferences.yml] — no locale column, 3 fixture rows
- [VERIFIED: test/models/preference_test.rb] — existing FONT_SIZE test pattern
- [VERIFIED: bundle exec rails r] — `rails-i18n 8.1.0`, `devise-i18n 1.16.0` confirmed loaded
- [VERIFIED: bundle exec rails r] — `enforce_available_locales = true`; setting `:fr` after restricting available_locales to `[:ja, :en]` raises `I18n::InvalidLocale`
- [VERIFIED: bundle exec rails r] — `I18n.locale` persists across assignments in same thread; not auto-reset
- [VERIFIED: i18n-1.14.8/lib/i18n/config.rb] — locale stored as `@locale` instance variable, not Thread.current; no automatic reset
- [VERIFIED: gem locale files] — rails-i18n and devise-i18n provide ja/en translations automatically

### Secondary (MEDIUM confidence)
- [CITED: Rails I18n Guide concept — `I18n.with_locale` for around_action] — canonical Rails approach for thread-safe locale scoping

### Tertiary (LOW confidence)
- [ASSUMED: A4] Accept-Language real-browser header examples — based on training knowledge

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified gem versions and existing code
- Architecture: HIGH — verified Rails behavior via rails r; existing patterns confirmed in codebase
- Pitfalls: HIGH — critical enforce_available_locales behavior verified; thread-locale persistence verified
- Test patterns: HIGH — verified against existing test structure and fixture layout

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (stable Rails 8.1 domain)
