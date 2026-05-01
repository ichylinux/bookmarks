# Phase 18: Auth, 2FA & Translation Verification - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 18 completes the v1.4 Internationalization milestone by (1) making Devise authentication pages locale-aware, (2) verifying the already-localized 2FA surfaces, and (3) closing the remaining translation gaps and verification requirements.

Specifically:
- **AUTHI18N-01**: Sign-in page and Devise flash/failure messages render in the active locale.
- **AUTHI18N-02**: Custom 2FA authentication and setup pages render in Japanese or English (2FA views already use `t('two_factor.*')` keys — verification required).
- **AUTHI18N-03**: A failed sign-in resolving to English shows the failure message in English.
- **VERI18N-02**: Representative Japanese and English UI paths (layout, preferences, core gadgets, auth, 2FA) are covered by automated tests.
- **VERI18N-03**: Every hardcoded Japanese literal in views/helpers/controllers/JS is either translated or explicitly documented as intentional user/external content (zero unexplained literals).
- **VERI18N-04**: A persistent Minitest test asserts that `ja.yml` and `en.yml` have identical key sets; enforced on every `bin/rails test` run.

Phase 18 does NOT extend features, add new gadgets, or alter routing. It is a translation + verification close-out phase.

</domain>

<decisions>
## Implementation Decisions

### Translation Audit (VERI18N-03)

- **D-01:** Find every hardcoded Japanese literal in views, helpers, controllers, and JavaScript. Translate UI literals into locale keys. Document user-created and external-data content (e.g., `holiday_jp` holiday names carried forward from Phase 17) as intentionally untranslated. The phase ends with zero unexplained hardcoded Japanese strings.

### Key Symmetry Enforcement (VERI18N-04)

- **D-02:** Write a persistent Minitest test that loads both `config/locales/ja.yml` and `config/locales/en.yml`, extracts the full key set from each, and asserts they are identical. This test runs on every `bin/rails test` run and will catch future key-symmetry regressions automatically.

### Claude's Discretion

The user chose to finalize context after discussing only the translation audit decisions. The planner and researcher should decide the remaining implementation details with these biases:

- **Devise sign-in page activation**: `devise-i18n` is already in the Gemfile and was explicitly deferred to this phase (Phase 16 D-04). Prefer the approach that minimizes generated files in `app/views/devise/` — if the devise-i18n engine serves localized views automatically, prefer that. Generate views locally only if needed to support the custom `Users::SessionsController` override or app-specific layout. Cover only the Devise pages that are actively used: sessions (sign-in) at minimum; password reset if present in the app flow.

- **Failed sign-in flash key**: `set_flash_message!(:alert, :invalid)` in `app/controllers/users/sessions_controller.rb` resolves to `devise.sessions.invalid`. This key is NOT in our locale files. Check Devise's fallback chain first (it may fall back to `devise.failure.invalid` which devise-i18n provides). If the fallback doesn't land in the right key, add `devise.sessions.invalid` to both `ja.yml` and `en.yml` following the Phase 16 flash pattern. AUTHI18N-03 requires the English version to render in English when locale is `:en`.

- **VERI18N-02 test type**: Prefer Minitest integration tests for locale-specific assertions (they run faster and integrate with the existing `bin/rails test` gate). Add a Cucumber scenario only if a representative auth + 2FA E2E path cannot be covered adequately with integration tests. Tests should cover at minimum: sign-in page renders in Japanese, sign-in page renders in English, failed sign-in flash appears in the request locale, 2FA OTP page renders in both locales.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements

- `.planning/ROADMAP.md` — Phase 18 goal, success criteria, and requirement mapping (AUTHI18N-01/02/03, VERI18N-02/03/04).
- `.planning/REQUIREMENTS.md` — Full requirement definitions for AUTHI18N-01/02/03 and VERI18N-02/03/04.
- `.planning/PROJECT.md` — v1.4 milestone goal, constraints, and cumulative project decisions.
- `.planning/STATE.md` — current v1.4 progress and Phase 17 artifacts.

### Prior Phase Alignment

- `.planning/phases/14-locale-infrastructure/14-CONTEXT.md` — locale resolution pipeline (`Localization` concern, `around_action :set_locale`, whitelist guard, `I18n.with_locale`, `<html lang>`).
- `.planning/phases/15-language-preference/15-CONTEXT.md` — lazy-lookup template-path pitfall, native-label rule.
- `.planning/phases/16-core-shell-and-shared-messages-translation/16-CONTEXT.md` — Phase 16 D-04 explicitly defers devise-i18n activation to Phase 18; flash namespace (`flash.*`), interpolation pattern, `rails-i18n` activation.
- `.planning/phases/17-feature-surface-translation/17-CONTEXT.md` — `holiday_jp` holiday names documented as intentionally untranslated external data; user/external content boundary rule.

