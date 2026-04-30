# Project Research Summary

**Project:** Bookmarks v1.4 — Internationalization
**Domain:** Rails i18n / bilingual UI (ja/en) for an existing Rails personal dashboard
**Researched:** 2026-05-01
**Confidence:** HIGH

## Executive Summary

v1.4 should add bilingual Japanese/English UI through Rails' built-in i18n system, with no frontend framework changes and no JavaScript translation pipeline. The app already has the right foundation: Rails 8.1, `rails-i18n`, `devise-i18n`, server-rendered ERB views, and a preferences page where account settings already live.

The recommended implementation is a small locale infrastructure layer first, followed by incremental string extraction. Locale should be persisted on `users.locale` as defined in `PROJECT.md`, resolved on every request by `ApplicationController`, and selected through `/preferences`. First visits and unauthenticated pages should fall back to a whitelisted `Accept-Language` parse, then `I18n.default_locale` (`:ja`).

The main risks are incomplete English coverage hidden by fallbacks, Devise/Warden messages using the wrong locale, and hardcoded strings surviving in attributes, helper-rendered HTML, JavaScript callbacks, tests, and custom 2FA views. These should be handled by phasing foundation work before extraction, adding locale-specific tests, and verifying Devise failure paths explicitly.

## Reconciled Decisions

### Store locale on `users.locale`

`PROJECT.md` is canonical for v1.4 and explicitly calls for a `locale` column on `users`. Although one architecture note considered `preferences.locale`, this milestone should use `users.locale` because locale affects authentication, Devise/Warden messaging, first post-login rendering, and account identity more than presentation-only preferences.

### Use `before_action :set_locale`

Rails generally recommends `around_action` with `I18n.with_locale`, but this app uses Devise/Warden. Research flags Devise failure flows as a risk when `around_action` resets locale before Warden failure responses are rendered. Use a `before_action` that assigns `I18n.locale = resolved_locale` at the start of every request. Never mutate `I18n.default_locale` at runtime.

The implementation must verify an English-locale failed-login path so Devise flash messages are proven to render in English.

### Avoid new dependencies by default

Manual `Accept-Language` parsing is sufficient for the two supported locales when paired with `I18n.available_locales` whitelisting. Do not add `http_accept_language` unless real browser/header behavior proves the manual parser inadequate.

Do not configure `i18n-js` for v1.4. For isolated JavaScript-visible strings, render translated values into `data-*` attributes from ERB and read those attributes in JavaScript.

### Rely on bundled Devise translations unless customizing

`devise-i18n` is already installed. Let the gem provide default Devise messages and labels unless the app needs custom Devise copy. Custom 2FA views still need explicit `en.yml` counterparts.

## Key Findings

### Recommended Stack

No required new gems or npm packages.

| Component | Recommendation |
|-----------|----------------|
| Locale files | `config/locales/ja.yml` and `config/locales/en.yml` |
| Locale persistence | `users.locale`, nullable string, validated against `ja` / `en` |
| Locale resolution | `ApplicationController` `before_action :set_locale` |
| First-visit fallback | Safely parse `HTTP_ACCEPT_LANGUAGE`, whitelist against `I18n.available_locales` |
| Devise | Use installed `devise-i18n`; verify Warden failure path |
| JavaScript strings | Prefer ERB-rendered `data-*` translated values, not `i18n-js` |

### Table Stakes

- Add `users.locale` and validation.
- Configure `config.i18n.available_locales = %i[ja en]`.
- Resolve locale by priority: `current_user.locale` -> valid `Accept-Language` locale -> `I18n.default_locale`.
- Add a language selector to `/preferences`.
- Extract all hardcoded UI strings in both `ja.yml` and `en.yml`.
- Translate navigation, layout, flash/error messages, bookmarks, notes, todos, feeds, calendar surfaces, custom 2FA views, ARIA/title/placeholder text, and controller alerts.
- Verify Devise auth pages and failure flash behavior in both locales.

### Watch Out For

1. **Fallbacks can mask missing English keys.** Tests should explicitly exercise `:en`, and extraction work should add both locale keys together.
2. **Devise/Warden can bypass `around_action`.** Use `before_action` and verify failed-login flash localization.
3. **Never change `I18n.default_locale` at runtime.** It is global, not request-local.
4. **Whitelist `Accept-Language`.** Never assign raw header values to `I18n.locale`.
5. **Tests currently assert Japanese literals.** Update tests alongside each extracted view/controller surface.
6. **Strings hide in attributes and JS callbacks.** Search for text in `aria-label`, `title`, `placeholder`, submit values, helpers, `.js.erb`, and JavaScript failure handlers.

## Suggested Roadmap Phases

### Phase 14: I18n Foundation

Add `users.locale`, model validation, `available_locales`, safe locale resolution, and request-level tests for user preference, Accept-Language fallback, invalid locale rejection, and default `:ja` behavior.

### Phase 15: Preferences Language Switcher

Add ja/en selector to `/preferences`, persist to `users.locale`, and verify the selected language affects the next rendered page.

### Phase 16: Core Shell Translation

Extract layout, navigation, drawer/menu, shared buttons, preferences page labels, flash strings, and common UI copy to `ja.yml` / `en.yml`.

### Phase 17: Feature Surface Translation

Extract bookmarks, notes, todos, feeds, calendar, forms, validation-facing labels, controller alerts, ARIA/title/placeholder strings, and JS-visible messages via `data-*` values.

### Phase 18: Auth, 2FA, and Verification

Verify Devise and custom 2FA pages, failed-login flash localization, remaining hardcoded strings, English/Japanese smoke paths, and translation coverage.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Rails i18n, rails-i18n, and devise-i18n are already present |
| Features | HIGH | Scope is explicit in `PROJECT.md` and the app surface is small enough to audit |
| Architecture | HIGH | Server-rendered Rails flow keeps locale resolution centralized |
| Pitfalls | HIGH | Main risks are known Rails/Devise i18n failure modes plus extraction completeness |

**Overall confidence:** HIGH

## Sources

- `.planning/PROJECT.md` — v1.4 milestone scope
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`

---
*Research completed: 2026-05-01*
*Ready for requirements: yes*
