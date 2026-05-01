---
status: passed
phase: 14-locale-infrastructure
phase_name: Locale Infrastructure
verified: 2026-05-01
verification_method: code_inspection + minitest_suite
requirements_verified:
  - I18N-01
  - I18N-02
  - I18N-03
  - I18N-04
  - VERI18N-01
must_haves_score: "13/13"
test_runs: 127
test_failures: 0
---

# Phase 14 — Locale Infrastructure: Verification Report

## Phase Goal (from ROADMAP.md)

> Users receive every request in a safe, supported locale resolved from account preference, browser language, or Japanese default.

## Verdict: PASSED

すべての must_have、すべての requirement、すべての success criterion が実装と自動テストで満たされている。

## Requirement Traceability

| Req | Description | Phase 14 Coverage | Status |
|-----|-------------|-------------------|--------|
| **I18N-01** | Persisted `locale` value limited to `ja` / `en` | `db/migrate/20260501020618_add_locale_to_preferences.rb` (column) + `Preference::SUPPORTED_LOCALES` constant + `validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true` | ✓ Verified |
| **I18N-02** | Resolution order: saved → Accept-Language → :ja | `Localization#resolved_locale` iterates `[saved_locale, accept_language_match]` with whitelist guard, falls through to `I18n.default_locale` (= `:ja`) | ✓ Verified |
| **I18N-03** | Cannot force unsupported locale via headers/params/stored | **Layered defense**: write-time `validates :locale, inclusion:` (model rejection); read-time `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` runs before every `I18n.with_locale`; boot-time `config.i18n.available_locales = %i[ja en]` + `enforce_available_locales = true` (raises `I18n::InvalidLocale` if anything slips through). No `params[:locale]` is read anywhere. | ✓ Verified |
| **I18N-04** | `<html lang>` attribute matches resolved locale | `app/views/layouts/application.html.erb` line 2: `<html lang="<%= I18n.locale %>">`. ApplicationController includes Localization (`around_action :set_locale` wraps every request via `I18n.with_locale`), so I18n.locale at render time equals the resolved locale. | ✓ Verified |
| **VERI18N-01** | Tests cover saved / Accept-Language / invalid fallback / default | `test/controllers/application_controller_test.rb` exercises all 4 paths via integration tests asserting `<html lang>` attribute directly. | ✓ Verified |

## Must-Haves Cross-Check (per plan)

### Plan 14-01

| Truth | Evidence |
|-------|----------|
| Preference accepts 'ja' / 'en' as locale | `test_localeはsupported_localesのみ有効` first loop iterates SUPPORTED_LOCALES with `assert p.valid?` — all green |
| Preference rejects 'fr' / 'zh' / non-supported | Same test: `p.locale = 'fr'; assert_not p.valid?` and `p.locale = 'zh'; assert_not p.valid?` |
| Preference accepts nil locale | Same test: `p.locale = nil; assert p.valid?` |
| `Preference::SUPPORTED_LOCALES` equals `['ja', 'en']` | Defined as `%w[ja en].freeze` in `app/models/preference.rb` |
| Rails boot restricts `I18n.available_locales` to `[:ja, :en]` | `bin/rails runner 'puts I18n.available_locales.inspect'` outputs `[:ja, :en]` |

### Plan 14-02

| Truth | Evidence |
|-------|----------|
| Every request sets I18n.locale before any view renders | `around_action :set_locale` wraps every action via `I18n.with_locale`; included into `ApplicationController` as first include |
| signed-in user with locale='en' → I18n.locale = :en | `Localization#saved_locale` returns `current_user.preference&.locale`; `resolved_locale` whitelists & symbolizes |
| signed-out + Accept-Language: en → :en | `accept_language_match` is reached when `saved_locale` returns nil (always the case for signed-out users) |
| Accept-Language fr-only → :ja | `parse_accept_language` returns nil when no tag matches `SUPPORTED_LOCALES`; `resolved_locale` falls through to `I18n.default_locale` |
| I18n.locale cannot be set outside SUPPORTED_LOCALES | Whitelist `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` runs BEFORE `I18n.with_locale`; second-layer `enforce_available_locales = true` raises immediately if bypassed |
| Rendered `<html>` carries `lang` matching resolved locale | layout file: `<html lang="<%= I18n.locale %>">` |
| No locale bleed across Puma thread reuse | `around_action` + `I18n.with_locale` saves/restores thread-local locale atomically (block-scoped), unlike `before_action` which leaves the thread-local set |

