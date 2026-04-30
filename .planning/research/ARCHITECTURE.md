# Architecture Research

**Domain:** Rails i18n integration — per-user locale with Accept-Language detection
**Researched:** 2026-05-01
**Confidence:** HIGH (verified against Rails i18n guide and devise-i18n README)

## Standard Architecture

### System Overview

```
HTTP Request
    |
    v
ApplicationController#set_locale (before_action)
    |
    +-- authenticated? --> current_user.locale (if set)
    |                          |
    |                     fallback to Accept-Language header
    |                          |
    |                     fallback to I18n.default_locale (:ja)
    +-- not authenticated --> Accept-Language header
                                   |
                              fallback to I18n.default_locale (:ja)
    |
    v
I18n.locale = resolved_locale
    |
    v
Controller action + View (t() / I18n.t())
    |
    v
config/locales/ja.yml  OR  config/locales/en.yml
    |   (app keys)              (app keys)
    |
config/locales/devise.ja.yml  OR  config/locales/devise.en.yml
    (provided by devise-i18n gem -- no copy needed unless customizing)
```

### Component Responsibilities

| Component | Responsibility | Current State |
|-----------|---------------|---------------|
| `ApplicationController#set_locale` | Resolve and apply locale for every request | Does not exist yet -- must add |
| `config/locales/ja.yml` | Japanese translations for all app UI strings | Exists, partial (has `activerecord`, `messages`, `two_factor` keys only) |
| `config/locales/en.yml` | English translations for all app UI strings | Exists, stub only (`hello: "Hello world"`) |
| `users` table -- `locale` column | Persist per-user language preference | Does not exist yet -- migration required |
| `User` model | Validate and expose `locale` attribute | Exists; needs `locale` validation |
| `PreferencesController` | Accept and persist `locale` selection | Exists; needs `locale` update path added |
| `preferences/index.html.erb` | Language switcher UI | Exists; needs locale select row added |
| `devise-i18n` gem | Translate all Devise views/flash messages | Already in Gemfile -- automatic, no config needed |

## Recommended Project Structure

```
config/
  application.rb                          # MODIFIED: add available_locales
  locales/
    ja.yml                                # MODIFIED: extend with all app UI keys
    en.yml                                # MODIFIED: replace stub with all app UI keys

app/
  controllers/
    application_controller.rb             # MODIFIED: add set_locale before_action
  models/
    user.rb                               # MODIFIED: locale validation
  views/
    preferences/
      index.html.erb                      # MODIFIED: add locale select row
    layouts/
      application.html.erb                # MODIFIED: set lang attr on <html>
    [all other views]                     # MODIFIED: replace hardcoded strings with t()

db/
  migrate/
    YYYYMMDDHHMMSS_add_locale_to_users.rb   # NEW
```

### Structure Rationale

- **`locale` on `users`:** `PROJECT.md` defines the v1.4 milestone scope as a `users.locale` column. Locale affects authentication, Devise/Warden failure messages, and first post-login rendering, so it belongs on the account record rather than a presentation-only preference record.
- **`devise-i18n` locale files are not copied:** The gem auto-loads its locale files. Copying them is only needed when customizing specific strings. The gem provides correct `ja` and `en` translations for all Devise messages out of the box.
- **No URL-based locale (`/en/bookmarks`):** This is a personal single-user-oriented app with a persistent preferences page. URL prefixing adds routing complexity for no user-facing benefit. Preference persistence + Accept-Language detection is the correct model.

## Architectural Patterns

### Pattern 1: `before_action` for Locale Setting (NOT `around_action`)

**What:** Set `I18n.locale` in a `before_action` using direct assignment.
**When to use:** Always, in this app. This is the only correct approach when `devise-i18n` is in use.
**Trade-offs:** Direct `I18n.locale =` assignment can leak between requests in a threaded server if not consistently set. The `before_action` guarantee that it runs on every request is the mitigation.

