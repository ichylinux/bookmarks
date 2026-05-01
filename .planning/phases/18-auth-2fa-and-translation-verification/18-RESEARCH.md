# Phase 18: Auth, 2FA & Translation Verification - Research

**Researched:** 2026-05-01
**Domain:** Rails i18n / devise-i18n / Minitest locale assertions
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Find every hardcoded Japanese literal in views, helpers, controllers, and JavaScript. Translate UI literals into locale keys. Document user-created and external-data content (e.g., `holiday_jp` holiday names carried forward from Phase 17) as intentionally untranslated. The phase ends with zero unexplained hardcoded Japanese strings.

- **D-02:** Write a persistent Minitest test that loads both `config/locales/ja.yml` and `config/locales/en.yml`, extracts the full key set from each, and asserts they are identical. This test runs on every `bin/rails test` run and will catch future key-symmetry regressions automatically.

### Claude's Discretion

- **Devise sign-in page activation**: `devise-i18n` is already in the Gemfile and was explicitly deferred to this phase (Phase 16 D-04). Prefer the approach that minimizes generated files in `app/views/devise/`. Generate views locally only if needed to support the custom `Users::SessionsController` override or app-specific layout. Cover only the Devise pages actively used: sessions (sign-in) at minimum.

- **Failed sign-in flash key**: `set_flash_message!(:alert, :invalid)` in `app/controllers/users/sessions_controller.rb` resolves to `devise.sessions.invalid`. Check Devise's fallback chain first. If the fallback doesn't land in the right key, add `devise.sessions.invalid` to both `ja.yml` and `en.yml`.

- **VERI18N-02 test type**: Prefer Minitest integration tests for locale-specific assertions. Add a Cucumber scenario only if a representative auth + 2FA E2E path cannot be covered adequately with integration tests. Tests should cover at minimum: sign-in page renders in Japanese, sign-in page renders in English, failed sign-in flash appears in the request locale, 2FA OTP page renders in both locales.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTHI18N-01 | User sees Devise authentication pages and Devise flash/failure messages in the active locale | Sign-in view is already locale-aware via devise-i18n engine; flash key `devise.sessions.invalid` is missing and must be added; flash[:alert] is missing from the layout |
| AUTHI18N-02 | User sees custom two-factor authentication and setup pages in Japanese or English | 2FA views already fully locale-keyed via `two_factor.*` keys; test coverage is the only gap |
| AUTHI18N-03 | User sees the first failed sign-in message in English when their request resolves to English | Requires adding `devise.sessions.invalid` key to en.yml AND adding flash[:alert] rendering to the layout |
| VERI18N-02 | User-facing tests cover representative Japanese and English UI paths for layout, preferences, core gadgets, and auth/2FA surfaces | New integration test file for sessions + extend existing 2FA tests with locale assertions |
| VERI18N-03 | User-visible Japanese literals remaining in views, helpers, controllers, and JavaScript are either translated or explicitly documented as intentional user content | Audit complete — only two intentional categories remain (see Translation Audit section) |
| VERI18N-04 | User-visible translation keys are present in both `ja.yml` and `en.yml` for every extracted string | Test already exists at `test/i18n/locales_parity_test.rb` and passes; adding new keys in this phase must maintain parity |
</phase_requirements>

---

## Summary

Phase 18 is a targeted close-out phase. The codebase is already in excellent shape: the
devise-i18n engine automatically provides locale-aware sign-in views without any view
generation, all 2FA views are fully locale-keyed, and the Japanese literal audit found zero
unexplained hardcoded strings in rendered code (views/helpers/controllers/JS). The key
symmetry test (VERI18N-04) already exists and passes.

The work is narrower than the phase description suggests. Three concrete gaps need fixing:
(1) the `devise.sessions.invalid` translation key is missing from both locale files, causing
the failed sign-in flash to output a "Translation missing" message rather than localized text;
(2) `flash[:alert]` is never rendered in the application layout, so the flash never reaches
the user even after the key is added; and (3) VERI18N-02 needs new integration tests covering
sign-in page locale rendering and flash messages in both locales.