### Plan 14-03

| Truth | Evidence |
|-------|----------|
| Saved 'en' user sees `<html lang='en'>` | `test_保存済みlocaleがenのユーザは英語でレンダリングされる` — green |
| nil locale + Accept-Language en-US → `<html lang='en'>` | `test_AcceptLanguageがenのリクエストは英語でレンダリングされる` — green |
| nil locale + Accept-Language fr-FR → `<html lang='ja'>` | `test_無効なlocaleは無視されてデフォルトの日本語になる` — green |
| nil locale + no Accept-Language → `<html lang='ja'>` | `test_locale未設定かつAcceptLanguage未指定の場合はデフォルト日本語` — green |
| All 4 VERI18N-01 paths automated | `grep -c 'def test_' test/controllers/application_controller_test.rb` = 4 |

## Phase Success Criteria (from ROADMAP.md)

1. ✓ A signed-in user with a saved `ja` or `en` account locale sees pages rendered in that saved locale. (Test #1 proves)
2. ✓ A first-time or signed-out visitor with a valid `Accept-Language` match sees the app rendered in the matched supported locale. (Test #2 proves; same path also fires for signed-out via `saved_locale` returning nil)
3. ✓ A visitor with no supported language match, invalid locale input, or unsupported stored locale sees Japanese as the safe fallback. (Test #3 + parser whitelist + model validation)
4. ✓ The rendered `<html lang>` attribute matches the locale actually used for the request. (Layout binding + all 4 tests assert it)
5. ✓ User-facing tests prove saved locale, `Accept-Language`, invalid locale fallback/rejection, and default Japanese behavior. (4 tests in ApplicationControllerTest)

## Cross-cutting Constraints (from ROADMAP.md)

- ✓ `Preference::SUPPORTED_LOCALES` is defined in 14-01 and referenced by 14-02 (concern) and exercised by 14-03 (tests). Single source of truth verified.
- ✓ Whitelist guard `SUPPORTED_LOCALES.include?(candidate.to_s)` runs before every `I18n.with_locale` call (in `resolved_locale` and `parse_accept_language`).

## Test Suite Result

```
$ bin/rails test
127 runs, 625 assertions, 0 failures, 0 errors, 0 skips
```

Prior phase test files (10–13) were executed as part of the full suite — no regressions.

## Threats Mitigated

| ID | Description | Disposition |
|----|-------------|-------------|
| T-14-01 | Tampering of `preferences.locale` value via DB write | Mitigated by inclusion validation |
| T-14-02 | Tampering of I18n.available_locales boot config | Mitigated by `enforce_available_locales = true` + restricted list |
| T-14-03 | DoS via `I18n::InvalidLocale` | Mitigated — whitelist guard before with_locale |
| T-14-04 | Information disclosure via lang attribute | Accepted — public, WCAG-required |
| T-14-05 | Spoofing via thread-local I18n.locale persisting | Mitigated — `around_action` + `I18n.with_locale` |
| T-14-06 | Test fixture state shared between tests | Mitigated — each test resets locale explicitly |
| T-14-07 | Test passes by coincidence (default locale) | Mitigated — non-default scenarios assert non-default lang |

## human_verification

なし — Phase 14 のスコープは locale 解決パイプライン基盤のみ（UI 文字列翻訳は Phase 16 以降）。`<html lang>` 属性の切り替えは Minitest 統合テストで完全自動化済み、ユーザ目視で差分が観測できるのは Phase 16 で実 UI 翻訳が入る段階。よって Phase 14 完了に人による UAT は不要。

## Notes for Phase 15 / Onward

- `Preference#locale` は永続化済み、検証済み、Localization concern が読み出して `I18n.locale` に反映する経路が動作中。
- Phase 15 (Language Preference) は `/preferences` フォームに `locale` セレクトを追加するだけで成立する（既存 `open_links_in_new_tab`, `font_size` 追加と同形）。
- Phase 16+（実 UI 翻訳）では `I18n.t(...)` を呼ぶ context に既に `:ja` / `:en` のいずれかが入っている前提で進められる。

---
*Verification: 2026-05-01*