**Critical finding from devise-i18n README:** `around_action` with `I18n.with_locale` does NOT work correctly with Devise/Warden due to a Warden bug. Some Devise error messages bypass the `with_locale` scope and remain untranslated. Use `before_action` with direct assignment. The devise-i18n README documents this explicitly.

```ruby
# app/controllers/application_controller.rb
before_action :authenticate_user!
before_action :configure_permitted_parameters, if: :devise_controller?
before_action :set_locale   # after existing before_actions

private

def set_locale
  I18n.locale = resolve_locale
end

def resolve_locale
  if user_signed_in? && current_user.locale.present?
    current_user.locale.to_sym
  elsif (accept = request.env['HTTP_ACCEPT_LANGUAGE'])
    accepted = accept.scan(/\A[a-z]{2}/).first&.to_sym
    I18n.available_locales.include?(accepted) ? accepted : I18n.default_locale
  else
    I18n.default_locale
  end
end
```

### Pattern 2: `available_locales` Guard in `application.rb`

**What:** Declare supported locales explicitly so unknown values are rejected.
**When to use:** Required. `I18n.config.enforce_available_locales = true` is already active; adding `available_locales` makes the allowed set explicit and prevents locale injection.
**Trade-offs:** None. Low cost, mandatory.

```ruby
# config/application.rb
config.i18n.default_locale = :ja
config.i18n.available_locales = %i[ja en]
```

### Pattern 3: Locale on `users` Table with Validation

**What:** Store locale as a nullable string column in `users`, validated against the supported list.
**When to use:** Persistent per-user locale -- the correct model for an authenticated app.
**Trade-offs:** Requires migration. Far simpler than a session cookie and survives sign-out/sign-in.

```ruby
# Migration
add_column :users, :locale, :string, limit: 10

# app/models/user.rb
SUPPORTED_LOCALES = %w[ja en].freeze
validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true
```

`allow_nil: true` means a blank/null `locale` falls back to Accept-Language then default. No backfill migration needed; existing users get browser detection until they save a preference.

### Pattern 4: Lazy Lookup Scoping in Views

**What:** Use `t('.key')` (dot-prefix) in views to scope keys automatically to the view path. Use top-level `t('shared.key')` for strings shared across views (save, edit, delete, back).
**When to use:** Page-specific labels use lazy scoping. Action words reused in multiple views use `shared.*`.
**Trade-offs:** Lazy lookups create deep key trees (`ja.bookmarks.index.title`). Slightly harder to audit but prevent key collisions across controllers.

```erb
<%# app/views/bookmarks/index.html.erb %>
<th><%= t('.operations') %></th>  <%# resolves to ja.bookmarks.index.operations %>

<%# shared action labels %>
<%= f.submit t('shared.save') %>
```

## Data Flow

### Locale Resolution on Each Request

```
Browser sends request
    |
    v
before_action :set_locale
    |
    +--- user signed in AND current_user.locale present?
    |         YES --> I18n.locale = current_user.locale (e.g., :en)
    |         NO  --> parse HTTP_ACCEPT_LANGUAGE header
    |                     |
    |                     +--- valid available locale found?
    |                               YES --> I18n.locale = that locale
    |                               NO  --> I18n.locale = :ja (default)
    |
    v
All t() calls in controller + views use resolved locale
```

### Locale Preference Save Flow

```
User selects language on /preferences
    |
    v
POST /preferences (PreferencesController#create or #update)
    |
user_params permits: [:locale, { preference_attributes: [...] }]
    |
    v
@user.locale = 'en'
User validates inclusion in SUPPORTED_LOCALES
    |
    v
@user.save! (transaction)
    |
    v
redirect_to action: 'index'
    |
    v
Next request: set_locale picks up current_user.locale = :en
```

### Devise Auth Page Locale Flow

