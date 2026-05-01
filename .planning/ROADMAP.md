# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 — Quick Note Gadget** — Phases 10–13 (shipped 2026-04-30) — [archived](milestones/v1.3-ROADMAP.md)
- 🚧 **v1.4 — Internationalization** — Phases 14–18.1 (gap closure after milestone audit)

## Phases

### Active Milestone: v1.4 — Internationalization

**Goal:** Make the app bilingual in Japanese and English with persisted per-user locale preference and safe first-visit language detection.

| Phase | Milestone | Requirements | Status | Depends on |
|-------|-----------|--------------|--------|------------|
| 14. Locale Infrastructure | v1.4 | I18N-01, I18N-02, I18N-03, I18N-04, VERI18N-01 | Complete (3/3 plans, 2026-05-01) | v1.3 complete |
| 15. Language Preference | v1.4 | PREF-01, PREF-02, PREF-03 | Complete (3/3 plans, 2026-05-01) | Phase 14 |
| 16. Core Shell & Shared Messages Translation | v1.4 | 3/3 | Complete    | 2026-05-01 |
| 17. Feature Surface Translation | v1.4 | TRN-02, TRN-03, TRN-05 | Complete (5/5 plans, 2026-05-01) | Phase 16 |
| 18. Auth, 2FA & Translation Verification | v1.4 | AUTHI18N-01, AUTHI18N-02, AUTHI18N-03, VERI18N-02, VERI18N-03, VERI18N-04 | Complete (3/3 plans, 2026-05-02) | Phase 17 |
| 18.1. 2FA Pending Locale Resolution | v1.4 | I18N-02, AUTHI18N-02, VERI18N-02 | Not started — gap closure | Phase 18 + v1.4 audit |

#### Phase 14: Locale Infrastructure

**Goal:** Users receive every request in a safe, supported locale resolved from account preference, browser language, or Japanese default.

**Requirements:** I18N-01, I18N-02, I18N-03, I18N-04, VERI18N-01

**Plans:** 3 plans

Plans:

**Wave 1**
- [x] 14-01-PLAN.md — Data layer: migration + Preference model constants/validation + I18n available_locales config (completed 2026-05-01)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 14-02-PLAN.md — Localization concern + ApplicationController wiring + html lang layout attribute (completed 2026-05-01)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 14-03-PLAN.md — Integration tests: 4 VERI18N-01 paths in ApplicationControllerTest (completed 2026-05-01)

**Cross-cutting constraints:**
- `Preference::SUPPORTED_LOCALES` (defined in 14-01) is the single source of truth referenced by both the concern (14-02) and tests (14-03)
- Whitelist guard `SUPPORTED_LOCALES.include?(candidate.to_s)` must run before every `I18n.with_locale` call (14-01 defines, 14-02 enforces)

**Success criteria:**
1. A signed-in user with a saved `ja` or `en` account locale sees pages rendered in that saved locale.
2. A first-time or signed-out visitor with a valid `Accept-Language` match sees the app rendered in the matched supported locale.
3. A visitor with no supported language match, invalid locale input, or unsupported stored locale sees Japanese as the safe fallback.
4. The rendered `<html lang>` attribute matches the locale actually used for the request.
5. User-facing tests prove saved locale, `Accept-Language`, invalid locale fallback/rejection, and default Japanese behavior.

#### Phase 15: Language Preference

**Goal:** Users can choose Japanese or English from preferences and have that choice persist across sessions.

**Requirements:** PREF-01, PREF-02, PREF-03

**Success criteria:**
1. A signed-in user can select Japanese or English from the existing `/preferences` page.
2. After saving, the selected language controls the next rendered page.
3. The selected language persists after browser refresh, sign-out, sign-in, and future sessions.
4. The preferences page itself renders in the newly selected language after the change.

**Plans (completed 2026-05-01):**

**Wave 1** *(parallel — no shared files)*
- [x] `15-01-PLAN.md` Backend wiring — `Preference::LOCALE_OPTIONS` 定数、controller の `:locale` permit + 空文字 nil 化 + `redirect_to preferences_path`、既存 test_更新 redirect URL 更新。`FONT_SIZE_OPTIONS` Hash 削除（D-09 Plan 段階決定） *(completed 2026-05-01)*
- [x] `15-02-PLAN.md` I18n catalog — `ja.yml` に `preference.locale / preference.font_size / preferences.index.{theme_options, font_size_options, submit}` 追加、`en.yml` を Phase 15 スコープでフル構築 *(completed 2026-05-01)*

**Wave 2** *(blocked on Wave 1 completion)*
- [x] `15-03-PLAN.md` View + integration tests — `f.select :locale`、theme/font_size の `t` 化、`f.submit t('.submit')`、`f.label :font_size` override 削除、`preference_params` helper 拡張、PREF-01..03 を証明する 8 件の Minitest 統合テスト追加 *(completed 2026-05-01)*

