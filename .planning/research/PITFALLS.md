# Pitfalls Research

**Domain:** Adding bilingual (ja/en) i18n to an existing Rails 8.1 app with hardcoded Japanese strings, Devise auth + 2FA, Sprockets, per-user preferences, Minitest integration tests, and Cucumber E2E tests
**Researched:** 2026-05-01
**Confidence:** HIGH — based on direct codebase inspection plus verified community sources

---

## Critical Pitfalls

### Pitfall 1: Fallbacks in Production Silently Mask Incomplete `en.yml`

**What goes wrong:**
`config/environments/production.rb` already has `config.i18n.fallbacks = true`. If `en.yml` is missing a key that exists in `ja.yml`, production silently renders the Japanese string for English users instead of raising an error. No test fails; no exception is logged. The app "works" but English pages contain Japanese text.

**Why it happens:**
Fallbacks are intentional and correct for production, but they become a trap during the extraction phase. Developers add a key to `ja.yml`, extract the view, and ship. The corresponding `en.yml` key is forgotten. Tests pass because the test suite runs in `:ja` (the default locale) and fallback kicks in for any `en` check, hiding the gap.

**How to avoid:**
- Enable `config.action_view.raise_on_missing_translations = true` in both `test.rb` and `development.rb` (both already have it commented out — uncomment it as the first step of the i18n milestone).
- Use `i18n-tasks` gem to do a static analysis sweep (`bundle exec i18n-tasks missing`) before each phase ends. It checks both locale files without relying on test execution.
- In integration tests that verify English UI, explicitly set `I18n.locale = :en` for those test cases so missing `en.yml` keys raise rather than fall back.

**Warning signs:**
- A string appears in Japanese on an English-locale page.
- `bundle exec i18n-tasks missing` reports keys in `en` that exist in `ja`.
- `raise_on_missing_translations` is still commented out in `test.rb`.

**Phase to address:** Infrastructure phase (locale file setup + `raise_on_missing_translations` + `i18n-tasks` CI check) — before any string extraction begins.

---

### Pitfall 2: Tests Assert Hardcoded Japanese Strings That Will Change

**What goes wrong:**
The existing test suite has numerous assertions on literal Japanese strings:

```ruby
assert_select 'input[type=submit][value=?]', '保存', count: 1
assert_select '.breadcrumbs-label', text: 'ブックマーク'
assert_select 'a.breadcrumbs-create-bookmark[title=?]', 'ブックマークを追加'
assert_match 'QRコード', response.body
assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
```

When those strings are extracted to locale keys and rendered via `t(...)`, these assertions stop working in any test that runs with `I18n.locale = :en`. They also break if the Japanese string changes (e.g., during copy editing).

**Why it happens:**
The tests were written before i18n existed. They assert on rendered output, which was fine when output was hardcoded. After extraction, the rendered output is driven by the locale file, not the view source.

**How to avoid:**
- Replace literal string assertions with `I18n.t(...)` lookups:
  ```ruby
  assert_select 'input[type=submit][value=?]', I18n.t('preferences.save_button')
  ```
- For tests that specifically verify locale behavior (e.g., English vs Japanese label rendering), set locale explicitly in a setup block and restore it in teardown:
  ```ruby
  setup { I18n.locale = :en }
  teardown { I18n.locale = I18n.default_locale }
  ```
- Cucumber step definitions that match Japanese text strings (`*設定画面で タスクウィジェットを表示する*`) describe user-visible behavior and should match locale keys, not hardcoded strings, wherever possible.

**Warning signs:**
- `assert_match '保存'` without `I18n.t(...)` call after that string has been extracted.
- A test passes only because `I18n.locale` is `:ja` by default; it would fail if run with `:en`.

**Phase to address:** String extraction phases (each extraction phase must update the tests for the same view in the same PR — never extract a view without updating its tests in the same commit).

---

### Pitfall 3: `I18n.default_locale` Changed at Runtime Poisons All Threads

