---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Verification Debt Cleanup
status: planning
stopped_at: ""
last_updated: "2026-05-03T18:09:05+09:00"
last_activity: 2026-05-03 - Milestone v1.5 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-03 — Milestone v1.5 started

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-03)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Shipped:** v1.1 (2026-04-27), v1.2 (2026-04-29), v1.3 (2026-04-30), v1.4 (2026-05-03)
**Current milestone:** v1.5 — Verification Debt Cleanup

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
- Phase 17 planning artifacts ready: `17-RESEARCH.md`, `17-PATTERNS.md`, approved `17-UI-SPEC.md`, approved `17-VALIDATION.md`, and five execution plans covering TRN-02/TRN-03/TRN-05
- Phase 17 translated feature surfaces for bookmarks, notes, todos, feeds, calendars, and JavaScript-visible feed messages; `BookmarkGadget#title`, `TodoGadget#title`, Todo priority labels, Calendar weekdays/month captions, and feed `data-*` messages are locale-aware while user/external content stays unchanged; final gate green: lint, `bin/rails test` 181/1043, `dad:test` 9/28; code review clean after fix `309965e`
- Phase 18 completed auth/2FA localization verification: `devise.sessions.invalid` exists in ja/en, failed sign-in alerts render via shared `.flash-alert`, auth/OTP/setup tests cover localized paths, VERI18N-03 audit approved with only native labels and `holiday_jp` as intentional exceptions; final gate green: lint, `bin/rails test` 187/1069, `dad:test` 9/28; code review clean after duplicate 2FA alert fixes
- Phase 18.1 closed the v1.4 audit gap: `Localization#saved_locale` now considers the pending 2FA user from `session[:otp_user_id]` when no Devise user is signed in, without signing in early and while preserving the `Preference::SUPPORTED_LOCALES` whitelist. Regression tests cover saved English OTP and stale unsupported locale fallback; full gate green: lint, `bin/rails test` 189/1085, `dad:test` 9/28; code review clean.
- Phase 18.2 is queued to close the remaining v1.4 audit gap: `PreferencesController#create/update` materializes `flash[:notice] = t('preferences.saved')` before redirect while the request still uses the previous locale, so a language-change redirect can render page chrome in the new locale with one save notice from the old locale.

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
| 260501-nyc | modern theme — gadget title bars use primary blue (#3b82f6) instead of classic grey | 2026-05-01 | fb43b2c |
| 260501-onx | stabilize flaky features/02.タスク.feature:5 (task widget scenario) | 2026-05-01 | 60c134b, 93d16db |
| 260501-qlk | fix gadget title link visited color | 2026-05-01 | 8dd9aca |

## Deferred Items

Items acknowledged and deferred at v1.4 milestone close on 2026-05-03:

| Category | Item | Status |
|----------|------|--------|
| verification_gap | Phase 05: 05-VERIFICATION.md | human_needed |
| verification_gap | Phase 06: 06-VERIFICATION.md | human_needed |
| verification_gap | Phase 09: 09-VERIFICATION.md | human_needed |
| uat_gap | Phase 09: 09-HUMAN-UAT.md | passed (0 pending) |
| uat_gap | Phase 12: 12-HUMAN-UAT.md | resolved (0 pending) |
| context_questions | Phase 10: 10-CONTEXT.md | 3 open questions |
| quick_task | 260429-q01-convert-system-tests-to-cucumber | missing |
| quick_task | 260429-q02-rename-default-theme-to-classic | missing |
| quick_task | 260430-pph-modenize-javascript-in-notes-tabs-js | missing |
| quick_task | 260430-pz0-as-shown-in-tmp-ss-png-tabs-are-represen | missing |
| quick_task | 260430-q04-check-readme-outdated-info | missing |
| quick_task | 260430-q05-notes-no-dependent-destroy | missing |
| quick_task | 260501-jmn-fix-cucumber-tests-failing-due-to-recent | missing |
| quick_task | 260501-nyc-modern-theme-gadget-title-bar-color-fix | missing |
| quick_task | 260501-onx-features-02-feature-5-is-flaky | missing |
| quick_task | 260501-q03-simple-theme-note-tab-toggle | missing |
| quick_task | 260501-q04-remove-tweets-table | missing |
| quick_task | 260501-q05-font-size-preference | missing |
| quick_task | 260501-qlk-fix-gadget-title-link-visited-color | missing |
| todo | 2026-04-30-extract-drawer-ui-helper.md | ui (pending) |
| todo | 2026-04-30-gate-drawer-blocks-on-theme.md | ui (pending) |

All items predate v1.4; none block the v1.4 definition of done. Carry forward to v1.5+ planning.

## Session Continuity

Last session: 2026-05-03T08:50:00Z
Stopped at: v1.4 milestone complete — all 7 phases shipped, audit passed, ready to archive
Resume: `/gsd-new-milestone` — start the next milestone cycle
