# Project Retrospective

*Living document updated at milestone boundaries.*

## Milestone: v1.1 — Modern JavaScript

**Shipped:** 2026-04-27  
**Phases:** 3 (2–4) | **Plans:** 6 | **Tasks:** 8 (per milestone close)

### What Was Built

- ESLint 9 + Prettier wired to Sprockets-served JS with a single `yarn run lint` entry point.
- First-party `app/assets/javascripts/` brought to `const`/`let`, explicit globals, and jQuery-`this`-safe patterns; legacy APIs (e.g. `$.delegate`) fixed where they broke under modern jQuery.
- Regression evidence: Minitest, Cucumber (`dad:test`), and a recorded D-04 manual smoke list.
- `CONVENTIONS.md` JavaScript section aligned with the linter and project rules (**DOCS-01**).

### What Worked

- **Small phases:** Tooling → edit → verify limited blast radius and kept verification traceable to roadmap requirements.
- **Audit before close:** `v1.1-MILESTONE-AUDIT.md` with **passed** status gave confidence to archive without re-litigating scope.

### What Was Inefficient

- Some `SUMMARY.md` files had thin `one_liner` fields, so automated accomplishment extraction produced noise until hand-edited in `MILESTONES.md`.
- Nyquist/VALIDATION flags on phases are **partial** by design (manual smoke); expect ongoing explanation for strict-automation expectations.

### Patterns Established

- **Lint-first, ship-second:** no Phase 3 mass edit without a green baseline from Phase 2.
- **Document the command surface:** README + `package.json` for lint is part of the definition of done, not an afterthought.

### Key Lessons

1. **Retroactive verification docs** (e.g. Phase 3 `VERIFICATION.md`) are acceptable for audit but cost time; prefer creating VERIFICATION with the phase in future.
2. **3-source traceability** (REQUIREMENTS + VERIFICATION + SUMMARY) catches gaps early; keep REQ IDs stable across phases.

### Cost Observations

- Not tracked in-repo for this milestone — add session/model metrics in a future close-out if product governance requires them.

---

## Milestone: v1.3 — Quick Note Gadget

**Shipped:** 2026-04-30
**Phases:** 4 (10–13) | **Plans:** 10

### What Was Built

- `notes` table migration, `Note` model with `Crud::ByUser`, soft-delete override, `scope :recent`, and `validates :body presence/length`.
- `NotesController#create`: authenticated POST, server-side `user_id` merge, redirect to `root_path(tab: 'notes')`.
- Simple-theme tab strip (ホーム/ノート) with ERB gate + jQuery switching (`notes_tabs.js`) + `?tab=notes` SSR state — invisible on other themes.
- `_note_gadget.html.erb`: textarea + Save, empty-state "メモはまだありません", reverse-chrono note list with timestamps.
- `WelcomeControllerTest` gadget + isolation coverage; Cucumber `features/04.ノート.feature` Japanese E2E.
- `drawer_ui?` helper gating hamburger + drawer in layout; extended `layout_structure_test.rb`.
- Human UAT 5/5 passed.

### What Worked

- **Zero new dependencies:** entire feature on existing stack — no bundler churn, no new abstractions.
- **Plan 01 → N execution:** splitting data layer, controller, tab UI, and gadget into focused phases kept each step verifiable in isolation.
- **Cucumber feature as living spec:** `04.ノート.feature` in Japanese matches the product intent; HEADLESS=true makes it runnable in CI without a display.
- **Quick-task workflow for small fixes:** `notes_tabs.js` modernization and tab label rename were handled as quick tasks without polluting phase scope.

### What Was Inefficient

- **Milestone audit run too early:** `v1.3-MILESTONE-AUDIT.md` was generated before phases 12–13 were built, producing a stale `gaps_found` report. Audit should run after all phases complete.
- **Phase 10 missing `VERIFICATION.md`:** model tests and UAT passed but were never promoted to VERIFICATION format, leaving a Nyquist gap. The pattern is now clear: create VERIFICATION with the phase, not retroactively.
- **Rails 8.1 `delete_all` gotcha:** cost debug time in Phase 13 tests; now documented in STATE.md and memory.

### Patterns Established

- **Server-side ownership merge:** `permit(:body).merge(user_id: current_user.id)` — never accept `user_id` from the client.
- **Theme isolation two-gate:** ERB `favorite_theme == 'simple'` guard AND CSS `.simple { }` scope required together; one alone leaks.
- **Query-param tab state:** `root_path(tab: 'notes')` redirect + `URLSearchParams` read on DOM ready survives POST/redirect cycle cleanly.
- **`drawer_ui?` helper:** explicit boolean from `WelcomeHelper` is cleaner than `favorite_theme != 'simple'` inline — a reusable pattern for future theme-conditional layout blocks.

