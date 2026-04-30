# Feature Research

**Domain:** Rails i18n / bilingual UI (ja/en) for an existing personal bookmark app
**Researched:** 2026-05-01
**Confidence:** HIGH — scope is tightly constrained by the milestone definition; codebase is fully readable; Rails i18n API is stable and well-documented

## Feature Landscape

### Table Stakes (Users Expect These)

Features that must exist for the "bilingual UI" goal to be real. Missing any one of these = the feature doesn't exist yet.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Extract all hardcoded UI strings to ja.yml / en.yml | Without extraction there is no i18n — hardcoded strings can never switch | MEDIUM | ~22 view files have non-ASCII strings; layout, nav, gadgets, forms, flash messages, and one hardcoded controller alert |
| Lazy `t()` helpers in every view | Standard Rails i18n convention; views must call `t('key')` or `t('.key')` instead of bare strings | LOW | Replace existing bare Japanese strings with `t()` calls; lazy lookup (leading dot) is idiomatic and reduces YAML key verbosity |
| `locale` column on the `users` table | Per-user language preference can only persist if stored in the database | LOW | Single migration: `add_column :users, :locale, :string`; nullable, default nil (falls back to detection logic) |
| Language switcher on `/preferences` | The milestone explicitly requires per-user locale selection from the preferences page | LOW | One `<select>` field (`ja` / `en`) added to the existing preferences form; wires through `PreferencesController#update` with strong-params permit |
| Accept-Language header detection for first visit / unauthenticated | Without this, every first-time or logged-out visitor sees the app in the wrong language | LOW | `before_action :set_locale` in `ApplicationController`; priority chain: `current_user.locale` → parsed `Accept-Language` header → `I18n.default_locale` (:ja) |
| Devise auth page translations | Sign-in, 2FA, password-reset pages use Devise-generated flash keys; untranslated = broken UX on those pages | LOW | `devise-i18n` gem is already in Gemfile and Gemfile.lock (v1.16.0); need to generate locale files (`rails generate devise:i18n:locale ja en`) and ensure Devise flash key translations exist in both locales |
| Flash and validation error translations | Controllers emit flash messages; model validation errors use `activerecord.errors.*` keys; must work in both locales | MEDIUM | Flash messages currently mix hardcoded Japanese strings (e.g., `notes_controller` alert `'エラーが発生しました'`) and `t()` calls; all must be moved to locale files |
| All nav/layout labels translated | The app shell (layout, drawer nav, hamburger button, menu) is the most-visible surface; one untranslated string breaks the impression of "fully bilingual" | LOW | layout.html.erb has 7 hardcoded Japanese strings; common/_menu.html.erb has 6; all have direct English equivalents |
| All gadget UIs translated | Bookmarks, todos, feeds, calendar, and note gadgets all contain Japanese strings | MEDIUM | Mostly LOW complexity per gadget; the feed gadget has a hardcoded error string in a JS `.fail()` callback — needs JS i18n treatment (see Anti-Features) |
| i18n fallback enabled in all environments | If a translation key exists in ja.yml but not en.yml (or vice versa), the app should not crash | LOW | `config.i18n.fallbacks = true` already in `config/environments/production.rb`; must add to `development.rb` and `test.rb` to prevent unexpected crashes in dev/test |

### Differentiators (Competitive Advantage)

