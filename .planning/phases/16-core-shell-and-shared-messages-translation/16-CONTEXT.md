---
phase: 16
phase_name: Core Shell & Shared Messages Translation
phase_slug: core-shell-and-shared-messages-translation
milestone: v1.4
created: 2026-05-01
status: ready-to-plan
---

# Phase 16: Core Shell & Shared Messages Translation - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

このフェーズは v1.4 Internationalization の **アプリ chrome レイヤ** を翻訳する。Phase 14（locale 解決）と Phase 15（`/preferences` ページ + 言語セレクタ）を土台に、ユーザがアプリの「外殻」を ja/en で操作できるようにする。

このフェーズで届けるもの:

1. **共有 shell の翻訳**: `app/views/layouts/application.html.erb` のページタイトル・ヘッダ・ARIA label、`app/views/common/_menu.html.erb` のナビゲーション項目（Home / 設定 / ブックマーク / タスク / カレンダー / フィード / ログアウト / Note）、drawer 内の同等ナビ。
2. **共有 flash / alert の翻訳**: 既存 hardcode 文言（特に `app/controllers/notes_controller.rb:8` の `'エラーが発生しました'` フォールバック）を i18n 化し、今後の controller flash 追加に向けたパターンを確立。
3. **validation-facing labels の有効化**: `errors.full_messages` が ja/en どちらでも自然に出るよう、`rails-i18n` を両 locale に対して有効化し、`activerecord.errors.messages.*` と `errors.messages.*` の defaults を gem からロードする。
4. **キー対称性の確保**: 抽出した shared 文言について `ja.yml` と `en.yml` の双方に同一キーが揃うこと（success criterion 4）。

このフェーズで **触らない** もの:

- Feature surface（bookmarks / notes / todos / feeds / calendars）の view と form 内文言 — **Phase 17** の領分
- Devise auth pages 全体 と `devise-i18n` gem の有効化 — **Phase 18** の領分
- 二段階認証（two_factor）の view 文言 — 既に Phase 15 で keys は揃っているが Devise 周辺扱いとして **Phase 18** で総点検
- JS 側に出る文言 — **Phase 17** 内 TRN-05（server-rendered `data-*` 経由）

</domain>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 16 goal / success criteria / requirement mapping (TRN-01, TRN-04)
- `.planning/REQUIREMENTS.md` — TRN-01, TRN-04, VERI18N-04 definitions
- `.planning/phases/14-locale-infrastructure/14-CONTEXT.md` — locale resolution pipeline (saved → Accept-Language → :ja), `Preference::SUPPORTED_LOCALES`, `Localization` concern, `<html lang>`
- `.planning/phases/15-language-preference/15-CONTEXT.md` — language selector UX, native-label rule, lazy-lookup template-path pitfall
- `.planning/phases/15-language-preference/15-SUMMARY.md` (and 15-01/15-02/15-03 SUMMARY) — `preferences.index.*` namespace, `activerecord.attributes.preference.locale` precedent, redirect-to-self pattern
- `CLAUDE.md` — phase verification policy: `yarn lint` + `bin/rails test` + `bundle exec rake dad:test` must all pass
- `config/locales/ja.yml` / `config/locales/en.yml` — current key inventory; existing `messages.confirm_delete` is the precedent for top-level absolute-keyed shared namespace with `%{name}` interpolation
- `app/views/layouts/application.html.erb` — primary translation target (drawer nav, page title, `aria-label="メニュー"`)
- `app/views/common/_menu.html.erb` — primary translation target (`<title>` is hardcoded `'Bookmarks'`; nav links 6 hardcoded strings)
- `app/controllers/notes_controller.rb:8` — existing hardcoded fallback `'エラーが発生しました'` to be replaced with `t('flash.errors.generic')`
- `app/controllers/users/two_factor_setup_controller.rb` — pre-existing absolute-key flash usage (`t('two_factor.enabled')`) — pattern reference
- Carry-forward pitfalls (Phase 15 lessons):
  - Lazy lookup template-path mismatch — `t('.foo')` in `app/views/X/Y.html.erb` resolves to `X.Y.foo`, NOT `X.foo`
  - Native-label rule — language/script/identity labels stay native across locales
  - Phase 15 `13-CONTEXT.md` and Phase 14 `14-CONTEXT.md` carry-forward: Zeitwerk boot order, Puma thread-local I18n, whitelist-before-`with_locale`
