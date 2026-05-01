# Phase 18: Auth, 2FA & Translation Verification - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 7
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `app/views/layouts/application.html.erb` | layout/view | request-response | itself (modify in place) | exact |
| `config/locales/ja.yml` | config/i18n | — | itself (modify in place) | exact |
| `config/locales/en.yml` | config/i18n | — | itself (modify in place) | exact |
| `test/controllers/sessions_controller_test.rb` | test (new file) | request-response | `test/controllers/application_controller_test.rb` | exact |
| `test/controllers/two_factor_authentication_controller_test.rb` | test (extend) | request-response | itself (extend in place) | exact |
| `test/i18n/locales_parity_test.rb` | test (verify only) | — | itself (no changes needed) | exact |
| `app/assets/stylesheets/common.css.scss` | stylesheet | — | itself (modify in place) | exact |

---

## Pattern Assignments

### `app/views/layouts/application.html.erb` (layout, request-response)

**Analog:** itself — `app/views/layouts/application.html.erb`

**Existing flash[:notice] pattern** (lines 30-32):
```erb
<% if flash[:notice].present? %>
  <div class="flash-notice"><%= flash[:notice] %></div>
<% end %>
```

**Addition required — flash[:alert] block (insert after line 32, before `<%= yield %>`):**
```erb
<% if flash[:alert].present? %>
  <div class="flash-alert"><%= flash[:alert] %></div>
<% end %>
```

Context: The `<div class="wrapper">` starts at line 28. The flash blocks sit between the optional menu render (line 29) and `<%= yield %>` (line 33). Insert the alert block directly after the notice block. No other layout changes are needed.

---

### `config/locales/ja.yml` (config/i18n)

**Analog:** itself — `config/locales/ja.yml`