**Primary recommendation:** Add `devise.sessions.invalid` to `ja.yml` and `en.yml`, add
`flash[:alert]` to the application layout alongside the existing `flash[:notice]`, and write a
`sessions_controller_test.rb` with locale assertions. AUTHI18N-02 and VERI18N-04 require no new
code, only test extensions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Sign-in page locale | Frontend Server (ERB) | — | devise-i18n engine injects localized view via Rails engine view path; `around_action :set_locale` sets I18n.locale before render |
| Failed sign-in flash message | API / Backend | Frontend Server | `set_flash_message!(:alert, :invalid)` in `Users::SessionsController`; message resolved via `I18n.t` at controller layer; display in ERB layout |
| Flash display | Frontend Server (layout ERB) | — | `app/views/layouts/application.html.erb` renders flash; currently only shows `flash[:notice]` |
| 2FA page locale | Frontend Server (ERB) | — | Custom views already use `t('two_factor.*')` keys; locale set by inherited `Localization` concern |
| Locale key symmetry | Test layer | — | `test/i18n/locales_parity_test.rb` (already exists) |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| devise-i18n | 1.16.0 | Locale files and localized views for Devise | Already in Gemfile; auto-loads `ja.yml` + `en.yml` via Railtie; provides localized sessions views |
| rails-i18n | ~8.0 | ActiveRecord error messages, date formats | Already active from Phase 16 |

No new gems needed for this phase. [VERIFIED: bundle show devise-i18n]

### Key Libraries Already Active

| Library | Version | Relevant Behavior |
|---------|---------|------------------|
| devise-i18n | 1.16.0 | Railtie adds `rails/locales/{ja,en}.yml` to `I18n.load_path` based on `config.i18n.available_locales` |
| devise | 5.0.3 | `set_flash_message!` resolves keys via `find_message`; `translation_scope` = `"devise.#{controller_name}"` |

---

## Architecture Patterns

### Sign-in View Resolution Chain

```
GET /users/sign_in
  -> Users::SessionsController (inherits Devise::SessionsController)
  -> scoped_views? = false (default)
  -> _prefixes = ["users/sessions", "devise/sessions", ...]
  -> Rails searches:
     1. app/views/users/sessions/new.html.erb  -- DOES NOT EXIST
     2. app/views/devise/sessions/new.html.erb  -- DOES NOT EXIST (dir empty)
     3. devise-i18n engine: app/views/devise/sessions/new.html.erb  -- FOUND
        (uses t('.sign_in') -> resolves to devise.sessions.new.sign_in via lazy lookup)
     4. (devise gem fallback never reached)
```

**Key insight:** The devise-i18n engine's `app/views/` is in the global view path because
Rails Engines automatically share their `app/` directories with the host application. No view
generation is needed. [VERIFIED: integration test confirmed `ログイン` / `Log in` renders
correctly in both locales.]

### Flash Key Resolution for `set_flash_message!(:alert, :invalid)`

```ruby
# In Users::SessionsController (inherits DeviseController):
# translation_scope = "devise.sessions"   (controller_name = "sessions")
# find_message(:invalid) calls:
I18n.t("user.invalid", scope: "devise.sessions", default: [:invalid])
# => tries "devise.sessions.user.invalid"  -- MISSING
# => falls back to :invalid  (Symbol default, looked up WITHOUT scope)
# => tries top-level "invalid"  -- MISSING
# => returns "Translation missing..." string
```

The key `devise.sessions.invalid` does NOT exist in the devise-i18n gem's locale files. Only
`devise.sessions.{already_signed_out, new.sign_in, signed_in, signed_out}` are provided.
`devise.failure.invalid` exists in the gem but is not reached by the sessions controller's
`translation_scope`. [VERIFIED: ran integration test, confirmed "Translation missing" output.]

**Fix:** Add `devise.sessions.invalid` to both `ja.yml` and `en.yml`.

### Flash Display Gap

The application layout currently renders only `flash[:notice]`:

```erb
<% if flash[:notice].present? %>
  <div class="flash-notice"><%= flash[:notice] %></div>
<% end %>
```

`flash[:alert]` (set by the failed sign-in) is never displayed. [VERIFIED: grep of layout +
integration test confirmed flash[:alert] never appears on page.]

**Fix:** Add a `flash[:alert]` block to `app/views/layouts/application.html.erb` alongside
the existing notice block, using a CSS class `flash-alert`.

### Locale Test Pattern (established in prior phases)