**What goes wrong:**
Setting `I18n.default_locale = :en` (or `:ja`) inside a controller action or `before_action` changes a **global** class-level variable. In Puma with multiple threads, every concurrent request immediately inherits the new default locale, regardless of their own session locale. This causes random locale mismatches that are impossible to reproduce reliably.

**Why it happens:**
The Rails i18n guide and many blog posts show `I18n.locale = params[:locale]` as the simple approach. Developers conflate `I18n.locale` (thread-local, safe) with `I18n.default_locale` (global, dangerous). Setting the default locale dynamically is a common copy-paste error.

**How to avoid:**
- Set `config.i18n.default_locale = :ja` only in `config/application.rb` (already done).
- In the `set_locale` callback, set `I18n.locale` (not `I18n.default_locale`):
  ```ruby
  around_action :switch_locale
  def switch_locale(&action)
    locale = locale_for_current_user
    I18n.with_locale(locale, &action)
  end
  ```
- **Exception (see Pitfall 4):** `around_action` with `I18n.with_locale` has a known conflict with Devise's warden middleware — see below.

**Warning signs:**
- `I18n.default_locale = ...` anywhere outside `config/application.rb`.
- Intermittent wrong-locale renders in staging that disappear on server restart.

**Phase to address:** Locale-setting infrastructure phase (ApplicationController + locale resolution logic).

---

### Pitfall 4: Devise Failure Messages Use Wrong Locale with `around_action`