**Cross-cutting constraints:**
- ロケールセレクタ ラベル（`自動 / 日本語 / English`）は **native 表記固定**で i18n を経由しない（D-02）
- `nil` は first-class state として保持（フォーム送信で空文字 → `.presence` で nil 正規化、D-04..D-06）
- `redirect_to preferences_path` は locale 変更時に限らず **一律変更**（D-11、Plan 15-01 と Plan 15-03 のテストの両方に整合）

#### Phase 16: Core Shell & Shared Messages Translation

**Goal:** Users can navigate the app chrome and shared UI messages in Japanese or English.

**Requirements:** TRN-01, TRN-04

**Success criteria:**
1. The main layout, menus, drawer navigation, shared buttons, breadcrumbs, titles, placeholders, and ARIA labels render in Japanese or English according to the active locale.
2. Shared flash messages and controller alerts render in the active locale.
3. Validation-facing labels and common form text render in the active locale.
4. Both `config/locales/ja.yml` and `config/locales/en.yml` contain matching keys for extracted shared shell and message strings.

**Plans:** 3/3 plans complete

Plans:

**Wave 1**
- [x] 16-01-PLAN.md — yml catalog (nav.* + flash.errors.generic) + parity test + rails-i18n smoke test

**Wave 2** *(blocked on Wave 1)*
- [x] 16-02-PLAN.md — Layout + simple-theme menu substitutions + notes_controller flash substitution

**Wave 3** *(blocked on Wave 2)*
- [x] 16-03-PLAN.md — Integration tests (TRN-01 chrome ja+en, TRN-04 flash.errors.generic ja+en) + full CLAUDE.md verification gate

#### Phase 17: Feature Surface Translation

**Goal:** Users can use the app's core bookmark, note, todo, feed, calendar, and JavaScript-visible UI in Japanese or English.

**Requirements:** TRN-02, TRN-03, TRN-05

**Success criteria:**
1. Bookmark screens can be used in Japanese or English without hardcoded UI strings.
2. Notes, todos, feeds, and calendar gadget surfaces can be used in Japanese or English without hardcoded UI strings.
3. JavaScript-visible messages render in the active locale through server-rendered translated values such as `data-*` attributes, without adding `i18n-js` or a JavaScript i18n build pipeline.
4. User-created content such as bookmark titles, note bodies, todos, and feed content remains unchanged and is not treated as translatable UI chrome.

**Plans:** 5 plans

Plans:

**Wave 1**
- [x] 17-01-PLAN.md — Locale catalog + translation primitives (ja/en key skeleton, fixed gadget titles, Todo priority helpers, Calendar weekday/month primitives)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 17-02-PLAN.md — Bookmark feature surface translation with bookmark/folder user content preserved
- [x] 17-03-PLAN.md — Note and Todo feature surfaces, Todo priority display, and default priority preference select

**Wave 3** *(blocked on Wave 1 completion)*
- [x] 17-04-PLAN.md — Feed, Calendar, and JavaScript-visible strings via server-rendered translated values

**Wave 4** *(blocked on Waves 2 and 3 completion)*
- [x] 17-05-PLAN.md — Representative bilingual validation and full lint/Minitest/dad:test gate

**Cross-cutting constraints:**
- Fixed app UI labels translate; user-created/external content remains unchanged (`BookmarkGadget#title` and `TodoGadget#title` localize, Feed/Calendar record titles do not).
- Todo priority labels localize at display time while stored numeric values remain unchanged.
- Calendar month/year and weekday labels localize; `holiday_jp` holiday names remain intentionally Japanese external data.
- JavaScript-visible strings use server-rendered translated values such as `data-*`; no `i18n-js`, JS translation registry, or new build pipeline.

#### Phase 18: Auth, 2FA & Translation Verification

**Goal:** Users see authentication, 2FA, and representative app flows correctly localized, with remaining translation gaps caught.

**Requirements:** AUTHI18N-01, AUTHI18N-02, AUTHI18N-03, VERI18N-02, VERI18N-03, VERI18N-04

**Plans:** 3 plans

Plans:

**Wave 1**
- [x] 18-01-PLAN.md — devise.sessions.invalid locale key (ja + en) + flash[:alert] in application layout + .flash-alert CSS rule (completed 2026-05-02)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 18-02-PLAN.md — New sessions_controller_test.rb (4 tests: sign-in page ja/en + failed flash ja/en) + 2FA OTP locale tests (extend existing test file) (completed 2026-05-02)
- [x] 18-03-PLAN.md — Full phase gate (lint + minitest + dad:test) + VERI18N-03 audit sign-off checkpoint (completed 2026-05-02)

