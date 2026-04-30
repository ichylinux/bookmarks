# Stack Research

**Domain:** Rails i18n / Bilingual (ja/en) support with per-user locale preference
**Researched:** 2026-05-01
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Rails I18n framework | Built into Rails 8.1.3 (already present) | `t()` / `I18n.t()` helper, YML locale files, `I18n.with_locale` | Zero new dependencies; `config/locales/*.yml` is the Rails standard and already partially populated in this app (`ja.yml`, `en.yml` exist) |
| `rails-i18n` gem | 8.1.0 (already in Gemfile.lock) | Provides Rails ActiveRecord/ActionView locale data (validation messages, date formats, number formats) for `:ja` and `:en` | Without this gem, Rails' built-in messages (e.g., "can't be blank") would only appear in English; the 8.1.0 release (Nov 2025) matches the app's Rails 8.1.x series exactly |
| `devise-i18n` gem | 1.16.0 (already in Gemfile.lock) | Devise flash messages and view labels in both locales | Devise flash strings bypass normal controller locale flow via Warden middleware; this gem provides the ja/en translation keys that Devise looks up internally. Version 1.16.0 released Feb 2026. |
| `before_action :set_locale` | Rails 8.1 built-in | Per-request locale setting in `ApplicationController` | Safer for this Devise/Warden app because failure responses can run outside an `around_action` locale scope. Set `I18n.locale` at the start of every request; never mutate `I18n.default_locale` at runtime. |
| `users.locale` column (string) | New migration | Persists per-user language choice in the database | The `preferences` table already stores per-user boolean/string flags (theme, use_note, use_todo); locale follows the same pattern. Storing on `users` (not `preferences`) is simpler — locale is a core user attribute, not a display preference. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `http_accept_language` gem | 2.1.1 | Parse `Accept-Language` header for unauthenticated / first-visit locale detection | Add this gem. Handles quality-value (`q=`) weighting, language subtag normalization, and matching against `I18n.available_locales`. The `compatible_language_from` method returns the best match or `nil`. Last release 2017 but stable; no known Rails 8 incompatibilities. |
| `i18n-js` gem | 4.2.4 (already in Gemfile) | Export Rails YML translations to JSON for JavaScript consumption | **Do not configure for this milestone.** No JavaScript in the app currently calls `I18n.t()`; all `messages.confirm_delete` usages are ERB `t()` calls rendered server-side. The gem is in the Gemfile but uninitialized — leave it dormant. See "What NOT to Use" below. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `rails g devise:i18n:locale ja` | Generate a custom Devise ja locale file into `config/locales/` | Run once if you need to override or extend any Devise key beyond what the gem ships. Not required if the bundled translations are sufficient. |
| `I18n.available_locales` check in test | Guard against typo locale strings in fixtures/tests | Set `I18n.available_locales = %i[ja en]` in `config/application.rb`; `I18n.enforce_available_locales = true` (already set) will raise on unknown locales. |
| Minitest `I18n.with_locale(:en) { }` block | Test English-locale path in controller/integration tests | Wrap assertions that check English strings inside an explicit locale block; avoids fixture-locale coupling |

## Installation

```bash
# Add http_accept_language to Gemfile (one new gem)
bundle add http_accept_language

# Generate migration for users.locale column
bundle exec rails generate migration AddLocaleToUsers locale:string

# (Optional) Generate custom Devise locale override files
bundle exec rails g devise:i18n:locale ja
bundle exec rails g devise:i18n:locale en
```