### Key Lessons

1. **`delete_all` on a NOT NULL FK in Rails 8.1 issues a nullifying UPDATE, not a DELETE.** Use `Note.where(user_id: user.id).delete_all` in tests.
2. **Milestone audit timing matters.** Run `/gsd-audit-milestone` only after all phases are complete — an early audit can look alarming when later phases are simply unbuilt.
3. **Single-day sprints are feasible for scoped gadgets.** Phases 10–13 (10 plans) shipped on one calendar date by keeping scope narrow and the stack unchanged.

### Cost Observations

- Not tracked in-repo for this milestone.

---

## Milestone: v1.4 — Internationalization

**Shipped:** 2026-05-03
**Phases:** 7 (14–18.2) | **Plans:** 19 | **Tasks:** 32

### What Was Built

- Locale infrastructure: `preferences.locale` column, `Preference::SUPPORTED_LOCALES` whitelist, `Localization` controller concern with thread-safe `around_action :set_locale` + `I18n.with_locale`, three-stage resolution (saved → Accept-Language → :ja), `<html lang>` from resolved locale.
- Preferences language switcher (ja/en/auto) on `/preferences` with locale-aware page chrome.
- Core shell + shared message translation: navigation, drawer, simple-theme menu, `flash.errors.generic` fallback all driven by `t(...)`.
- Feature-surface translation: bookmarks, notes, todos, feeds, calendars — UI chrome localized while user/external content stays as-is. JavaScript-visible feed messages supplied via server-rendered translated `data-*` attributes (no JS i18n build pipeline).
- Auth/2FA localization: Devise `invalid_credentials` alert, OTP labels, setup pages — all bilingual through shared layout flash rendering.
- Phase 18.1 gap closure: pending 2FA OTP page resolves saved locale via `session[:otp_user_id]` before sign-in completes, without signing in early, while preserving the `SUPPORTED_LOCALES` whitelist.
- Phase 18.2 gap closure: `PreferencesController#create/update` translate save flash under the just-saved locale via whitelist-gated `I18n.with_locale`, so language-change redirects render chrome and notice in the new locale together.
- Ja/en regression coverage: locale key parity test, OTP saved-locale test, locale-change save flash test (both directions), representative feature-surface ja/en assertions.

### What Worked

- **Phase 14 invariants drove everything downstream:** the `around_action` + `I18n.with_locale` + whitelist-gate contract was set once and held across 18 plans. Every subsequent integration just had to respect those three rules.
- **Audit-driven gap closure:** the v1.4 milestone audit caught two real integration gaps (pending OTP, preferences flash) that automated phase-level verification missed. Splitting them into 18.1 and 18.2 preserved phase boundaries.
- **Translation surface as a feature, not a refactor:** treating each surface (auth, feature pages, shared shell) as a phase-scoped deliverable with its own ja/en regression made the work atomically verifiable instead of one giant rewrite.
- **`I18n.with_locale` for one-shot translation under a different locale than the request:** the same primitive solved both the OTP pre-sign-in lookup and the save flash post-redirect alignment.
- **Native labels rule (D-02):** keeping `自動 / 日本語 / English` in their own scripts regardless of UI locale matched product intent and saved a failed UX iteration.

### What Was Inefficient

- **Cucumber scenario-order DB-state leak:** Phase 18.2 verification needed three runs of `dad:test` to go green (different unrelated features flaked on each first attempt). The flake was acknowledged in `CLAUDE.md` but never fixed; carries forward as v1.5+ debt.
- **Two integration gaps caught only by milestone audit, not phase verification:** PREF-03 was claimed by Phase 15's plan, marked complete by 15-03 SUMMARY, and passed Phase 15 verification — yet the locale-change save flash bug existed the whole time. Phase-level verification didn't simulate the post-redirect render under the new locale. Lesson: phase verification should include the user-observable post-action state across the redirect boundary, not just the immediate handler return.
- **Lazy lookup template path mismatch (Plan 15-02):** `t('.foo')` in `app/views/preferences/index.html.erb` resolves to `preferences.index.foo`, not `preferences.foo`. Plan 15-02 placed keys at `preferences.foo` and required a corrective edit. Future view-i18n plans must verify yml key paths match the view path exactly.
- **Multiple phases shipped without VALIDATION.md** (Phase 14, 15, 18, 18.1) — Nyquist tracking lagged the actual work. Pattern from v1.3 retrospective recurred.
- **Phase 16 `nav.home: Home` brand label** carried forward as documented intentional exception but never explicitly decided — flagged in audit tech_debt.