**Success criteria:**
1. Devise authentication pages and Devise flash/failure messages render in the active locale.
2. Custom two-factor authentication and setup pages render in Japanese or English.
3. A failed sign-in request resolved to English shows the first failure message in English.
4. Representative Japanese and English UI paths cover layout, preferences, core gadgets, authentication, and 2FA surfaces.
5. Remaining user-visible Japanese literals in views, helpers, controllers, and JavaScript are translated or explicitly documented as intentional user/content data, with matching keys present in both locale files.

#### Phase 18.1: 2FA Pending Locale Resolution

**Goal:** A user with a saved locale preference keeps that locale on the 2FA OTP challenge page while they are between password authentication and OTP completion.

**Requirements:** I18N-02, AUTHI18N-02, VERI18N-02

**Gap Closure:** Closes `otp-saved-locale-gap` from `.planning/v1.4-MILESTONE-AUDIT.md`.

**Plans:** 1 plan

Plans:

**Wave 1**
- [ ] 18.1-01-PLAN.md — Pending 2FA saved-locale resolution + OTP regression tests + full verification gate

**Cross-cutting constraints:**
- `Localization` must not sign the user in before OTP validation.
- Every locale candidate, including pending OTP user preference, must still pass `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` before `I18n.with_locale`.

**Success criteria:**
1. Locale resolution considers the pending OTP user identified by `session[:otp_user_id]` when no user is signed in.
2. A 2FA-enabled user with `preference.locale = 'en'` sees the OTP challenge page rendered with `html[lang=en]` after password sign-in, even without an `Accept-Language` header.
3. Existing signed-in saved-locale, Accept-Language, default `:ja`, and invalid-locale fallback behavior remains unchanged.
4. Targeted auth/localization tests and the full lint/Minitest/dad:test gate pass.

<details>
<summary>✅ v1.3 — Quick Note Gadget (Phases 10–13) — SHIPPED 2026-04-30</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).

- [x] **Phase 10: Data Layer** (3/3 plans) — completed 2026-04-30
- [x] **Phase 11: Notes Controller** (1/1 plan) — completed 2026-04-30
- [x] **Phase 12: Tab UI** (2/2 plans) — completed 2026-04-30
- [x] **Phase 13: Note Gadget + Integration Tests** (4/4 plans) — completed 2026-04-30

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 10. Data Layer | v1.3 | 3/3 | Complete | 2026-04-30 |
| 11. Notes Controller | v1.3 | 1/1 | Complete | 2026-04-30 |
| 12. Tab UI | v1.3 | 2/2 | Complete | 2026-04-30 |
| 13. Note Gadget + Integration Tests | v1.3 | 4/4 | Complete | 2026-04-30 |

</details>

<details>
<summary>✅ v1.2 — Modern Theme (Phases 5–9) — SHIPPED 2026-04-29</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).

- [x] **Phase 5: Theme Foundation** (2/2 plans) — completed 2026-04-28
- [x] **Phase 6: HTML Structure** (1/1 plan) — completed 2026-04-29
- [x] **Phase 7: Drawer CSS + Animation** (1/1 plan) — completed 2026-04-29
- [x] **Phase 8: Drawer JS Interaction** (1/1 plan) — completed 2026-04-29
- [x] **Phase 9: Full-Page Theme Styles** (1/1 plan) — completed 2026-04-29

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 5. Theme Foundation | v1.2 | 2/2 | Complete | 2026-04-28 |
| 6. HTML Structure | v1.2 | 1/1 | Complete | 2026-04-29 |
| 7. Drawer CSS + Animation | v1.2 | 1/1 | Complete | 2026-04-29 |
| 8. Drawer JS Interaction | v1.2 | 1/1 | Complete | 2026-04-29 |
| 9. Full-Page Theme Styles | v1.2 | 1/1 | Complete | 2026-04-29 |

</details>

<details>
<summary>✅ v1.1 — Modern JavaScript (Phases 2–4) — SHIPPED 2026-04-27</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).

- [x] **Phase 2: JavaScript tooling baseline** (2/2 plans) — completed 2026-04-27
- [x] **Phase 3: Modernize application scripts** (2/2 plans) — completed 2026-04-27
- [x] **Phase 4: Verify and document** (2/2 plans) — completed 2026-04-27

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 2. JavaScript tooling | v1.1 | 2/2 | Complete | 2026-04-27 |
| 3. Modernize scripts | v1.1 | 2/2 | Complete | 2026-04-27 |
| 4. Verify and document | v1.1 | 2/2 | Complete | 2026-04-27 |

</details>

---
*Last updated: 2026-05-02 — v1.4 milestone audit found one 2FA pending-locale gap; Phase 18.1 added for closure before archive.*