```ruby
# From test/controllers/application_controller_test.rb (Phase 14/16 pattern):
def test_sign_in_page_renders_in_japanese
  get new_user_session_path
  assert_response :success
  assert_select 'html[lang=?]', 'ja'
  assert_select 'input[type=submit][value=?]', I18n.t('devise.sessions.new.sign_in', locale: :ja)
end

def test_sign_in_page_renders_in_english
  get new_user_session_path, headers: { 'Accept-Language' => 'en' }
  assert_response :success
  assert_select 'html[lang=?]', 'en'
  assert_select 'input[type=submit][value=?]', I18n.t('devise.sessions.new.sign_in', locale: :en)
end
```

### VERI18N-04 Key Symmetry Pattern (already implemented)

```ruby
# test/i18n/locales_parity_test.rb — ALREADY EXISTS AND PASSES
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
```

This test runs on every `bin/rails test` run. Any new keys added in Phase 18 that break
parity will be caught immediately. [VERIFIED: file exists, test passes — 1 run, 4 assertions.]

---

## Translation Audit Results (VERI18N-03)

### Zero Unexplained Hardcoded Japanese Literals

A comprehensive scan of `app/views/**/*.erb`, `app/helpers/**/*.rb`,
`app/controllers/**/*.rb`, and `app/javascript/**/*.js` found:

| Location | Japanese Found | Classification |
|----------|---------------|----------------|
| `app/views/welcome/_bookmark_gadget.html.erb:6` | `フォルダを先頭に...` | ERB comment (`<%# ... %>`), never rendered |
| `app/controllers/bookmarks_controller.rb:8,20,35,94` | Japanese code comments | Ruby comments, never rendered |
| `app/models/bookmark.rb`, `bookmark_gadget.rb` | Japanese code comments | Ruby comments, never rendered |
| `app/assets/javascripts/bookmark_gadget.js` | Japanese code comments | JS comments, never rendered |
| `app/assets/stylesheets/welcome.css.scss` | Japanese CSS comments | CSS comments, never rendered |
| `app/models/preference.rb:13,14` | `'自動'`, `'日本語'` | **Intentional: native label rule** (Phase 15 D-02) |
| Calendar views via `holiday_jp` | Japanese holiday names | **Intentional: external data** (Phase 17 D-03/04) |
| `app/views/bookmarks/index.html.erb` | 📁 🔖 | Unicode emoji (not Japanese text), acceptable |
| `app/views/common/_menu.html.erb` | ▼ | Unicode arrow symbol, acceptable |
| `app/views/welcome/_bookmark_gadget.html.erb` | ▶ | Unicode triangle symbol, acceptable |

[VERIFIED: grep with `[ぁ-ん々〆〤ァ-ヤ一-龯]` character class across all files]

**Documented exceptions (carry from prior phases):**

1. **`Preference::LOCALE_OPTIONS` native labels** (`'自動'`, `'日本語'`): Locale-selector
   labels follow the industry convention of displaying in their native script regardless of
   the active UI locale (Phase 15 D-02). These are intentional and require no change.

2. **`holiday_jp` holiday names**: Japanese public holiday names come from the `holiday_jp`
   gem as external regional data. They are not UI chrome and are intentionally untranslated
   (Phase 17 D-03/04 documented exception).

**Conclusion:** VERI18N-03 is already satisfied for the existing codebase. The phase only
needs to add `devise.sessions.invalid` to both locale files (and maintain parity per D-02).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Localized Devise views | Custom sessions/new.html.erb | devise-i18n engine views | Engine views already accessible in view path; building custom views creates maintenance burden |
| YAML key flattening | Recursive hash walker | Already implemented in `test/i18n/locales_parity_test.rb` | Don't duplicate — extend or reuse |
| Flash message locale resolution | Custom flash helper | `I18n.t` + `set_flash_message!` already wired to locale | The mechanism works once the key exists |

---

## Common Pitfalls

### Pitfall 1: Generating Devise Views Unnecessarily

**What goes wrong:** Running `rails generate devise:i18n:views` copies 10+ ERB files into
`app/views/devise/`. These then shadow the engine views and must be maintained forever.

**Why it happens:** Developers assume they need to generate views to enable localization.