Within the context of this personal app, "competitive advantage" means a noticeably smooth bilingual experience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `before_action :set_locale` for Devise/Warden compatibility | Devise failure flash messages render in the selected locale | LOW | Rails generally recommends `around_action`, but this app should use `before_action` because Devise/Warden failure flows can run after `around_action` resets locale |
| Locale persisted on `users.locale` (not in session or cookie) | Locale follows the user account across devices and browsers — no re-selection needed | LOW | After login, `switch_locale` reads `current_user.locale`; the preferences form writes it back through the existing `PreferencesController#update` path |
| Detect Accept-Language on first visit, then respect saved preference | Correct "zero-config" experience: new user sees app in their browser language immediately; then can override and have that choice stick | LOW | Priority chain in `switch_locale`: DB preference (highest) → Accept-Language header → default :ja; the `http_accept_language` gem is not installed but the header can be parsed with one line (`request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first`) |
| `config.i18n.available_locales = [:ja, :en]` guard | Prevents unknown locale injection via URL tampering or corrupted DB values | LOW | Sanitize the value extracted from user/header against `I18n.available_locales` before assigning `I18n.locale` |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Translate inline JS strings via i18n-js | The feed gadget has a hardcoded Japanese error string inside a JS `.fail()` callback; naturally one wants to translate it with i18n-js | The `i18n-js` gem (already in Gemfile at v4.2.4) requires a build/export step (`rails i18n:js:export`) that generates a JS file from locale YAMLs. This adds a build-time step, a generated asset to maintain, and a JS loading concern. For a single string it is disproportionate. | Move the error string to a `data-` attribute on the gadget container rendered by ERB, then read it in the JS `.fail()` callback. Zero new infrastructure. |
| URL-based locale (e.g., `/en/bookmarks`) | Common in public-facing Rails apps; some tutorials recommend it | This is a private, always-authenticated app. URL segments for locale add route complexity (scope blocks, locale param threading through all `link_to` helpers, existing JS `.post()` calls would need updating) for no user benefit. | Store locale in the user record + Accept-Language detection. URL segments are unnecessary for a private app. |
| Separate locale-namespaced YAML files per controller (e.g., `en/bookmarks.yml`) | Feels organized for large apps | This app has a small, stable translation surface. Splitting into many files adds lookup friction and YAML management overhead with no benefit at this scale. | Two flat files (`ja.yml`, `en.yml`) with logical grouping by section is maintainable and is exactly what the existing `ja.yml` already does. |
| Pluralization and complex number formatting | Rails i18n supports pluralization rules (`:one`, `:other`, `:many`) | The current app has no count-sensitive strings. Adding pluralization keys for strings that don't need them clutters the YAML and creates false requirements. | Extract strings as-is; add pluralization only when a specific string genuinely needs it. |
| Language switcher in the page header (always visible) | More discoverable | Adds visual clutter to every page for a setting that users change rarely. The preferences page is the correct home for account-level settings. | Language switcher lives on `/preferences` only, consistent with how theme selection works. |

## Feature Dependencies

```
[Language switcher on /preferences]
    └──requires──> [locale column on users table]
                       └──requires──> [migration: add_column :users, :locale, :string]

[Per-user locale persistence]
    └──requires──> [locale column on users table]
    └──requires──> [PreferencesController strong-params: permit :locale]

[before_action :set_locale in ApplicationController]
    └──requires──> [locale column on users table (to read current_user.locale)]
    └──requires──> [config.i18n.available_locales = [:ja, :en] guard]

[Accept-Language detection]
    └──enhances──> [before_action :set_locale — used as fallback when user has no saved locale]

[t() calls in views]
    └──requires──> [ja.yml / en.yml keys extracted first]

[Devise auth page translations]
    └──requires──> [devise-i18n locale files generated (already gem is installed)]
    └──requires──> [before_action :set_locale — Devise pages must respect current locale]

[Flash / validation error translations]
    └──requires──> [ja.yml / en.yml keys for all flash strings]
    └──requires──> [before_action :set_locale — flash messages are rendered after redirect, locale must be consistent]

[i18n fallback in dev/test]
    └──enhances──> [all t() calls — prevents MissingTranslationData crashes during development]
```

### Dependency Notes

- **Migration must come first.** Every other feature depends on the `locale` column existing. Run the migration before touching the switcher, preferences form, or `switch_locale` logic.
- **`set_locale` must land before any view string extraction.** Once the `before_action` is in place, locale switching works immediately even for partially-translated views. Extract strings incrementally after that.
- **Devise locale files depend on `set_locale`.** Devise renders its own flash messages using whatever `I18n.locale` is set to at request time. The `before_action` must run for Devise controllers, which it will since it is in `ApplicationController`.
- **`devise-i18n` is already installed** (v1.16.0 in Gemfile.lock). No new gem needed — only the locale file generation step is missing.
- **`rails-i18n` is already installed** (v8.1.0). This provides `activerecord.errors.*` base translations for both ja and en for free. Do not re-translate what rails-i18n already provides.

## MVP Definition

### Launch With (v1.4)

Everything needed to deliver a fully bilingual app.