### Patterns Established

- **Locale resolution contract:** `around_action :set_locale` + `I18n.with_locale` + `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` whitelist gate before every locale-setting call. Forbidden: `before_action`, raw `I18n.locale = ...`, `?locale=` URL param.
- **Pre-sign-in saved-locale lookup:** `session[:otp_user_id]` is the bridge for resolving saved preferences during multi-step authentication without prematurely signing in.
- **Post-action translation under different locale:** when a save changes the active locale, materialize the post-action flash with `I18n.with_locale(saved_candidate) { t(key) }` so the flash aligns with the post-redirect chrome.
- **Native-label rule for language UIs:** display language names in their own script regardless of UI locale.
- **JavaScript-visible strings via server-rendered `data-*`:** no JS i18n build pipeline; ERB renders translated text into data attributes that JS reads.
- **Yml key path parity with view path:** `t('.x')` in `app/views/A/B.html.erb` ⇒ key at `A.B.x`, not `A.x`.

### Key Lessons

1. **Phase verification must cross the redirect boundary.** A handler that sets `flash[:notice] = t(...)` then `redirect_to` is verified as a unit only by asserting the post-redirect rendered output, not the controller-level return. Apply this to any `before_action`-vs-`around_action`-vs-after-save state question in future phases.
2. **`I18n.with_locale` is the universal escape hatch.** It solves "translate this one string under a different locale than the request" cleanly and thread-safely. Reach for it before adding new helpers.
3. **Milestone audits catch what phase audits miss.** Cross-phase integrations (Localization concern × PreferencesController × shared layout flash) need a milestone-level review pass; don't trust per-phase verification to catch them.
4. **Re-run audits after gap closures.** Stale `gaps_found` audits create friction at archive time. The audit refresh is cheap; do it as part of gap-closure phase verification.
5. **Whitelist gates compose with framework guards.** `Preference::SUPPORTED_LOCALES` + `enforce_available_locales` + `validates :locale, inclusion:` is three independent layers; any one alone is incomplete.

### Cost Observations

- Not tracked in-repo. Approximate: 7 phases / 19 plans / ~3 calendar days; opus/sonnet mix typical for the project.

---

## Milestone: v1.5 — Verification Debt Cleanup

**Shipped:** 2026-05-04
**Phases:** 4 (19–22) | **Plans:** 7

### What Was Built

- Phase 19: Shared verification rubric (`19-VERIFICATION-RUBRIC.md`) with hybrid claim table + per-claim evidence blocks, fail-first/minimal-fix/one-rerun policy, and tri-suite gate (lint + Minitest + Cucumber). Closes VERF-01/02.
- Phase 20: `05-VERIFICATION.md` closure with `P05-C01..C03` PASS — THEME-01/02/03 including THEME-03 drawer-contract alignment (modern + classic, simple excluded by `drawer_ui?`). Closes P05V-01/02.
- Phase 21: `06-VERIFICATION.md` closure with `P06-C01..C03` PASS — modern + classic + simple interaction evidence, non-modern unaffected contract. Closes P06V-01/02.
- Phase 22: `09-VERIFICATION.md` closure with `P09-C01..C04` PASS — STYLE-01..04 anchored to `modern_full_page_theme_contract_test.rb` selectors; STYLE-05 explicitly out of scope. Closes P09V-01/02 + MSYN-01.

### What Worked

- **Verification rubric as shared contract (Phase 19):** a single artifact defining evidence fields, acceptance threshold, and flake policy meant Phases 20–22 could close independently without relitigating criteria.
- **Fail-first, minimal-fix policy:** finding THEME-03 mismatch in Phase 20 and fixing only the broken guard (`modern_only` enforcement) rather than broader cleanup kept scope contained and the fix traceable.
- **One-rerun flake policy:** the explicit policy (one re-run allowed, consistent second failure = real regression) prevented premature green declarations without adding flake anxiety.
- **Milestone sync as its own plan (22-02):** treating cross-document consistency as an explicit deliverable (not an afterthought) caught the stale snapshot problem and produced a clean close.

### What Was Inefficient