**What goes wrong:**
The Rails guides recommend `around_action` with `I18n.with_locale`. However, Devise's authentication failure path runs through Warden middleware, which executes *after* the `around_action` yields and resets the locale back to default. The result: Devise failure flash messages (wrong password, account locked, etc.) are always rendered in `:ja`, even when the user's locale is `:en`. This was a confirmed bug in Devise (issue #4823, issue #5247).

**Why it happens:**
Warden's failure app is a separate Rack application. It processes the authentication error after the controller's `around_action` has already finished and reset `I18n.locale`. The locale is gone when Warden renders the error message.

**How to avoid:**
Use `before_action` (not `around_action`) for locale setting. `before_action` sets the thread-local `I18n.locale` at the start of the request and does not reset it at the end — so Warden's failure path, which runs later in the middleware stack, still sees the correct locale:

```ruby
before_action :set_locale

def set_locale
  I18n.locale = locale_for_current_user
end
```

This is safe because `I18n.locale` is thread-local. The risk of leakage between requests (the reason Rails recommends `around_action`) is negligible when the locale is reset at the *start* of every request via `before_action`. The locale from the previous request on the same thread is overwritten before any user code runs.

**Warning signs:**
- Devise flash messages (wrong password, sign out confirmation) show in `:ja` for English users.
- `around_action :switch_locale` with `I18n.with_locale` in `ApplicationController`.

**Phase to address:** Locale-setting infrastructure phase, before implementing Devise view translations.

---

### Pitfall 5: `devise-i18n` Gem Does Not Cover Custom Devise Views

**What goes wrong:**
The `devise-i18n` gem (already in the Gemfile) provides translations for Devise's *internal* flash messages and model error messages (e.g., `devise.sessions.signed_in`, `devise.failure.unauthenticated`). It does **not** translate the content of Devise views (form labels, button text, page headings). Any Devise view published with `rails generate devise:views` contains hardcoded English strings like "Log in", "Sign up", "Forgot your password?".

This app currently has no published Devise views — it uses Devise defaults. Those defaults are already translated by `devise-i18n`. But if Devise views are published (required to customize sign-in page appearance), the view strings must be manually extracted to locale files.

**Why it happens:**
Developers assume that installing `devise-i18n` fully handles all Devise text. It handles system-generated messages, not view HTML.

**How to avoid:**
- Before publishing Devise views (`rails generate devise:views`), know that you are taking on the translation burden for all form content in those views.
- If customization is not needed, keep Devise views unpublished — `devise-i18n` already handles the generated messages.
- If views must be published (for UI polish), immediately extract all hardcoded strings in the generated files before committing them.
- The 2FA views (`app/views/users/two_factor_authentication/`) and the Two Factor Setup views are custom (not Devise defaults) — their strings are already in `ja.yml` (confirmed). Both `en.yml` counterparts must be added.

**Warning signs:**
- `app/views/devise/sessions/new.html.erb` contains `Log in` as a literal string.
- `rails generate devise:views` output committed without `t(...)` substitutions.

**Phase to address:** Devise auth page translation phase — inspect whether views need to be published before extracting strings.

---

### Pitfall 6: `Accept-Language` Header Used Without Whitelisting — Locale Injection

**What goes wrong:**
Using `request.env['HTTP_ACCEPT_LANGUAGE']` raw to set the locale is a security vulnerability. An attacker (or a browser with unusual settings) can send `Accept-Language: ../../../../etc/passwd` or an arbitrary string. If the locale value is used to load a file path (`config/locales/#{locale}.yml`) or passed to `I18n.locale=` without validation, it can cause unexpected behavior or path traversal.

Additionally, without whitelisting, an attacker can force an unsupported locale, causing `MissingTranslation` errors to propagate or fallbacks to expose unintended strings.

**Why it happens:**
Quick implementations extract the first part of the `Accept-Language` header (e.g., `request.env['HTTP_ACCEPT_LANGUAGE'].to_s.scan(/[a-z]{2}/).first`) and use it directly. The Rails guides' code examples in this area have historically been noted as insecure (Rails issue #16289).

**How to avoid:**
- Always validate the locale against `I18n.available_locales`:
  ```ruby
  def extract_locale_from_accept_language_header
    lang = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.scan(/\A[a-z]{2}/).first
    I18n.available_locales.map(&:to_s).include?(lang) ? lang.to_sym : I18n.default_locale
  end
  ```
- Set `I18n.config.enforce_available_locales = true` (already set in `config/application.rb`) — this makes Rails raise on any attempt to set an unsupported locale.
- Only use `Accept-Language` for unauthenticated/first visits; authenticated users should use their stored `users.locale` preference, which is validated at save time.

**Warning signs:**
- `I18n.locale = request.env['HTTP_ACCEPT_LANGUAGE']` without sanitization.
- `enforce_available_locales = true` absent from `config/application.rb`.
- Locale derived from `Accept-Language` without checking `I18n.available_locales`.

**Phase to address:** Locale detection + user preference persistence phase.

---

### Pitfall 7: Per-User Locale Not Set for the Request — Locale Mismatch After Login

**What goes wrong:**
The `users.locale` column stores the user's preference. But if `set_locale` reads the locale before `authenticate_user!` runs (or reads from session instead of the freshly loaded user), the locale for the request is wrong. Specifically: a user logs in with `:en` preference, but the first request after login uses `:ja` (the default) because `current_user` is not yet available when locale is set.

A subtler variant: the `before_action :set_locale` order in `ApplicationController` matters. If it runs before `authenticate_user!`, `current_user` is `nil` for unauthenticated requests, and the per-user lookup fails silently, falling back to the default.

**Why it happens:**
`before_action` callbacks run in declaration order. Placing `set_locale` before `authenticate_user!` means the locale is resolved without a logged-in user. The locale is set to the default; the user sees a flash in the wrong language.

**How to avoid:**
- Declare `before_action :set_locale` *after* `before_action :authenticate_user!` in `ApplicationController`, or resolve locale gracefully when `current_user` is nil:
  ```ruby
  def set_locale
    I18n.locale = if current_user&.locale.present?
      current_user.locale
    elsif request.env['HTTP_ACCEPT_LANGUAGE'].present?
      extract_locale_from_accept_language_header
    else
      I18n.default_locale
    end
  end
  ```
- The locale resolution chain: (1) `current_user.locale`, (2) `Accept-Language` header, (3) `I18n.default_locale`.
- For the Devise sign-in page itself (unauthenticated), only the `Accept-Language` and default fallback apply — that is correct.

**Warning signs:**
- First request after login shows wrong language.
- `set_locale` raises `NoMethodError` on `nil.locale` for unauthenticated requests.
- `before_action :set_locale` appears before `before_action :authenticate_user!`.

**Phase to address:** Locale-setting infrastructure phase + `users.locale` persistence phase.

---

### Pitfall 8: Incomplete Extraction — Hardcoded Strings Survive in Unexpected Places

**What goes wrong:**
String extraction is done view-by-view but misses: `aria-label` attributes, `title` attributes, `placeholder` attributes, `value` attributes on submit buttons, strings inside helper methods that render HTML, strings inside `.js.erb` files, and hardcoded strings in `link_to` calls (e.g., `link_to '設定', preferences_path`). The app ships "translated" but scattered Japanese strings remain.

This is the most likely actual outcome of an i18n migration. Inspecting the current codebase:
- `application.html.erb`: `aria-label="メニュー"`, `link_to '設定'`, `link_to 'ログアウト'`
- `common/_menu.html.erb`: `link_to '設定'`, `link_to 'ブックマーク'`, `link_to 'タスク'`, `link_to 'ログアウト'`
- `preferences/index.html.erb`: `f.submit '保存'`, `select` option labels hardcoded (`'モダン'`, `'クラシック'`, `'シンプル'`)
- `bookmarks/index.html.erb`: `aria-label="パンくずリスト"`, `title: 'フォルダを作成'`, `title: 'ブックマークを追加'`
- `todos/update.js.erb`: potentially JS strings

**Why it happens:**
Developers focus on visible text content in `<p>` and `<td>` tags. HTML attribute strings, JavaScript strings, and helper-rendered strings are visually invisible during a manual review of ERB source. Select option labels and submit button values are particularly easy to miss.

**How to avoid:**
- Use `i18n-tasks` for static analysis: `bundle exec i18n-tasks health` will not catch attributes, but `bundle exec i18n-tasks find` with patterns helps.
- Run a grep sweep after each extraction phase for multi-byte (Japanese) characters in views and helpers:
  ```bash
  grep -rn '[^\x00-\x7F]' app/views/ app/helpers/
  ```
  Any match after an "extraction complete" claim is a missed string.
- Extract attribute strings to locale keys: `aria-label: t('layout.menu_button')`, not `aria-label="メニュー"`.
- Pay special attention to `f.select` option labels — they are often hash literals or arrays in the view, not ERB text nodes.

**Warning signs:**
- `grep -rn '[^\x00-\x7F]' app/views/` returns results after extraction is declared complete.
- `aria-label`, `title`, and `placeholder` attributes contain Japanese literals.
- `f.submit '保存'` instead of `f.submit t('...')`.

**Phase to address:** Every extraction phase. Run the grep sweep as the exit criterion for each phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Only extract `ja.yml`, defer `en.yml` | Faster first phase | `en.yml` never gets done; English mode broken at launch | Never — extract both in the same commit |
| Keep `raise_on_missing_translations` commented out | Avoids test noise early | Missing keys silently use fallback in tests; gaps never discovered | Never past the infrastructure phase |
| Use `around_action` + `I18n.with_locale` as Rails guide recommends | "Correct" per guides | Devise failure messages (wrong password etc.) use wrong locale | Never — use `before_action` for this app |
| Extract strings one view at a time, update locale file, skip tests | Faster extraction | Tests assert old hardcoded strings and pass because locale is `:ja` — false confidence | Never — update tests in the same commit as the view |
| Hardcode `locale: :ja` in tests to preserve existing assertions | Tests keep passing immediately | English locale never tested; `en.yml` gaps never discovered | Only as a transitional marker with a TODO, removed before phase closes |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `devise-i18n` gem | Assuming it translates Devise view HTML | It only translates generated flash/error messages; custom or published Devise views need manual extraction |
| Devise + Warden locale | `around_action` with `I18n.with_locale` | Use `before_action` so Warden failure path sees the correct locale |
| `rails-i18n` gem | Assuming it covers all date/number formatting for `:ja` | It does, but verify format keys are used in views (e.g., `l(date, format: :short)` not `date.strftime`) |
| `Accept-Language` header | Using raw header value as locale | Always whitelist against `I18n.available_locales`; `enforce_available_locales = true` already set |
| Fixtures + locale columns | Adding `locale` column to `users` fixture without a value | Fixture will insert `NULL`; `set_locale` must handle nil gracefully with a fallback |
| `f.select` option labels | Leaving `{'モダン' => 'modern', ...}` hash literal in the view | Move to `t('preferences.theme_options.modern')` etc. in `en.yml` and `ja.yml` |
| Cucumber features | Feature files in Japanese (`# language: ja`) — step text is language-specific | Cucumber steps describe behavior, not translated UI text; steps can remain in Japanese even when the app is bilingual |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `current_user.locale` loaded on every request via DB | Extra `SELECT users WHERE id=?` per request if `current_user` is not already loaded | `current_user` is already loaded by Devise's `authenticate_user!` — no extra query; `locale` is just a column on the already-loaded User object | Not an issue at this scale |
| `I18n.t` called in a loop (e.g., inside `.each` on a large collection) | Slow view rendering at scale | `I18n.t` is fast (hash lookup); not a real concern for this app | Not a real concern |
| Accept-Language parsing on every unauthenticated request | CPU overhead for header parsing | Cache in session after first parse; for authenticated users, use stored `locale` instead | Not a real concern for a personal app |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Raw `Accept-Language` value used as locale | Path traversal or unsupported locale forcing errors | Whitelist against `I18n.available_locales`; `enforce_available_locales = true` already set |
| `locale` param in URL accepted without validation | Attacker forces arbitrary locale, triggers `I18n::InvalidLocale` | Same whitelist pattern; do not expose locale as a URL param (this app uses per-user preference + header detection, not URL-based locale) |
| Locale stored in cookie without signing | Cookie tampering to force unsupported locale | This app stores locale in `users.locale` DB column (authenticated), not an unsigned cookie — safe by design |
| User can set `locale` to arbitrary string via preferences form | Same as above | Validate `locale` value in `Preference` or `User` model: `validates :locale, inclusion: { in: %w[ja en] }` |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Language switcher only on `/preferences` page, not on sign-in page | Unauthenticated users get language forced by their browser; cannot change before logging in | Accept-Language detection handles unauthenticated users; no sign-in page switcher needed for v1.4 |
| Flash messages for save/create remain in Japanese regardless of locale | English users see Japanese confirmations | Extract all flash messages to locale keys; `flash[:notice] = t('preferences.saved')` not a hardcoded string |
| Theme select options remain in Japanese (`モダン`) for English users | English users see Japanese option labels in a dropdown | Extract select options to locale files |
| Switching language does not take effect until next page load | User changes to English; page still shows Japanese until they navigate away | Language change in preferences should redirect (already does: `redirect_to root_path`) — locale will be applied on the next request |

---

## "Looks Done But Isn't" Checklist

- [ ] **Fallback masking check:** Run `bundle exec i18n-tasks missing` — zero output for both `ja` and `en`.
- [ ] **Grep sweep:** `grep -rn '[^\x00-\x7F]' app/views/ app/helpers/` returns zero results.
- [ ] **English locale smoke test:** Sign in, switch locale to `en`, visit every major page — zero Japanese strings visible.
- [ ] **Devise failure in English:** Set locale to `en`, attempt sign in with wrong password — flash message is in English.
- [ ] **`raise_on_missing_translations` active:** Enabled in `test.rb` and `development.rb`; run `rails test` — zero `MissingTranslation` exceptions.
- [ ] **`aria-label` and `title` attributes:** None contain hardcoded Japanese (grep for `aria-label="[^\x00-\x7F]`).
- [ ] **Submit button values:** `f.submit` calls use `t(...)`, not string literals.
- [ ] **Select option labels:** No `{' 日本語文字列' => 'value'}` hash literals in views.
- [ ] **Locale persists across redirect:** Change locale in preferences, redirect to root — root renders in the new locale.
- [ ] **Unauthenticated page locale:** Sign out, set browser to `en`, visit sign-in page — page renders in English.
- [ ] **Thread-safety check:** `I18n.default_locale` never assigned in any controller or model (grep: `grep -rn 'I18n.default_locale =' app/`).
- [ ] **Accept-Language whitelist:** Locale extraction method checks `I18n.available_locales` before assigning.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| `en.yml` gaps shipped to production | MEDIUM | Run `i18n-tasks missing`; add missing keys; redeploy; no DB migration needed |
| Hardcoded Japanese in views after "complete" extraction | LOW | Grep sweep; replace literals with `t(...)` calls; add to both locale files |
| Tests asserting hardcoded strings break on locale change | LOW (before merge) | Replace string literals with `I18n.t(...)` lookups in test assertions |
| Devise failure messages in wrong locale | LOW | Switch from `around_action` to `before_action` for locale setting |
| `Accept-Language` injection security issue | LOW–MEDIUM | Add `I18n.available_locales` whitelist; covered by `enforce_available_locales = true` |
| `users.locale` migration causes errors with nil values | LOW | Add `locale_for_current_user` nil guard; defaults to `I18n.default_locale` |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Fallbacks masking missing `en.yml` keys | Infrastructure phase (before any extraction) | `raise_on_missing_translations = true` uncommented; `i18n-tasks` passes |
| Tests asserting hardcoded Japanese strings | Every extraction phase (same PR as view) | Grep test files for literal Japanese matching extracted strings |
| `I18n.default_locale` changed at runtime | Locale infrastructure phase | `grep -rn 'I18n.default_locale =' app/` returns zero results |
| Devise + Warden locale (`around_action` conflict) | Locale infrastructure phase | Sign in with wrong password in English locale; flash is in English |
| `devise-i18n` not covering view HTML | Devise auth page translation phase | Sign-in page renders fully in English when locale is `:en` |
| `Accept-Language` injection | Locale detection phase | Pass invalid locale header; app uses default locale, no error |
| Per-user locale not applied on first post-login request | Locale + user preference phase | Log in as English-preference user; first page after login is in English |
| Incomplete extraction (attributes, JS strings) | Every extraction phase | `grep -rn '[^\x00-\x7F]' app/views/` returns zero results |

---

## Sources

- Direct codebase inspection: `config/application.rb`, `config/environments/production.rb`, `config/environments/test.rb`, `app/views/layouts/application.html.erb`, `app/views/common/_menu.html.erb`, `app/views/preferences/index.html.erb`, `app/views/bookmarks/index.html.erb`, `app/controllers/application_controller.rb`, `config/locales/ja.yml`, `config/locales/en.yml`, `Gemfile`
- [Devise uses wrong locale for failure flash messages (issue #5247)](https://github.com/heartcombo/devise/issues/5247)
- [Wrong locale in failure_app (issue #4823)](https://github.com/heartcombo/devise/issues/4823)
- [devise-i18n locale in around_action question (issue #282)](https://github.com/tigrish/devise-i18n/issues/282)
- [Rails PR #34356 — `around_action` recommendation for locale](https://github.com/rails/rails/pull/34356/files)
- [Bad code example for i18n from Accept-Language header (Rails issue #16289)](https://github.com/rails/rails/issues/16289)
- [Foolproof i18n Setup in Rails (thoughtbot)](https://thoughtbot.com/blog/foolproof-i18n-setup-in-rails)
- [Testing i18n in Ruby on Rails: Rooting Out Missing Translations (downey.io)](https://downey.io/blog/testing-i18n-ruby-on-rails-missing-translations/)
- [i18n locale leak between requests (ruby-i18n issue #381)](https://github.com/ruby-i18n/i18n/issues/381)

---
*Pitfalls research for: v1.4 Internationalization — adding bilingual ja/en support to existing Rails 8.1 app*
*Researched: 2026-05-01*