</canonical_refs>

<decisions>
## Implementation Decisions

### Flash & Alert Translation Pattern

The user explicitly discussed this gray area; the four sub-decisions below are LOCKED.

- **D-01: Top-level `flash.*` namespace, absolute keys.** All shared flash and alert strings live under a single top-level `flash.*` namespace in `ja.yml` / `en.yml`, accessed via absolute key (e.g. `t('flash.created', name: ...)`, `t('flash.destroyed', name: ...)`, `t('flash.errors.generic')`). Mirrors the existing `messages.confirm_delete` precedent (already absolute-keyed, top-level, with `%{name}` interpolation, reused across `bookmarks/feeds/todos/calendars` views). NOT lazy-lookup `t('.created')` per controller — the app currently has very few flashes and the shared phrasing would otherwise duplicate. Locale-file-anchored keys are also immune to controller renames.

- **D-02: Interpolation passes record user-content directly via `name:`.** Flash strings that reference a record use `t('flash.X', name: @record.title)` (or equivalent: `@bookmark.title`, `@feed.title`, `@todo.title`, `@calendar.title`, `@note.title`). The interpolated value is **user-entered content** and is intentionally NOT translated. Identical pattern to `messages.confirm_delete` already in use. **No `activerecord.models.*` (model-name) translation work in Phase 16** — defer model-name translation to a later phase if/when a generic "%{model} を削除しました" form is needed.

- **D-03: Single shared `flash.errors.generic` key for the generic error fallback.** The hardcoded `'エラーが発生しました'` literal in `app/controllers/notes_controller.rb:8` (`@note.errors.full_messages.to_sentence.presence || 'エラーが発生しました'`) is replaced by `@note.errors.full_messages.to_sentence.presence || t('flash.errors.generic')`. Phrasing: ja `'エラーが発生しました'`, en `'Something went wrong.'` (final wording confirmed in plan). Same key reused anywhere else in the codebase that needs a generic error fallback. NOT per-controller specific keys — overkill for the current flash volume.

- **D-04: Activate `rails-i18n` for both ja and en.** `gem 'rails-i18n', '~> 8.0'` is already in `Gemfile`. Phase 16 ensures both `:ja` and `:en` validation message defaults are loaded — i.e. `errors.messages.*` and `activerecord.errors.messages.*` come from rails-i18n's bundled translation files. Concretely: confirm `config.i18n.available_locales = %i[ja en]` (set in Phase 14) does NOT prevent rails-i18n's `:en` and `:ja` files from loading; verify with a smoke test that triggering a `presence: true` validation produces a localized message in each locale; if rails-i18n provides ja message but our app has overridden it inadvertently, prefer the gem's defaults and remove our override unless intentional. **`devise-i18n` is intentionally NOT activated in Phase 16** — it is deferred to Phase 18 along with the Devise auth-page translation work, to keep Phase 16 scope tight to "core shell + shared messages" and avoid surfacing Devise UI before Phase 18 owns it.

### Boundary Reaffirmations (carry-forward, not re-discussed)

- **D-05: Lazy-lookup is still allowed for view-anchored partials.** The Phase 15 lesson stands — when a string belongs to a single view/partial (e.g. shell layout title `t('.title')` inside `application.html.erb`), lazy lookup may be used **provided** the yml key exactly matches the view path. For Phase 16, the explicit choice to use absolute keys applies to **flash/alert strings** (D-01) and to **navigation strings shared across layout + drawer + menu**. Per-partial cosmetics may use lazy lookup at the planner's discretion.