- **Stale archive snapshots:** milestones/v1.5-ROADMAP.md and v1.5-REQUIREMENTS.md were created mid-execution (pre–Phase 22 completion) and required correction at formal close. Archive snapshots should only be created after all phases complete.
- **No formal milestone audit:** v1.5-MILESTONE-AUDIT.md was skipped; the milestone-sync work in Phase 22 substituted for it but is not structurally equivalent. For future debt-cleanup milestones, a lightweight audit (even just a checklist) is worth the overhead.
- **RETROSPECTIVE and REQUIREMENTS.md not cleaned up by Phase 22-02:** the "milestone shipped" declaration in STATE.md preceded the formal `/gsd-complete-milestone` archival, leaving RETROSPECTIVE, REQUIREMENTS.md removal, ROADMAP reorganization, and git tag as deferred work.

### Patterns Established

- **Verification-debt milestone pattern:** shared rubric phase → one closure phase per document → milestone sync phase. Works cleanly when scope is exclusively carry-forward verification, not new features.
- **Selector-level evidence standard:** STYLE claims require specific CSS selectors or DOM paths as evidence, not just "theme looks right." This is the reproducible bar for future style phases.
- **Out-of-scope claim (STYLE-05):** explicitly naming an out-of-scope claim in the verification document prevents future confusion about whether it was missed or intentionally deferred.

### Key Lessons

1. **Archive snapshots at end, not mid-execution.** Creating milestones/v*-ROADMAP.md and v*-REQUIREMENTS.md before all phases complete produces stale artifacts that need correction at formal close.
2. **Verification rubric investment pays off across N phases.** Phase 19's rubric made Phases 20–22 self-describing; each closure document could be read independently and understood in full.
3. **Milestone sync is a real deliverable.** Cross-document consistency (ROADMAP + STATE + MILESTONES + PROJECT) should be a named plan in the milestone, not assumed to happen automatically.

### Cost Observations

- Verification-debt milestones are documentation-heavy: ~260 files changed across 7 plans, but actual code changes were 2 test files (+38 + 16 lines). The effort was evidence capture and document alignment, not feature work.
- Model mix: not tracked. Tri-suite gate ran multiple times; Cucumber one-rerun policy applied at least once.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Key Change |
|-----------|--------|------------|
| v1.1 | 3 (2–4) | First full GSD milestone with roadmap + requirements + archive close-out |
| v1.2 | 5 (5–9) | Added UI-SPEC, drawer JS interaction, full-page CSS polish; first multi-plan theme phase |
| v1.3 | 4 (10–13) | First data-layer → controller → UI → tests pipeline; Cucumber E2E; zero-dep constraint held |
| v1.4 | 7 (14–18.2) | First milestone with mid-flight gap-closure phases (18.1, 18.2) added after audit; first cross-cutting concern (locale) wired through every surface |
| v1.5 | 4 (19–22) | First verification-debt-only milestone; shared rubric phase + per-document closure phases + explicit milestone sync phase |

### Cumulative quality

| Milestone | Automated tests | Notes |
|-----------|-----------------|--------|
| v1.1 | Minitest + Cucumber green at close | Manual D-04 smoke for JS-touching flows |
| v1.2 | Minitest + SCSS contract tests | Human UAT 5/5; drawer reduced-motion manual |
| v1.3 | Minitest + Cucumber HEADLESS green | Human UAT 5/5; Phase 10 VERIFICATION skipped |
| v1.4 | Minitest 191/1101 + Cucumber 9/28 green | Locale key parity test enforced; pre-existing Cucumber scenario-order flake surfaced and deferred |
| v1.5 | Minitest + Cucumber green (one-rerun policy) | No new user-facing features; evidence-only + 2 test file changes (+38+16 lines) |

### Top lessons (carry forward)

1. Keep SUMMARY one-liners meaningful for `milestone complete` and historiography.
2. Phase dirs not archived to `milestones/v*-phases/` — `/gsd-cleanup` available for retroactive archival.
3. Run `/gsd-audit-milestone` only after **all** phases complete; early audits produce misleading `gaps_found` reports.
4. Create `VERIFICATION.md` with the phase, not retroactively — saves Nyquist remediation work at close.
5. Phase verification must cross the redirect boundary for any flow that changes shared state (locale, theme, session) — the post-action rendered output is the contract, not the handler return (v1.4).
6. Refresh stale milestone audits as part of gap-closure phase verification, not at archive time (v1.4).
7. Archive snapshots (milestones/v*-ROADMAP.md, v*-REQUIREMENTS.md) must be created after all phases complete — mid-execution snapshots are stale at close (v1.5).
8. Verification-debt milestones need a shared rubric phase first; the rubric investment pays for itself across all downstream closure phases (v1.5).