- [ ] Migration: `add_column :users, :locale, :string` (nullable, no default)
- [ ] `config.i18n.available_locales = [:ja, :en]` in `application.rb`
- [ ] `before_action :set_locale` in `ApplicationController` with priority chain: `current_user&.locale` → Accept-Language header → `:ja`
- [ ] Language switcher (`<select>`) on `/preferences` form with `ja` / `en` options; wired through existing `PreferencesController#update`
- [ ] All hardcoded UI strings in views extracted to `ja.yml` and `en.yml`; views use `t('key')` or `t('.key')` lazy lookup
- [ ] All hardcoded flash messages / controller alerts moved to locale keys; `t('...')` used at call site
- [ ] Devise i18n locale files generated (`rails generate devise:i18n:locale ja en`) and verified
- [ ] `i18n.fallbacks = true` added to `development.rb` and `test.rb` (already on in production)
- [ ] Feed gadget inline JS error string moved to a `data-` attribute on the ERB container instead of i18n-js

### Add After Validation (v1.x)

- [ ] `http_accept_language` gem — replace one-line header parse with robust gem if Accept-Language parsing proves unreliable in practice
- [ ] `i18n-tasks` gem — detect missing/unused translation keys as project grows

### Future Consideration (v2+)

- [ ] i18n-js for JS-side translations — only if a future milestone adds enough JS-rendered strings to justify the build step
- [ ] URL-based locale segment — only if the app ever becomes public/multi-user-facing

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Migration: locale column | HIGH | LOW | P1 — unblocks all other features |
| `set_locale` before_action | HIGH | LOW | P1 — locale logic backbone |
| Language switcher on /preferences | HIGH | LOW | P1 — user-facing control |
| String extraction (views) | HIGH | MEDIUM | P1 — makes bilingual UI real |
| Flash/error string extraction | HIGH | MEDIUM | P1 — broken flash = broken UX |
| Devise locale files | HIGH | LOW | P1 — auth pages must work in both locales |
| i18n fallbacks in dev/test | MEDIUM | LOW | P1 — prevents crashes during incremental extraction |
| Accept-Language detection | MEDIUM | LOW | P1 — correct first-visit experience |
| Feed gadget data- attribute fix | LOW | LOW | P1 — avoids i18n-js dependency |
| available_locales guard | MEDIUM | LOW | P1 — security/correctness |
| http_accept_language gem | LOW | LOW | P2 — header parsing is adequate without it initially |
| i18n-tasks gem | MEDIUM | LOW | P2 — useful but not blocking launch |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Internal Reference (No External Competitors)

This is a private personal app, not a public product. The "competitor" reference is the expected behavior of any modern bilingual Rails app.

| Feature | Rails convention | This app's current state | Gap |
|---------|-----------------|--------------------------|-----|
| Locale per request with Devise compatibility | `before_action :set_locale` | No locale switching at all | Must add |
| Per-user preference | DB column + preferences form | Preferences pattern exists; no `locale` column | Migration + form field |
| Accept-Language fallback | Parse `HTTP_ACCEPT_LANGUAGE` header | Not implemented | One method in `switch_locale` |
| View string extraction | `t()` / `t('.')` lazy lookup | Partial — `ja.yml` has `activerecord.attributes` and `two_factor.*` keys; views still have hardcoded strings | Extract remaining strings |
| Devise translations | `devise-i18n` gem | Gem is installed but locale files not generated | Run generator |
| Rails model error messages | `rails-i18n` gem | Gem is installed (v8.1.0); provides ja/en base keys | Verify; no custom overrides needed |

## Sources

- Codebase review: `/home/ichy/workspace/bookmarks/app/`, `config/locales/`, `config/application.rb`, `Gemfile`, `Gemfile.lock`, `db/schema.rb`
- Milestone definition: `/home/ichy/workspace/bookmarks/.planning/PROJECT.md` (v1.4 Active requirements)
- Rails i18n guide: https://guides.rubyonrails.org/i18n.html (locale setting patterns, Accept-Language, lazy lookup)
- devise-i18n gem: https://github.com/tigrish/devise-i18n (locale file generator, key structure)
- rails-i18n gem: https://github.com/svenfuchs/rails-i18n (provides base ja/en activerecord error translations)
- Phrase Rails i18n guide: https://phrase.com/blog/posts/rails-i18n-setting-and-managing-locales/ (per-user locale pattern)

---
*Feature research for: Rails i18n / bilingual UI (ja/en) — v1.4 milestone, personal bookmark app*
*Researched: 2026-05-01*