```
Unauthenticated request to /users/sign_in
    |
    v
before_action :set_locale (runs even on Devise controllers via ApplicationController)
    |
    v
Accept-Language header resolves to :en or :ja
    |
    v
I18n.locale = resolved_locale (direct assignment -- bypass Warden bug)
    |
    v
devise-i18n gem serves translated view (ja.yml or en.yml loaded automatically)
    |
    v
Warden/Devise flash messages translated correctly
```

## Integration Points

### ApplicationController (MODIFIED)

Add `before_action :set_locale` after `:authenticate_user!` in the chain so `user_signed_in?` and `current_user` are available inside `resolve_locale`. Devise controller actions inherit `ApplicationController`, so the locale is set for login and registration pages too.

**Change:** Add `before_action :set_locale` + private `set_locale` + `resolve_locale` methods.

### `config/application.rb` (MODIFIED)

Add `config.i18n.available_locales = %i[ja en]` alongside the existing `config.i18n.default_locale = :ja`.

### `users` Table / `User` Model (MODIFIED)

Migration adds `locale` string column (nullable, no default). `User` model gains `SUPPORTED_LOCALES` constant and inclusion validation. Nil means "detect from browser."

### `PreferencesController` (MODIFIED)

Permit `:locale` on the user update path. No new action needed -- the existing preferences save flow can persist the account-level locale alongside preference attributes.

### `preferences/index.html.erb` (MODIFIED)

Add a locale select row to the preferences form, alongside the existing `theme` select. Render options from `I18n.available_locales` mapped to human-readable names.

### `layouts/application.html.erb` (MODIFIED)

Set `lang` attribute on `<html>` tag for screen reader and SEO correctness:

```erb
<html lang="<%= I18n.locale %>">
```

### `devise-i18n` Gem (ALREADY PRESENT -- no action needed)

The gem is already in the `Gemfile`. It auto-loads `devise.ja.yml` and `devise.en.yml` from its gem directory. No copy or generator step is required unless specific strings need customization. The `before_action` locale pattern ensures Devise pages are translated.

### `config/locales/ja.yml` + `config/locales/en.yml` (EXTENDED)

`ja.yml` already has `activerecord.attributes`, `messages`, and `two_factor` keys. All remaining UI strings must be extracted and added to both files: navigation labels, flash messages, button labels, gadget headings, form labels, error messages, and breadcrumb text.

## Build Order

Dependencies drive this sequence. Each phase depends on the one before.

```
Phase 1: Foundation (everything depends on this)
  - Add config.i18n.available_locales to application.rb
  - Add set_locale before_action to ApplicationController
  - Migration: add locale to users
  - User model: validation, SUPPORTED_LOCALES constant
  - PreferencesController: permit :locale in strong params
  RATIONALE: Locale must be resolvable per-request before any t() calls
             can be tested. The column must exist before the switcher UI
             can save. These are the hard dependencies for all later work.

Phase 2: Locale Switcher UI (depends on Phase 1)
  - Add locale select row to preferences/index.html.erb
  - Add lang attribute to layouts/application.html.erb
  RATIONALE: Depends on users.locale column (Phase 1). Enables
             manual testing of all subsequent translation extraction by
             switching between ja and en and verifying output.

Phase 3: Translation Extraction -- Core UI (depends on Phase 1)
  - Extract navigation/layout strings (application.html.erb, _menu.html.erb)
  - Extract preferences page strings
  - Extract flash messages shared across controllers
  - Populate ja.yml and en.yml with all extracted keys
  RATIONALE: Layout and nav strings appear on every page -- extract first
             so the bilingual scaffold is visible across the whole app.
             Preferences page strings must exist before Phase 2 output
             is fully bilingual. Flash messages are tested by existing
             integration tests; keeping them green validates locale wiring.

Phase 4: Translation Extraction -- Gadgets and CRUD (depends on Phase 3)
  - Extract note gadget strings (_note_gadget.html.erb)
  - Extract bookmark CRUD strings (index, form, show, edit)
  - Extract todo CRUD strings
  - Extract calendar and feed strings
  - Add en.yml equivalents for two_factor keys already in ja.yml
  RATIONALE: Individual feature areas are independent within this phase
             and can proceed in any order. Devise views are auto-translated
             by devise-i18n once locale is set -- only the custom two_factor
             keys (already in ja.yml) need corresponding en.yml entries.

Phase 5: Verification (depends on Phases 1-4)
  - Integration tests: set_locale resolves current_user.locale for signed-in users
  - Integration tests: Accept-Language fallback for unauthenticated pages
  - Integration tests: Preference save persists locale, subsequent request uses it
  - Smoke: switch preference to English, verify all pages
  - Smoke: sign out, set Accept-Language: en, verify sign-in page in English
```