- **D-06: Native-label rule applies to in-shell language/script identity.** Phase 15's `自動 / 日本語 / English` precedent stands. Phase 16 does NOT introduce any new language-identity labels, but if a future drawer/menu adds a language toggle indicator, the native-label rule applies.

</decisions>

<deferred>
## Deferred for Research / Planning

The user discussed only the "Flash & alert translation pattern" gray area. The following are deliberately NOT decided here and are left to `gsd-phase-researcher` and `gsd-planner` to surface:

- **Key namespace strategy for non-flash shell strings (nav, layout title, ARIA labels).** Options seen so far:
  - top-level `nav.*` / `shell.*` (absolute, parallel to `flash.*` / `messages.*`)
  - partial-anchored lazy lookup (`common.menu.*`, `layouts.application.*`)
  - hybrid (truly shared → top-level; per-partial cosmetics → lazy)

  Researcher should examine: how many places repeat the same string (e.g. "ホーム" appears in both `application.html.erb` drawer and `common/_menu.html.erb`); whether DRY argues for `nav.home` over duplicating `layouts.application.nav.home` and `common.menu.nav.home`.

- **Phase 16 vs 17 boundary on shared form text.** Specifically: submit/cancel buttons inside feature `_form.html.erb` partials, and `messages.confirm_delete` (already shared). Researcher/planner should propose whether shared form action buttons (`保存` / `キャンセル`) live in `flash.*`-style shared namespace this phase or come over with feature surfaces in Phase 17. Bias: keep Phase 16 conservative — only translate shell-level + already-shared strings; let feature `_form.html.erb` follow in Phase 17 unless they reuse a key already extracted here.

- **Test coverage approach for TRN-01 / TRN-04.** VERI18N-02 (cross-feature E2E i18n verification) is locked to Phase 18. For Phase 16 itself the planner should propose at minimum:
  - a `ja`/`en` parity test that fails when a key exists in one yml but not the other (success criterion 4)
  - a small number of integration tests that hit `/` (or another shell-served path) with each locale and assert localized nav strings appear
  - whether to add Cucumber scenarios for shell — given the documented flakiness in CLAUDE.md, prefer minitest integration tests as the primary green-bar gate; add Cucumber only if a path cannot be exercised via integration tests

- **Page title strategy.** `<title>Bookmarks</title>` in `application.html.erb` is hardcoded. Decide whether to introduce a `content_for(:title)` mechanism with a default of "Bookmarks" (English brand, kept across locales), or fully translate it (`t('layouts.application.title')`). Bias: brand name `Bookmarks` likely stays untranslated (native-brand rule), but ARIA label `'メニュー'` definitely gets translated.

- **Hardcoded literal sweep.** Phase 16 needs a complete inventory of hardcoded Japanese (or other-locale) literals in:
  - `app/views/layouts/`
  - `app/views/common/`
  - `app/controllers/` (flash/notice/alert sites)
  - any helper that produces user-visible chrome strings
  Plan should include the exact list before implementation begins so Wave 1 (yml additions) and Wave 2 (view/controller substitutions) can be sequenced safely.

</deferred>

<scope_creep_notes>
## Scope Creep Captured (not acted on this phase)

(None surfaced during this discussion.)

</scope_creep_notes>

<next_steps>
## Next Steps

1. **Review this CONTEXT.md.** If a deferred item should actually be locked here, edit the file before planning.
2. **Run `/gsd-plan-phase 16`** — researcher will inventory hardcoded literals and propose key-namespace strategy for non-flash strings; planner will sequence yml additions, view/controller edits, rails-i18n activation, and the parity test.
3. **Verification gate (per CLAUDE.md):** `yarn run lint` + `bin/rails test` + `bundle exec rake dad:test` must all pass before Phase 16 is marked complete. Cucumber flakiness policy: re-run once on failure; consistent failure across two runs indicates a real regression.

</next_steps>
</content>
</invoke>