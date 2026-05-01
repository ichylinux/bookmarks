---
status: passed
phase: 16-core-shell-and-shared-messages-translation
requirements: [TRN-01, TRN-04]
verified_at: 2026-05-01
verifier: gsd-verifier
---

# Phase 16 Verification

## Verdict

Phase 16 passes verification for its defined scope: core app shell navigation, shared menu/drawer chrome, shared generic flash fallback, and validation-message readiness are available in Japanese and English.

The broader v1.4 translation work still has intentional follow-up scope in Phase 17 and Phase 18. Feature-surface strings such as bookmark/todo form labels, feature breadcrumbs, JavaScript-visible messages, Devise/auth pages, and full cross-feature literal auditing are explicitly deferred by `16-CONTEXT.md` / `16-RESEARCH.md` and mapped to later requirements/phases. They are not Phase 16 gaps.

## Requirement Verification

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TRN-01: User can navigate the app shell in Japanese or English | Passed for Phase 16 core-shell scope | `config/locales/ja.yml` and `config/locales/en.yml` define matching `nav.*` keys. `app/views/layouts/application.html.erb` uses `t('nav.*')` for drawer links and `t('nav.menu_aria')` for the hamburger ARIA label. `app/views/common/_menu.html.erb` uses the same absolute `nav.*` keys for simple-theme menu links, including `nav.note`. `test/controllers/application_controller_test.rb` asserts rendered Japanese and English chrome text plus ARIA labels. |
| TRN-04: User sees flash messages, controller alerts, and validation-facing labels in the active locale | Passed for Phase 16 shared-message scope | `flash.errors.generic` exists in both locale files. `app/controllers/notes_controller.rb` calls `t('flash.errors.generic')` inline at redirect time, avoiding boot-time locale capture. `test/controllers/notes_controller_test.rb` verifies Japanese and English `flash.errors.generic` lookup values. `test/i18n/rails_i18n_smoke_test.rb` verifies `rails-i18n` validation defaults resolve in both locales. ActiveRecord attribute keys are present in both locale files and protected by parity testing. |

## Success Criteria

1. Main layout, menu, drawer navigation, and ARIA labels render according to active locale: passed.
   - Layout drawer links use `t('nav.home')`, `t('nav.preferences')`, `t('nav.bookmarks')`, `t('nav.todos')`, `t('nav.calendars')`, `t('nav.feeds')`, and `t('nav.sign_out')`.
   - Hamburger button uses `aria-label="<%= t('nav.menu_aria') %>"`.
   - Simple-theme menu uses shared `nav.*` keys and preserves the `current_user.preference&.use_note?` gate.
   - Integration tests assert `ホーム` / `設定` / `メニュー` for `ja` and `Home` / `Preferences` / `Menu` for `en`.

2. Shared flash messages and controller alerts render in the active locale: passed.
   - `notes_controller.rb` no longer contains the hardcoded generic Japanese fallback.
   - The fallback is `t('flash.errors.generic')` at the call site.
   - Locale tests assert `エラーが発生しました` for `ja` and `Something went wrong.` for `en`.

3. Validation-facing labels and common validation text render in the active locale: passed for Phase 16 readiness.
   - `rails-i18n` smoke tests prove `errors.messages.blank` resolves for both `ja` and `en`.
   - `ja.yml` and `en.yml` both include matching `activerecord.attributes.*` keys, including the English labels added when the parity gate exposed prior asymmetry.
   - No app-side `errors.messages.*` or `activerecord.errors.messages.*` overrides were introduced, so Rails validation defaults remain delegated to `rails-i18n`.

4. Locale key parity for extracted shared shell and message strings: passed.
   - `test/i18n/locales_parity_test.rb` flattens `config/locales/ja.yml` and `config/locales/en.yml` and asserts identical key sets.
   - `nav.note` remains `Note` in both locales per the native-brand rule.
   - Brand strings in `application.html.erb` (`<title>Bookmarks</title>`, logo alt text, and head-title link) remain intentionally untranslated.

## Code And Test Evidence

- Locale catalogs:
  - `config/locales/ja.yml` contains `nav.home: ホーム`, `nav.note: Note`, `nav.menu_aria: メニュー`, and `flash.errors.generic: エラーが発生しました`.
  - `config/locales/en.yml` mirrors those keys with `Home`, `Note`, `Menu`, and `Something went wrong.`.

- Runtime call sites:
  - `app/views/layouts/application.html.erb` contains one `nav.menu_aria` ARIA binding and seven drawer `nav.*` link bindings.
  - `app/views/common/_menu.html.erb` contains eight simple-theme menu `nav.*` link bindings.
  - `app/controllers/notes_controller.rb` contains one inline `t('flash.errors.generic')` fallback and no constant extraction.

- Automated tests:
  - `test/i18n/locales_parity_test.rb` covers ja/en key parity.
  - `test/i18n/rails_i18n_smoke_test.rb` covers `rails-i18n` validation defaults.
  - `test/controllers/application_controller_test.rb` covers rendered chrome in ja/en.
  - `test/controllers/notes_controller_test.rb` covers shared flash lookup in ja/en.

## Gate Results

Orchestrator-provided final gate results are green:

- `NODENV_VERSION=20.19.4 yarn run lint` — PASS
- `bin/rails test` — PASS (`142 runs, 716 assertions, 0 failures, 0 errors`)
- `bundle exec rake dad:test` — PASS (`9 scenarios, 28 steps`)
- Schema drift — `drift_detected=false`
- Code review — `16-REVIEW.md` status `clean`

Verifier-focused re-run:

- `bin/rails test test/i18n test/controllers/application_controller_test.rb test/controllers/notes_controller_test.rb` — PASS (`18 runs, 75 assertions, 0 failures, 0 errors, 0 skips`)

## Human Verification

None required for pass/fail. Optional visual confirmation may still inspect `/` in both locales to confirm the intentionally untranslated `Bookmarks` brand remains visually acceptable.

## Residual Risk

`notes_controller.rb`'s generic fallback branch is difficult to force through normal validations because `errors.full_messages` is usually populated first. The phase mitigates this with both catalog lookup tests and source-level verification that the controller uses `t('flash.errors.generic')` inline.

Feature-surface literals discovered outside the Phase 16 chrome boundary remain expected work for Phase 17/18, not Phase 16 gaps.