**How to avoid:** The devise-i18n engine views are already in Rails' view lookup path. The
sign-in page renders `ログイン`/`Log in` correctly without any generated files. Only create
`app/views/users/sessions/new.html.erb` or `app/views/devise/sessions/new.html.erb` if you
need app-specific customization beyond what the engine provides.

**Warning signs:** Running `rails generate devise:i18n:views` or `rails generate devise:views`.

### Pitfall 2: Confusing `devise.failure.invalid` with `devise.sessions.invalid`

**What goes wrong:** Checking the devise-i18n gem locale files and finding `devise.failure.invalid`
(present in both ja.yml and en.yml) and concluding the key is already covered.

**Why it happens:** The standard Devise `create` action in `Devise::SessionsController` uses
Warden to authenticate and the failure message comes from `devise.failure.invalid`. Our custom
`Users::SessionsController#create` bypasses Warden and calls `set_flash_message!(:alert, :invalid)`
directly, which resolves via `translation_scope = "devise.sessions"`.

**How to avoid:** The key needed is `devise.sessions.invalid`, not `devise.failure.invalid`.
Both must be added to `ja.yml` and `en.yml`. [VERIFIED: confirmed via integration test]

### Pitfall 3: Key Symmetry Parity Breaking

**What goes wrong:** Adding `devise.sessions.invalid` to one locale file but forgetting the
other causes `test/i18n/locales_parity_test.rb` to fail.

**Why it happens:** YAML edits to one file without mirroring the other.

**How to avoid:** Add the key to both files in the same commit. The parity test catches any
regression immediately on `bin/rails test`.

### Pitfall 4: Flash[:alert] Still Not Displayed

**What goes wrong:** Adding `devise.sessions.invalid` key works, but the flash message never
appears on the sign-in page.

**Why it happens:** `app/views/layouts/application.html.erb` only renders `flash[:notice]`,
not `flash[:alert]`. The session controller sets `flash[:alert]` and redirects, but the layout
discards it silently.

**How to avoid:** Add a `flash-alert` div to the layout alongside the existing `flash-notice`
div. The 2FA views handle their own inline alerts (using `flash.now[:alert]`), so they are not
affected by the layout change.

### Pitfall 5: Lazy-Lookup Key Path for Devise Views

**What goes wrong:** The devise-i18n sign-in view uses `t('.sign_in')`. This lazy lookup resolves
to `devise.sessions.new.sign_in` (the template path `devise/sessions/new` + key `.sign_in`).
If a local `app/views/users/sessions/new.html.erb` is created, `t('.sign_in')` would instead
resolve to `users.sessions.new.sign_in` — a missing key.

**Why it happens:** Lazy-lookup is template-path-anchored (Phase 15 lesson).

**How to avoid:** Do not generate a local sessions view unless you add the corresponding keys
under `users.sessions.new` in both locale files, or switch to absolute key calls.

---

## Code Examples

### Adding `devise.sessions.invalid` to `ja.yml`

```yaml
# Source: verified via Devise find_message + integration test
devise:
  sessions:
    already_signed_out: 既にログアウト済みです。  # provided by devise-i18n
    invalid: "%{authentication_keys}またはパスワードが違います。"  # ADD THIS
    new:
      sign_in: ログイン
    signed_in: ログインしました。
    signed_out: ログアウトしました。
```

Note: The `authentication_keys` interpolation is consistent with `devise.failure.invalid`
in the same gem. Use the same phrasing for both locales.

### Adding `flash[:alert]` to Application Layout

```erb
<%# app/views/layouts/application.html.erb — add after the flash[:notice] block %>
<% if flash[:notice].present? %>
  <div class="flash-notice"><%= flash[:notice] %></div>
<% end %>
<% if flash[:alert].present? %>
  <div class="flash-alert"><%= flash[:alert] %></div>
<% end %>
```

### Integration Test Pattern for Sign-in Locale (VERI18N-02)

