---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: — Internationalization
status: ready_to_plan
stopped_at: Phase 16 complete — core shell/shared messages translated and verified; ready to discuss/plan Phase 17
last_updated: "2026-05-01T07:20:44.536Z"
last_activity: 2026-05-01
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# State

## Current Position

Phase: 17 (Feature Surface Translation) — ready to discuss/plan
Plan: Not started
Plans: 0/? (planning not yet started)
Last completed: Phase 16 — Core Shell & Shared Messages Translation (3/3 plans, 2026-05-01)
Status: Ready to discuss/plan Phase 17
Last activity: 2026-05-01
Resume: `/gsd-discuss-phase 17` — gather context for Phase 17 Feature Surface Translation

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-01)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.
**Shipped:** v1.1 (2026-04-27), v1.2 (2026-04-29), v1.3 (2026-04-30)
**Current milestone:** v1.4 — Internationalization

## v1.4 Roadmap

| Phase | Name | Status |
|-------|------|--------|
| 14 | Locale Infrastructure | Complete (2026-05-01) |
| 15 | Language Preference | Complete (2026-05-01) — 3/3 plans, 8 new integration tests |
| 16 | Core Shell & Shared Messages Translation | Complete (2026-05-01) — 3/3 plans, full lint/Minitest/dad:test gate green |
| 17 | Feature Surface Translation | Not started |
| 18 | Auth, 2FA & Translation Verification | Not started |

## Accumulated Context

### Shipped in v1.4 so far

- `preferences.locale` nullable string column (migration `20260501020618_add_locale_to_preferences`)
- `Preference::SUPPORTED_LOCALES = %w[ja en].freeze` + `validates :locale, inclusion:` model contract
- `Preference::LOCALE_OPTIONS = { '自動' => nil, '日本語' => 'ja', 'English' => 'en' }.freeze` (Phase 15)
- `Preference::FONT_SIZE_OPTIONS` Hash 削除、`FONT_SIZES` 配列のみ保持 (Phase 15 D-09)
- `config.i18n.available_locales = %i[ja en]` boot-time restriction (combined with `enforce_available_locales = true`)
- `Localization` controller concern (`app/controllers/concerns/localization.rb`) — `around_action :set_locale` (thread-safe), saved → Accept-Language → :ja resolution pipeline
- `ApplicationController` includes `Localization` as the first include
- `<html lang="<%= I18n.locale %>">` in `app/views/layouts/application.html.erb`
- `PreferencesController` — `:locale` permit + 空文字 nil 化 + `redirect_to preferences_path` (Phase 15)
- `app/views/preferences/index.html.erb` — locale select + theme/font_size の `t` 化 + `t('.submit')` (Phase 15)
- `config/locales/ja.yml` / `config/locales/en.yml` — `activerecord.attributes.preference.{font_size, locale}` + `preferences.index.{theme_options, font_size_options, submit}` (Phase 15)
- `test/controllers/preferences_controller_test.rb` — 14 tests (6 既存 + 8 新規) で PREF-01..03 を網羅 (Phase 15)
- `test/controllers/application_controller_test.rb` covers all 4 VERI18N-01 paths via integration tests asserting `<html lang>` attribute (Phase 14)
- `nav.*` + `flash.errors.generic` locale catalog in `config/locales/ja.yml` / `config/locales/en.yml` with ja/en key parity test coverage (Phase 16)
- `app/views/layouts/application.html.erb` drawer nav, `app/views/common/_menu.html.erb` simple-theme menu, and `NotesController#create` generic fallback now consume shared `t(...)` keys (Phase 16)
- `test/controllers/application_controller_test.rb` covers ja/en chrome rendering; `test/controllers/notes_controller_test.rb` covers `flash.errors.generic`; final gate green: lint, `bin/rails test` 142/716, `dad:test` 9/28 (Phase 16)

### Critical Pitfalls (carry forward to Phase 16+)

- **Zeitwerk boot order:** `config/application.rb` cannot reference `Preference::SUPPORTED_LOCALES` (uninitialized constant at boot). Use inline `%i[ja en]` and treat the duplication as documented (with comment).
- **Puma thread reuse:** `I18n.locale` is thread-local; always use `around_action` + `I18n.with_locale` (NEVER `before_action`) to prevent locale bleed across requests reusing the same thread.
- **Whitelist before with_locale:** Even though `enforce_available_locales = true` raises on bad input, the concern MUST whitelist via `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` BEFORE calling `I18n.with_locale` — silent fall-through is the contract for stale DB / malformed Accept-Language values.
- **Lazy lookup template path (Phase 15 lesson):** `t('.foo')` in `app/views/X/Y.html.erb` resolves to `X.Y.foo`, NOT `X.foo`. Phase 15 で Plan 15-02 が `preferences.foo` 直下に置いたキーを `preferences.index.foo` にネストし直す補修が必要だった。Phase 16/17 で view を i18n 化する際、yml キーの階層は view path に完全一致させる必要がある。
- **Native ラベル原則 (Phase 15 lesson):** locale select の `自動 / 日本語 / English` は en 表示時も native のまま (D-02)。同様の「言語 / 通貨 / 国名」など UI 一般慣習に従う場合、Phase 16/17 で再利用可能なパターン。
- **Carry forward from v1.3:** Rails 8.1 `has_many ... delete_all` nullify incompatibility with NOT NULL FK; theme leakage requires both ERB guard + CSS scope; CSRF use `form_with(local: true)`.

## Quick Tasks Completed

| # | Description | Date | Commit |
|---|-------------|------|--------|
| 260501-q01 | Replace Bookmarks nav with Home/Note in simple theme menu | 2026-05-01 | 66f2ebf |
| 260501-q02 | Remove simple-tabstrip nav (superseded by menu links) | 2026-05-01 | f73c484, 090f7cc |
| 260501-q03 | simple theme — Note tab visibility toggle via use_note preference | 2026-05-01 | f7b2267, bf98fd1, d8fb406 |
| 260501-q04 | remove table 'tweets' since there is no reference to it | 2026-05-01 | 3f215d4 |
| 260501-q05 | Font size preference (large, medium, small) | 2026-05-01 | 7ac28f1, e8608a0 |
| 260501-jmn | Fix cucumber regression from Phase 15-01 redirect (`features/step_definitions/todos.rb:7`); add CLAUDE.md phase-verification policy requiring `bundle exec rake dad:test` green | 2026-05-01 | d5311a6, 03c892c |

## Session Continuity

Last session: 2026-05-01T07:20:44Z
Stopped at: Phase 16 complete — 3/3 plans executed, verification passed, code review clean, final gate green
Resume: `/gsd-discuss-phase 17` — Phase 17 (Feature Surface Translation) に進む