**Existing `devise.sessions.*` keys:** None present (the section does not exist in the app's ja.yml; only `two_factor.*`, `flash.*`, `nav.*`, etc. are present as of lines 1-168).

**Existing flash namespace pattern** (lines 129-131):
```yaml
  flash:
    errors:
      generic: エラーが発生しました
```

**Addition required — insert `devise:` section. Follow existing top-level indentation (2 spaces per level). Place after the `two_factor:` block (line 103) or as a new top-level sibling:**
```yaml
  devise:
    sessions:
      invalid: "%{authentication_keys}またはパスワードが違います。"
```

Note: The `%{authentication_keys}` interpolation variable is what Devise's `set_flash_message!` passes. The phrasing mirrors `devise.failure.invalid` in the devise-i18n gem for consistency.

---

### `config/locales/en.yml` (config/i18n)

**Analog:** itself — `config/locales/en.yml`

**Existing `flash` namespace pattern** (lines 129-131):
```yaml
  flash:
    errors:
      generic: Something went wrong.
```

**Addition required — same structure as ja.yml, English text:**
```yaml
  devise:
    sessions:
      invalid: "Invalid %{authentication_keys} or password."
```

Key symmetry rule: Both files must receive this key in the same commit. `test/i18n/locales_parity_test.rb` enforces parity on every `bin/rails test` run — adding to only one file causes an immediate test failure.

---

### `test/controllers/sessions_controller_test.rb` (test, NEW FILE)

**Analog:** `test/controllers/application_controller_test.rb` — closest existing integration test covering locale assertions for unauthenticated paths.

**File header and class setup pattern** (lines 1-3 of application_controller_test.rb):
```ruby
require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
```

**Locale assertion pattern — `html[lang]` + translated text** (lines 6-12 of application_controller_test.rb):
```ruby
def test_保存済みlocaleがenのユーザは英語でレンダリングされる
  user.preference.update!(locale: 'en')
  sign_in user
  get root_path
  assert_response :success
  assert_select 'html[lang=?]', 'en'
end
```

**Accept-Language header pattern** (lines 14-20 of application_controller_test.rb):
```ruby
get root_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,ja;q=0.8' }
```

**New file full pattern for sessions_controller_test.rb:**
```ruby
require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

  # AUTHI18N-01: Sign-in page renders in Japanese (default locale)
  def test_サインインページが日本語でレンダリングされる
    get new_user_session_path
    assert_response :success
    assert_select 'html[lang=?]', 'ja'
    assert_select 'input[type=submit][value=?]',
      I18n.t('devise.sessions.new.sign_in', locale: :ja)
  end

  # AUTHI18N-01: Sign-in page renders in English via Accept-Language
  def test_サインインページが英語でレンダリングされる
    get new_user_session_path, headers: { 'Accept-Language' => 'en' }
    assert_response :success
    assert_select 'html[lang=?]', 'en'
    assert_select 'input[type=submit][value=?]',
      I18n.t('devise.sessions.new.sign_in', locale: :en)
  end

  # AUTHI18N-03: Failed sign-in flash appears in English
  def test_サインイン失敗時のflashが英語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } },
      headers: { 'Accept-Language' => 'en' }
    assert_redirected_to new_user_session_path
    follow_redirect!
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: User.human_attribute_name(:email, locale: :en),
      locale: :en)
    assert_select '.flash-alert', text: expected
  end

  # AUTHI18N-01 + AUTHI18N-03: Failed sign-in flash appears in Japanese
  def test_サインイン失敗時のflashが日本語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } }
    assert_redirected_to new_user_session_path
    follow_redirect!
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: User.human_attribute_name(:email, locale: :ja),
      locale: :ja)
    assert_select '.flash-alert', text: expected
  end

end
```

Notes:
- `user` helper returns `User.first` (fixture id: 1) via `test/support/` helpers — same as all other integration tests.
- `Devise::Test::IntegrationHelpers` is included in `ActionDispatch::IntegrationTest` via `test/test_helper.rb` line 18, so `sign_in` is available but not needed for unauthenticated paths.
- `User.human_attribute_name(:email, locale: :xx)` avoids hardcoding the humanized key value (see RESEARCH.md Open Question 1).
- The `Accept-Language: en` header controls locale for unauthenticated requests because `saved_locale` returns nil when not signed in; the `Localization` concern then falls back to Accept-Language.

---

### `test/controllers/two_factor_authentication_controller_test.rb` (test, EXTEND)

**Analog:** itself — already has 7 tests covering 2FA sign-in flow.

**Existing setup pattern** (lines 11-21):
```ruby
def test_sign_in_with_2fa_redirects_to_otp
  user.enable_two_factor!
  post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
  assert_redirected_to users_two_factor_authentication_path
end

def test_otp_page_renders
  user.enable_two_factor!
  post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
  get users_two_factor_authentication_path
  assert_response :success
end
```

**New tests to append (AUTHI18N-02 + VERI18N-02):**
```ruby
# AUTHI18N-02: OTP page renders in Japanese (default locale)
def test_OTPページが日本語でレンダリングされる
  user.enable_two_factor!
  post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
  get users_two_factor_authentication_path
  assert_response :success
  assert_select 'html[lang=?]', 'ja'
  assert_select 'label', text: I18n.t('two_factor.code_label', locale: :ja)
end

# AUTHI18N-02: OTP page renders in English via Accept-Language
def test_OTPページが英語でレンダリングされる
  user.enable_two_factor!
  post user_session_path,
    params: { user: { email: user.email, password: 'testtest' } },
    headers: { 'Accept-Language' => 'en' }
  get users_two_factor_authentication_path,
    headers: { 'Accept-Language' => 'en' }
  assert_response :success
  assert_select 'label', text: I18n.t('two_factor.code_label', locale: :en)
end
```

Note: The OTP page is served by an unauthenticated controller action (`skip_before_action :authenticate_user!`). Locale resolves via Accept-Language header since `user_signed_in?` is false at that point. The `html[lang]` assertion can be included for the English test if the page renders a full layout with `<html lang>`.

---

### `test/i18n/locales_parity_test.rb` (test, VERIFY ONLY — no changes)

**No changes needed.** File already exists and passes (1 run, 4 assertions green). The test automatically catches any parity breakage when new keys are added.

**Full file for reference** (lines 1-25):
```ruby
require 'test_helper'

class LocalesParityTest < ActiveSupport::TestCase
  def flatten_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten_keys(value, path) : [path]
    end
  end

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
end
```

---

### `app/assets/stylesheets/common.css.scss` (stylesheet)

**Analog:** itself — existing `.flash-notice` rule at lines 333-340.

**Existing `.flash-notice` rule** (lines 333-340):
```scss
.flash-notice {
  background: #dff0d8;
  color: #3c763d;
  border: 1px solid #d6e9c6;
  padding: 10px 16px;
  margin-bottom: 16px;
  border-radius: 4px;
}
```

**Addition required — `.flash-alert` rule (append after `.flash-notice` block):**
```scss
.flash-alert {
  background: #f2dede;
  color: #a94442;
  border: 1px solid #ebccd1;
  padding: 10px 16px;
  margin-bottom: 16px;
  border-radius: 4px;
}
```

Color values follow Bootstrap 3 alert-danger convention, which matches the existing `.flash-notice` use of Bootstrap 3 alert-success colors.

---

## Shared Patterns

### Locale Resolution for Unauthenticated Requests
**Source:** `app/controllers/concerns/localization.rb` (Phase 14), `test/controllers/application_controller_test.rb` lines 14-20
**Apply to:** `sessions_controller_test.rb`, 2FA controller test extensions
```ruby
# Unauthenticated requests: locale comes from Accept-Language header
# (saved_locale returns nil when user_signed_in? is false)
get path, headers: { 'Accept-Language' => 'en' }
assert_select 'html[lang=?]', 'en'
```

### Integration Test Class and Helper Setup
**Source:** `test/test_helper.rb` lines 17-19, `test/controllers/application_controller_test.rb` lines 1-3
**Apply to:** new `sessions_controller_test.rb`
```ruby
require 'test_helper'

class FooControllerTest < ActionDispatch::IntegrationTest
  # Devise::Test::IntegrationHelpers auto-included via test_helper.rb
  # user helper (User.first) available via test/support/
end
```

### Key Symmetry Invariant
**Source:** `test/i18n/locales_parity_test.rb`
**Apply to:** both locale file edits
- Every key added to `ja.yml` must be added to `en.yml` in the same change.
- The parity test runs on every `bin/rails test` and will fail immediately if a key is added to only one file.

### YAML Nesting Convention
**Source:** `config/locales/ja.yml` lines 129-131, `config/locales/en.yml` lines 129-131
**Apply to:** new `devise.sessions.invalid` key in both locale files
```yaml
# Top-level locale key, 2-space indent per level, no leading dash
ja:
  devise:
    sessions:
      invalid: "..."
```

---

## No Analog Found

None — all files have direct analogs in the codebase.

---

## Metadata

**Analog search scope:** `test/controllers/`, `app/views/layouts/`, `config/locales/`, `app/assets/stylesheets/`, `test/i18n/`
**Files scanned:** 10 source files read directly
**Pattern extraction date:** 2026-05-01