```ruby
# test/controllers/sessions_controller_test.rb (NEW FILE)
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

  # AUTHI18N-03: Failed sign-in flash shows in English when locale is :en
  def test_サインイン失敗時のflashが英語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } },
      headers: { 'Accept-Language' => 'en' }
    assert_redirected_to new_user_session_path
    follow_redirect!
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: 'Email', locale: :en)
    assert_select '.flash-alert', text: expected
  end

  # AUTHI18N-01 + AUTHI18N-03: Failed sign-in flash shows in Japanese when locale is :ja
  def test_サインイン失敗時のflashが日本語で表示される
    post user_session_path,
      params: { user: { email: user.email, password: 'wrongpass' } }
    assert_redirected_to new_user_session_path
    follow_redirect!
    expected = I18n.t('devise.sessions.invalid',
      authentication_keys: 'Eメール', locale: :ja)
    assert_select '.flash-alert', text: expected
  end
end
```

### 2FA Locale Test Extension (AUTHI18N-02 + VERI18N-02)

```ruby
# Extend test/controllers/two_factor_authentication_controller_test.rb

# AUTHI18N-02: OTP page renders in Japanese
def test_OTPページが日本語でレンダリングされる
  user.enable_two_factor!
  post user_session_path, params: { user: { email: user.email, password: 'testtest' } }
  get users_two_factor_authentication_path
  assert_response :success
  assert_select 'html[lang=?]', 'ja'
  assert_select 'label', text: I18n.t('two_factor.code_label', locale: :ja)
end

# AUTHI18N-02: OTP page renders in English
def test_OTPページが英語でレンダリングされる
  user.preference.update!(locale: 'en')
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

Note on 2FA locale during OTP step: the OTP page is an unauthenticated request
(`skip_before_action :authenticate_user!`). The locale resolves via `Accept-Language` header
since `saved_locale` returns `nil` when `user_signed_in?` is false. Use the header to control
locale in tests.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `"Log in"` in Devise views | `t('.sign_in')` from devise-i18n engine | Phase 18 (activate) | No view generation needed |
| No flash[:alert] in layout | Add flash-alert div to layout | Phase 18 | Required for sign-in failure UX |
| Missing `devise.sessions.invalid` | Add to ja.yml + en.yml | Phase 18 | Fixes "Translation missing" flash |

**Deprecated/outdated:**
- Calling `Devise.failure.invalid` for sessions flash: Not wrong but not reachable from our custom sessions controller.

---

## Key Discovery: VERI18N-04 Already Implemented

`test/i18n/locales_parity_test.rb` already exists and passes (1 run, 4 assertions green).
It uses the `flatten_keys` helper the CONTEXT described. **The planner should NOT create this
test — it already exists.** The plan for VERI18N-04 should only verify the test continues to
pass after new keys are added with parity.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `authentication_keys` interpolation variable in `devise.sessions.invalid` should use the same value as `devise.failure.invalid` (`"%{authentication_keys}またはパスワードが違います。"`) | Code Examples | If the variable name differs, flash shows raw `%{authentication_keys}` literal; low risk since Devise source confirms the variable name |

**All other claims were verified via tool calls (integration tests, grep, file reads).**

---

## Open Questions

1. **`authentication_keys` interpolation value in flash assertion**
   - What we know: `I18n.t('devise.sessions.invalid', authentication_keys: ...)` — the value passed is whatever Devise resolves for the model's `authentication_keys` (defaults to `email` humanized).
   - What's unclear: The exact humanized value Devise passes — it may be `"Email"` (en) or `"Eメール"` (ja, from devise-i18n's `activerecord.attributes.user.email`).
   - Recommendation: Test assertions should use `I18n.t('devise.sessions.invalid', authentication_keys: User.human_attribute_name(:email), locale: :xx)` to avoid hardcoding the humanized key name, OR assert that flash[:alert] is present and non-empty rather than asserting the exact string.

2. **CSS styling for `flash-alert`**
   - What we know: `flash-notice` has an existing CSS class in the app stylesheets.
   - What's unclear: Whether `flash-alert` needs a styled rule or just a plain div.
   - Recommendation: Add a minimal `flash-alert` CSS rule (red/warning color) alongside the existing `flash-notice` rule. Check `app/assets/stylesheets/` for the existing flash CSS.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 18 is purely code/config/test changes. No external tools, services, or CLIs beyond the existing project stack are required.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (ActionDispatch::IntegrationTest) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/sessions_controller_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTHI18N-01 | Sign-in page renders in Japanese | integration | `bin/rails test test/controllers/sessions_controller_test.rb` | ❌ Wave 0 |
| AUTHI18N-01 | Sign-in page renders in English | integration | `bin/rails test test/controllers/sessions_controller_test.rb` | ❌ Wave 0 |
| AUTHI18N-02 | OTP page renders in Japanese | integration | `bin/rails test test/controllers/two_factor_authentication_controller_test.rb` | ✅ (extend) |
| AUTHI18N-02 | OTP page renders in English | integration | `bin/rails test test/controllers/two_factor_authentication_controller_test.rb` | ✅ (extend) |
| AUTHI18N-03 | Failed sign-in flash in English | integration | `bin/rails test test/controllers/sessions_controller_test.rb` | ❌ Wave 0 |
| AUTHI18N-03 | Failed sign-in flash in Japanese | integration | `bin/rails test test/controllers/sessions_controller_test.rb` | ❌ Wave 0 |
| VERI18N-02 | Representative locale paths covered | integration | `bin/rails test` | ✅ (partial, extend) |
| VERI18N-03 | Zero unexplained Japanese literals | manual audit | — (audit done in research) | n/a |
| VERI18N-04 | ja.yml and en.yml have identical key sets | unit | `bin/rails test test/i18n/locales_parity_test.rb` | ✅ EXISTS |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/sessions_controller_test.rb test/i18n/locales_parity_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** `yarn run lint && bin/rails test && bundle exec rake dad:test` (per CLAUDE.md)

### Wave 0 Gaps

- [ ] `test/controllers/sessions_controller_test.rb` — covers AUTHI18N-01, AUTHI18N-03, VERI18N-02 (auth paths)

*(Existing files: `test/i18n/locales_parity_test.rb` passes. `test/controllers/two_factor_authentication_controller_test.rb` exists and passes; extend in-place for AUTHI18N-02.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 18 adds i18n only — no auth logic changes |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No access control changes |
| V5 Input Validation | No | No new user input paths |
| V6 Cryptography | No | No cryptographic changes |

Phase 18 makes no security-relevant code changes. All modifications are to locale YAML files,
ERB layout markup for flash display, and test files.

---

## Sources

### Primary (HIGH confidence)

- Integration tests run in session (`bin/rails test /tmp/test_*`) — confirmed sign-in page renders locale-aware text, confirmed "Translation missing" for `devise.sessions.invalid`, confirmed `flash[:alert]` not displayed
- `test/i18n/locales_parity_test.rb` — file read and test executed; confirmed already exists and passes
- `/home/ichy/.gem/ruby/3.4.0/ruby/3.4.0/gems/devise-i18n-1.16.0/rails/locales/ja.yml` — confirmed `devise.sessions.invalid` is absent
- `/home/ichy/.gem/ruby/3.4.0/ruby/3.4.0/gems/devise-i18n-1.16.0/rails/locales/en.yml` — confirmed `devise.sessions.invalid` is absent
- `/home/ichy/.gem/ruby/3.4.0/ruby/3.4.0/gems/devise-i18n-1.16.0/app/views/devise/sessions/new.html.erb` — confirmed uses `t('.sign_in')` lazy lookup
- `/home/ichy/.gem/ruby/3.4.0/ruby/3.4.0/gems/devise-5.0.3/app/controllers/devise_controller.rb` — confirmed `find_message` and `translation_scope` implementation
- `app/views/layouts/application.html.erb` — confirmed only `flash[:notice]` rendered
- `app/views/users/two_factor_authentication/show.html.erb`, `app/views/users/two_factor_setup/setup.html.erb`, `app/views/users/two_factor_setup/enabled.html.erb` — confirmed all use `t('two_factor.*')` keys
- `config/locales/ja.yml` + `config/locales/en.yml` — confirmed `two_factor.*` keys fully present and symmetric

### Secondary (MEDIUM confidence)

- Rails engine view path sharing behavior — standard Rails behavior; engines share `app/` with host by default unless explicitly isolated from view paths

---

## Metadata

**Confidence breakdown:**
- Sign-in page locale behavior: HIGH — verified via live integration test
- Flash key resolution: HIGH — verified via live integration test showing "Translation missing" message
- devise-i18n engine view resolution: HIGH — verified via test (renders `ログイン`/`Log in`)
- VERI18N-03 audit completeness: HIGH — grep scan confirmed, only intentional exceptions remain
- VERI18N-04 test status: HIGH — file read + test executed

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (stable gem versions)