No `package.json` or Sprockets changes. No Gemfile changes for `rails-i18n` or `devise-i18n` — both already present.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `locale` column on `users` table | `locale` column on `preferences` table | Use `preferences` only if locale is conceptually a display preference and you want a single migration target. `users` is cleaner: locale affects auth flows and Devise emails, not just UI display. |
| `before_action { I18n.locale = ... }` | `around_action` + `I18n.with_locale` | `around_action` is the general Rails recommendation, but use `before_action` in this app so Devise/Warden failure messages see the resolved locale. Verify failed-login flash localization in English. |
| `http_accept_language` gem | Manual `request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first` | Use the manual approach only in trivial apps. The gem handles quality weighting, wildcards, and nil-safety correctly. The Rails guide itself recommends using "a library like the http_accept_language gem" for production. |
| `users.locale` as a `string` column | `users.locale` as an enum | Use enum if you want database-level constraint. For two locales, a plain `string` with application-layer validation (`validates :locale, inclusion: { in: %w[ja en] }, allow_nil: true`) is simpler and easier to extend later. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `i18n-js` v4 Sprockets integration (configuring the gem) | `i18n-js` v4 was redesigned for modern JS bundlers (webpack, esbuild, Vite). It requires a companion `i18n-js` npm package (`yarn add i18n-js`) and uses ESM `import` syntax. Wiring it into a Sprockets `application.js` manifest is unsupported and would require manual `//= require` shims that break under Uglifier minification. The gem is already in the Gemfile but unused — leave it that way. | All translatable strings in this app are rendered server-side via `t()` in ERB views. No JavaScript i18n is needed for this milestone. |
| `globalize` / `mobility` gem (model-level translations) | These gems translate database-stored *content* (e.g., bookmark titles stored in multiple languages). This milestone translates *UI strings*, not user content. | Rails `config/locales/*.yml` for UI string translation |
| URL-based locale (`/ja/bookmarks`, `/en/bookmarks`) | Requires routing changes, redirect logic for all existing routes, and changes to every `link_to` / `redirect_to` call in the app. Disproportionate effort for a personal app with authenticated users who have a stored preference. | Per-user `locale` column + `Accept-Language` for guests |
| Locale stored in the session | Session-based locale is lost on sign-out and does not survive across devices/browsers. | Database column on `users` (persists per-account across sessions) |
| Locale stored in a cookie | Cookie locale is device-local and not synced to the user account. | Database column on `users` |

## Stack Patterns

**ApplicationController locale switching (canonical pattern):**

```ruby
before_action :set_locale

private

def set_locale
  I18n.locale = locale_for_current_request
end

def locale_for_current_request
  if user_signed_in? && current_user.locale.present?
    current_user.locale
  else
    http_accept_language.compatible_language_from(I18n.available_locales)
  end || I18n.default_locale
end
```

**`config/application.rb` additions:**

```ruby
config.i18n.available_locales = %i[ja en]
config.i18n.default_locale = :ja   # already set
```

**Devise i18n note:**

Use `before_action` from the start. The `devise-i18n` README documents Warden failure-app locale issues with `around_action`; this milestone must include an English wrong-password check to prove Devise flash localization works.

**`users` migration:**

```ruby
class AddLocaleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locale, :string, limit: 10
  end
end
```

**Locale strings:** Store as `"ja"` / `"en"` (string), not symbols. Symbols cannot be stored in a string column. Cast on read: `current_user.locale&.to_sym`.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `rails-i18n` 8.1.0 | Rails 8.1.x, Ruby 3.4 | Exact version match to app's Rails series. Gemfile pin `~> 8.0` allows patch-level updates within the 8.x series — correct. |
| `devise-i18n` 1.16.0 | Devise 5.0.3 | devise-i18n tracks Devise releases; 1.16.0 (Feb 2026) is the current release matching Devise 5. |
| `http_accept_language` 2.1.1 | Rails 8.1 (Rack middleware) | No Rails version dependency in the gem itself; it is pure Rack middleware. Works with Puma 8 multi-threaded (thread-safe). Last release 2017 but actively used; no known Rails 8 incompatibility. |
| `i18n` 1.14.8 | Rails 8.1 transitive dependency | Already resolved in Gemfile.lock. Do not pin independently — let Rails manage it. |

## Sources

- `/svenfuchs/rails-i18n` (Context7) — locale configuration snippets
- `/tigrish/devise-i18n` (Context7) — `before_action` pattern, Warden bug note
- `/fnando/i18n-js` (Context7) — v4 requires npm companion; Sprockets unsupported
- https://guides.rubyonrails.org/i18n.html — `around_action` / `I18n.with_locale` recommendation, Accept-Language header pattern, per-user stored locale example
- https://rubygems.org/gems/rails-i18n — version 8.1.0 confirmed (Nov 2025)
- https://rubygems.org/gems/devise-i18n — version 1.16.0 confirmed (Feb 2026)
- https://rubygems.org/gems/i18n-js — version 4.2.4 confirmed (Oct 2025)
- https://rubygems.org/gems/http_accept_language — version 2.1.1 (2017, stable)
- https://github.com/heartcombo/devise/issues/4823 — Warden failure-app locale bug report
- Existing app Gemfile.lock — confirmed currently installed versions

---
*Stack research for: Rails i18n bilingual (ja/en) support — v1.4*
*Researched: 2026-05-01*