## Anti-Patterns

### Anti-Pattern 1: Using `around_action` with `I18n.with_locale`

**What people do:** Follow the standard Rails guide example verbatim.
**Why it's wrong:** Warden (Devise's foundation) processes some callbacks outside the `around_action` block. Devise flash messages (login failure, unauthenticated redirect) are set at the Warden layer and bypass the `with_locale` scope, resulting in untranslated error messages.
**Do this instead:** Use `before_action` with `I18n.locale = resolved_locale` direct assignment. The `devise-i18n` README documents this requirement explicitly.

### Anti-Pattern 2: Storing Locale in the Session

**What people do:** `session[:locale] = params[:locale]` as the persistence mechanism.
**Why it's wrong:** Sessions are tied to browser sessions, not user accounts. If a user signs in on a different device the preference is lost.
**Do this instead:** Persist locale in `users.locale`, consistent with the v1.4 milestone scope and account-level auth behavior.

### Anti-Pattern 3: Copying devise-i18n Locale Files

**What people do:** Run `rails g devise:i18n:locale en` to copy locale files into `config/locales/`.
**Why it's wrong:** Copied files will not receive upstream bug fixes when `devise-i18n` is upgraded. Translation improvements in the gem stay invisible to the app.
**Do this instead:** Let the gem serve its own locale files. Only copy if a specific string genuinely needs overriding.

### Anti-Pattern 4: Deep Lazy-Lookup Keys for Shared Strings

**What people do:** Use `t('.save')` in every view, creating `ja.bookmarks.index.save`, `ja.bookmarks.new.save`, etc., all with value `保存`.
**Why it's wrong:** Duplicate translation values across dozens of keys. Changing "save" copy requires touching every key.
**Do this instead:** Shared action words (`保存 / Save`, `編集 / Edit`, `削除 / Delete`, `戻る / Back`) go under `ja.shared.*` / `en.shared.*`. Only page-specific labels use lazy `t('.')` scoping.

### Anti-Pattern 5: Hardcoding Locale Options in the Preferences View

**What people do:** `<option value="ja">日本語</option><option value="en">English</option>` inline in the form.
**Why it's wrong:** Adding a third locale later requires a view change. The view is not the source of truth for supported locales.
**Do this instead:** Iterate `I18n.available_locales` in the view and use a lookup hash for display names.

## Sources

- Rails i18n Guide -- https://guides.rubyonrails.org/i18n.html (fetched 2026-05-01)
- devise-i18n README (v1.15.0 installed locally) -- documents `before_action` requirement due to Warden bug; Warden issue referenced: https://github.com/wardencommunity/warden/issues/180
- Codebase inspection: `app/controllers/application_controller.rb`, `app/controllers/preferences_controller.rb`, `app/models/preference.rb`, `app/models/user.rb`, `config/application.rb`, `config/locales/ja.yml`, `config/routes.rb`, `app/views/preferences/index.html.erb`, `app/views/layouts/application.html.erb`, `db/schema.rb`

---
*Architecture research for: Rails i18n integration (v1.4 milestone)*
*Researched: 2026-05-01*