### Auth and 2FA Views

- `app/controllers/users/sessions_controller.rb` — custom Devise sessions controller; `set_flash_message!(:alert, :invalid)` is the failed sign-in flash call; key resolution must be verified.
- `app/controllers/users/two_factor_authentication_controller.rb` — OTP verification controller.
- `app/controllers/users/two_factor_setup_controller.rb` — 2FA enable/disable controller; uses absolute flash keys (`t('two_factor.enabled')`, `t('two_factor.disabled')`).
- `app/views/users/two_factor_authentication/show.html.erb` — OTP entry page; already uses `t('two_factor.verification_title')`, `t('two_factor.code_label')`, `t('two_factor.verify_button')`.
- `app/views/users/two_factor_setup/setup.html.erb` — QR code / manual entry setup page; already fully locale-keyed.
- `app/views/users/two_factor_setup/enabled.html.erb` — 2FA status page; already fully locale-keyed.

### Locale Files

- `config/locales/ja.yml` — current ja locale catalog; `two_factor.*` section already complete; `devise.sessions.*` section may need `invalid` key.
- `config/locales/en.yml` — must remain key-symmetric with ja.yml (enforced by D-02 Minitest test).

### devise-i18n Gem

- `Gemfile` — `gem 'devise-i18n'` already present; railtie auto-loads locale files for `:ja` and `:en`.
- Gem locale file (runtime): `$(bundle show devise-i18n)/rails/locales/ja.yml` and `en.yml` — provide `devise.failure.*`, `devise.sessions.*` (signed_in/out/already_signed_out/new.sign_in) but NOT `devise.sessions.invalid`.

### Coding and Verification Conventions

- `CLAUDE.md` — required phase verification gate: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`.
- `.planning/codebase/CONVENTIONS.md` — Rails view conventions, I18n use, test naming.
- `test/controllers/two_factor_authentication_controller_test.rb` — existing 2FA integration tests to extend with locale assertions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `two_factor.*` locale keys in both `ja.yml` and `en.yml` — 2FA views are already fully locale-keyed; AUTHI18N-02 likely only needs test coverage, not new translation work.
- `flash.errors.generic` key (Phase 16) — pattern for shared generic error fallback; any new generic error messages follow this key.
- `features/support/login.rb` — Cucumber `sign_in` helper handles both 2FA and non-2FA users; reusable for any new Cucumber auth scenarios.
- `test/controllers/two_factor_authentication_controller_test.rb` — 7 existing tests covering sign-in flow with/without 2FA; extend with locale-specific assertions.

### Established Patterns

- Absolute flash keys (`flash.*` namespace) from Phase 16 D-01 — all new flash strings follow this pattern.
- `around_action :set_locale` via `Localization` concern — locale is set per request from preference/Accept-Language/default; auth controllers inherit this via `ApplicationController`.
- Whitelist guard before `I18n.with_locale` (Phase 14 D-04) — locale integrity is already enforced at the controller level.
- Key symmetry: ja.yml and en.yml must be kept in sync (D-02 Minitest test enforces this going forward).

### Integration Points

- Devise's `set_flash_message!` resolves keys via `I18n.t` using the current `I18n.locale` — locale is already set by the time the sessions controller runs; the flash will render in the correct locale automatically if the key exists.
- `app/views/devise/` — currently empty; the devise-i18n engine serves localized views from its own gem path. If local overrides are needed, generate only the required views here.
- `config/locales/ja.yml` and `config/locales/en.yml` — any new keys added in Phase 18 must appear in both files immediately; the D-02 test enforces this.

</code_context>

<specifics>
## Specific Ideas

- The key symmetry Minitest test (D-02) should load both YML files, flatten their key sets, and assert equality. A clear failure message listing the asymmetric keys would help future contributors identify what's missing.
- `holiday_jp` holiday names were explicitly documented as intentionally untranslated in Phase 17 — the Phase 18 audit should carry this forward as a documented exception, not flag them as missing.
- The `set_flash_message!(:alert, :invalid)` key path in `sessions_controller.rb` is the most likely source of AUTHI18N-03 failure if the key is missing. Verify before adding — Devise may fall back to `devise.failure.invalid` which the gem provides in both locales.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 18-auth-2fa-and-translation-verification*
*Context gathered: 2026-05-01*
