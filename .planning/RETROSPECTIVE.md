# Project Retrospective

*Living document updated at milestone boundaries.*

## Milestone: v1.29 — Admin X API Usage Report

**Shipped:** 2026-05-21
**Phases:** 5 (96–100) | **Plans:** 6 (Phase 96: 2; Phases 97–100: 1 each)

### What Was Built

- `x_api_calls` append-only table; `XApiCall.record!` and `usage_summary` with date-range filters
- Controller instrumentation on `XAccountsController#refresh` and `#show` (success + error paths)
- `Admin::BaseController` + admin usage report at `/admin/x_api_usages` (filter, sort, ja/en, drawer link)
- Tri-suite: `yarn run lint` ✓ · 515/515 Minitest · 30/30 Cucumber

### What Worked

- Phase 96 formal GSD plans (2 waves) produced clean data-layer foundation for later phases
- Reusing existing `users.admin` + Rake task pattern avoided admin-promotion UI scope creep
- 404 (not 403) for non-admins keeps admin surface hidden

### What Was Inefficient

- Phases 97–100 shipped without `*-SUMMARY.md` artifacts — traceability relies on code review + tri-suite
- No `v1.29-MILESTONE-AUDIT.md` at close (recommended for next milestone)
- `gsd-sdk query` subcommands unavailable in Cursor environment — manual archival for complete-milestone

### Key Lessons

- Controller-level `record_x_api_call` after `XClient` keeps the service layer logging-free
- `usage_summary` returning an AR relation (not Array) enables report chaining without extra queries
- Phase directories archived via `/gsd-cleanup` before `/gsd-complete-milestone` reduces close friction

---

## Milestone: v1.28 — Account Self-Service Deletion

**Shipped:** 2026-05-20
**Phases:** 5 (91–95) | **Plans:** 1 (95 only; 91–94 implemented in single cursor-run commit)

### What Was Built

- Privacy policy + ToS (ja/en) updated for two-stage deletion: immediate deactivation + 90-day permanent erasure window
- `users` soft-delete migration (`deleted`, `deleted_at`); `User#destroy_account!` strips PII + anonymizes email; `active_for_authentication?` blocks auth; `User.active` scope excludes deleted users from OAuth re-auth
- Preferences danger zone: bilingual "delete account" section with DELETE confirmation step at `/account_deletion/new`, `AccountDeletionsController#destroy`, sign-out redirect
- Tri-suite: `yarn run lint` ✓ · 500/500 Minitest · 28/28 Cucumber
- Phase 95 artifact closure: retroactive VERIFICATION.md for all phases; 10/10 requirements traced to Complete

### What Worked

- Single-commit implementation (de956cd) for phases 91–94 moved fast; Phase 95 closure pattern handles audit gaps cleanly
- `@account_deletion` Cucumber tag with `rack_test` driver was a clean fix for DELETE form reliability
- Routing `DELETE /account_deletion` via a dedicated `AccountDeletionsController` kept concerns separate from `UsersController`

### What Was Inefficient

- Phases 91–94 implemented without GSD phase directories, requiring a full Phase 95 artifact-closure pass
- Context exhaustion at 81% during complete-milestone forced a fresh session for archival
- Quick task SUMMARY.md naming convention (`SUMMARY.md` vs `{date}-SUMMARY.md`) caused audit-open false positives requiring manual resolution

### Key Lessons

- `destroy_account!` using `update!` not `destroy` is the correct pattern — preserves transactional rows without cascade; but `has_many :x_accounts, dependent: :destroy` is now fragile if `destroy` is ever called
- Retroactive VERIFICATION.md files work well as audit closure when code is already proven by tri-suite
- SUMMARY.md files for quick tasks must use the un-prefixed `SUMMARY.md` filename (not `{date}-SUMMARY.md`) for gsd-sdk audit-open to recognize them as complete

---

## Milestone: v1.27 — Privacy Policy for X OAuth2 Email

**Shipped:** 2026-05-19
**Phases:** 2 (89–90) | **Plans:** 3

### What Was Built

- Public `/privacy` and `/terms` pages (ja/en, lang switcher, `PagesController` without auth)
- Privacy policy 5 sections + terms 3 sections in locale YAML; `pages.css.scss` layout
- OAUTH-03 re-auth email overwrite for dummy-pattern addresses; OAUTH-01/02 scope and create-path verification
- Phase 89 UAT 7/7; tri-suite green at Phase 90 close (485 Minitest, 27 Cucumber)

### What Worked

- Two-phase split (static pages → OAuth wiring) matched X Developer Portal dependency order
- Stub views in 89-01 let controller tests pass before 89-02 content landed

### What Was Inefficient

- Phase 90 closed without VERIFICATION/UAT/SECURITY artifacts — audit flagged as tech debt only
- Policy pages discoverable by direct URL only (no footer/nav links — intentional out of scope)

### Key Lessons

- `has_valid_email?` reuse avoided duplicating dummy-email regex for OAUTH-03
- `data['email'].present?` handles absent OmniAuth keys more safely than `!= nil`

### Patterns Established

- Fully public controller: `skip_before_action :authenticate_user!` without `only:` qualifier
- Conditional attrs hash before `assign_attributes` when re-auth updates subset of fields

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.26 — Visited Link Tracking

**Shipped:** 2026-05-18
**Phases:** 5 (84–88) | **Plans:** 8

### What Was Built

- `visited_links` persistence with utf8mb4-safe prefix unique index; `VisitedLink.record!` upsert + `urls_for` Set + fragment-only normalization
- `POST /visited_links` + Devise HTML semantics for guests (302); Cucumber isolation via `VisitedLink.delete_all`
- `.link--visited` styling + `visited_link_class`; three gadget controllers/views wired with single-query `@visited_urls`
- Delegated jQuery click handler + optimistic styling + contract tests + Cucumber feed scenario
- Phase 88 planning closure: traceability tables, SUMMARY metadata, `v1_26_closure_planning_contract_test.rb`

### What Worked

- End-to-end chain stayed thin: data layer → helper/CSS → controller wiring → JS → audit harness matched integration checker macros
- Delegated namespaced handler avoided rebinding on AJAX gadget refreshes

### What Was Inefficient

- `gsd-sdk milestone.complete` emitted placeholder "One-liner:" bullets in `MILESTONES.md` — repaired manually from SUMMARY files at archive time

### Key Lessons

- Keep Cucumber visit isolation (`VisitedLink.delete_all`) in the same change-set as the feature to prevent order-dependent state leaks
- Pre-close `audit-open` quick-task rows can disagree with merged git reality — document acknowledged drift rather than blocking ship

### Patterns Established

- Gadget content links use a single delegated `.gadget ol li a[href]` contract across themes and AJAX injection

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.25 — Portal Column Width Ratios

**Shipped:** 2026-05-18
**Phases:** 4 (80–83) | **Plans:** 4

### What Was Built

- `portal_column_widths` JSON column on `preferences` with sum-100 validation, length normalization, equal-split defaults
- Linked range sliders on preferences page (`portal_column_width_sliders.js`); redistributes delta on drag; rebuilds on column-count change
- Desktop portal renders saved ratios via `--portal-col-width-pct` inline CSS variable per `.portal-column`; mobile unchanged
- Minitest: model validation, save/reload round-trip, desktop markup structure, locale parity

### What Worked

- Tight 4-phase sequence with a single implementation commit avoided inter-phase integration gaps.
- CSS variable applied server-side via inline `style` kept JS complexity minimal — no hydration step.

### What Was Inefficient

- Post-ship bug: `<template>` outside root div caused `rebuildControls` to silently no-op. Cucumber passed because it uses `dispatchEvent` manually — real browser smoke test would have caught this immediately.

### Key Lessons

- `root.querySelector(...)` early-return guards need DOM structure verification. Don't assume selectors work without checking the actual rendered HTML.
- `execute_script + dispatchEvent` in Cucumber tests is an infrastructure workaround, not behavioral proof. Smoke-test dynamic JS in a real browser before ship.

### Patterns Established

- `<template>` elements for JS-cloned rows must be inside their `[data-*-root]` container if JS queries via `root.querySelector`.

---

## Milestone: v1.22 — Landing at Root

**Shipped:** 2026-05-17
**Phases:** 3 (70–72) | **Plans:** 3

### What Was Built

- Inline landing for guests at `/`: `WelcomeController#index` branches on `user_signed_in?`; no redirect; landing HTML rendered at 200.
- Complete removal of `/landing` route, `LandingController`, and `redirect_guest_to_landing` before_action.
- `User.from_omniauth` Twitter branch switched from `name` to `uid` lookup (fixes XAUTH-FUT-01 deferred from v1.18).
- Test contracts updated across Minitest + Cucumber; both auth states at `/` covered with regression guards.
- Tri-suite green: lint ✓ · 384 Minitest ✓ · 25 Cucumber ✓.

### What Worked

- **Parallel phase structure:** Phase 72 (Twitter uid fix) was independent of 70–71 and could have run concurrently; keeping it separate avoided cross-phase test noise.
- **Surgical removal:** Deleting `LandingController` entirely rather than leaving a redirect stub kept the routing surface clean and tests unambiguous.
- **Single `feat(v1.22)` commit:** The entire routing refactor, controller deletion, uid fix, and test updates landed atomically — easy to reason about and revert if needed.

### What Was Inefficient

- **No `.planning/phases/` artifacts for Phases 70–72:** Executed without standard GSD phase directories; traceability relies on git commit messages and ROADMAP success criteria rather than formal SUMMARY.md files. This is a recurring pattern for fast milestones.
- **No milestone audit before close:** Proceeding without `v1.22-MILESTONE-AUDIT.md` — requirements were verified informally via git/ROADMAP rather than a formal traceability check.

### Patterns Established

- **`user_signed_in?` branch in `index` over separate controller:** When a root route needs auth-state-aware content, a single controller with a conditional branch is simpler than two controllers + a redirect; less routing surface to test.

### Key Lessons

1. A deferred bug fix (XAUTH-FUT-01) can be cleanly picked up in a related milestone if it has no coupling to the main changes — keeps the fix close to the feature context without bloating the milestone.
2. Removing a route entirely (not redirecting) is the right call when the old URL had no external SEO/bookmark value — avoids permanent redirect complexity.
3. Even fast milestones benefit from updating the REQUIREMENTS traceability table before the commit that marks phases complete (the "Pending" traceability gap at archive was purely a documentation miss, not a functional gap).

### Cost Observations

- Not tracked in-repo.

---

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

## Milestone: v1.6 — Note Gadget for All Themes

**Shipped:** 2026-05-04  
**Phases:** 3 (23–25) | **Plans:** Not tracked as numbered artifacts (roadmap success criteria only)

### What Was Built

- Modern and classic welcome surfaces render `_note_gadget` on `/?tab=notes` with `#welcome-home-panel` / `#notes-tab-panel` exclusivity (`welcome-tab-panel--hidden`).
- Drawer navigation exposes Note (`t('nav.note')`) when `use_note` is enabled; Japanese copy delivered via locale tables.
- Theme SCSS extensions for `#notes-tab-panel` under modern/classic tokens; simple-theme tab JS unchanged (`notes_tabs.js` remains simple-only).
- Automated regression coverage in controller + layout integration tests and an expanded Cucumber scenario for modern-theme capture via the drawer link.

### What Worked

- **Reuse simple-theme contracts:** query-param tab state + full-page POST note create avoided new JS frameworks or SPA-style switching on modern/classic.
- **Focused incremental milestones:** v1.3 proved capture/list flows on simple first; v1.6 layered presentation + navigation without revisiting persistence semantics.

### What Was Inefficient

- **Process parity gap:** unlike earlier milestones, Phases 23–25 shipped without `.planning/phases/` VERIFICATION/Nyquist artifacts — acceptable for velocity here but increases reliance on audits/tests for historical narrative.
- **`gsd-sdk query milestone.complete` unavailable** in this environment’s CLI build; archival steps were executed manually (higher friction than automation promises).

### Patterns Established

- **SSR-first panel switching for modern/classic:** mirrors simple-theme behavior without extending `notes_tabs.js`.
- **Explicit Cucumber steps when combining theme activation + preference toggles** — prevents ambiguous stepdefs when multiple “sign in as modern user” variants coexist.

### Key Lessons

1. When skipping formal phase directories, capture milestone-level audits early (`v1.6-MILESTONE-AUDIT.md`) so close-out doesn’t re-argue evidence.
2. Keep drawer additions gated by existing helpers (`drawer_ui?`, `use_note`) rather than inline theme comparisons — preserves parity across locales.

### Cost Observations

- Documentation/process overhead intentionally lighter than verification-debt milestone v1.5; engineering effort concentrated in SCSS + ERB + tests.

---

## Milestone: v1.9 — Mobile Regression Hardening

**Shipped:** 2026-05-05  
**Phases:** 3 (33–33.2) | **Plans:** 3 | **Tasks:** 3

### What Was Built

- Phase 33 established an explicit baseline hardening lane for TEST-02 with direct traceability to executable artifacts.
- Phase 33.1 strengthened JS/Minitest tab-click contracts (`data-portal-column-index`, container/portal resolution, shared `activateColumn(...)`, ARIA/class sync).
- Phase 33.2 introduced a centralized Cucumber `Before` hook (`features/support/hooks.rb`) that resets session and shared preference defaults per scenario.
- Tri-suite gate passed at close; `dad:test` succeeded on first run after scenario-state reset introduction.

### What Worked

- **Gap-closure slicing:** 33 → 33.1 → 33.2 sequencing kept each risk isolated and quickly verifiable.
- **Contract-first hardening:** strengthening assertions without changing production behavior reduced regression blast radius.
- **Centralized hook strategy:** placing resets in support hooks avoided step-definition duplication and made behavior predictable.

### What Was Inefficient

- Milestone closure automation commands in the workflow were unavailable in this runtime, forcing manual archival/editing steps.
- Nyquist VALIDATION artifacts were still missing for v1.9 phases and remained a tracked quality debt.

### Patterns Established

- Keep regression debt closure in narrow insert phases with explicit requirement IDs.
- For flaky E2E caused by shared mutable state, prefer a single scenario-level reset hook over scattered per-step cleanup.

### Key Lessons

1. Deterministic test baselines are worth a dedicated phase when milestone close depends on tri-suite confidence.
2. Baseline-traceability phases (like 33) prevent ambiguity when later gap phases (33.1/33.2) carry implementation-heavy evidence.

### Cost Observations

- Small but high-impact milestone: three plans, mostly verification/contract and test-infrastructure hardening.
- Runtime tooling mismatch created process overhead relative to planned automated closeout flow.

---

## Milestone: v1.16 — Mastodon Account Following

**Shipped:** 2026-05-12  
**Phases:** 5 (52–56) | **Plans:** (inline / code-first; minimal `.planning/phases/` artifacts)

### What Was Built

- `mastodon_accounts` table + `MastodonAccount` model (`before_validation` URL parse, `Crud::ByUser`, `not_deleted` / `destroy_logically!`).
- `MastodonAccountsController` CRUD + `show` (HTML + XHR); `MastodonClient` (Faraday lookup + statuses, `strip_tags` + truncate, structured errors).
- `Portal#get_gadgets` registration + `welcome/_mastodon_account.html.erb` jQuery `$.get` gadget loads.
- Locales (ja/en) for management UI, gadget chrome, and API error strings; nav links to `/mastodon_accounts`.
- Minitest (`mastodon_client_test`, extended controller tests) and Cucumber `05.Mastodon.feature` with `@mastodon_gadget` + global `MastodonAccount.delete_all` in hooks to prevent scenario leakage.

### What Worked

- **Reuse of feed gadget contract:** same AJAX replace pattern reduced UX and JS surprise.
- **Explicit stub seam:** `MastodonClient.stub_fetch_result` kept Cucumber off the live network without adding WebMock.

### What Was Inefficient

- **GSD automation unavailable:** `gsd-sdk query` / `milestone.complete` not present in this runtime — audit, archive, and roadmap/requirements surgery were done manually.
- **Sparse phase artifacts:** only `052-*` context lived under `.planning/phases/`; no per-phase VERIFICATION/Nyquist files for 53–56.

### Patterns Established

- **Tri-suite as the ship gate** when formal phase VERIFICATION files are absent.
- **Cucumber data isolation:** destructive `MastodonAccount.delete_all` in `Before` + tagged stub for Mastodon-only scenarios.

### Key Lessons

1. When automation CLIs are missing, still produce `v*-MILESTONE-AUDIT.md` + archived REQUIREMENTS so the next milestone starts clean.
2. For third-party HTTP, Faraday `:test` stubs in unit tests plus a class-level stub for E2E is enough without WebMock — document the contract in audit tech_debt.

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.17 — Email Registration for X/Twitter Users

**Shipped:** 2026-05-13  
**Phases:** 3 (57–59) | **Plans:** (inline / VERIFICATION-led)

### What Was Built

- `User` dummy-pattern email validation `on: :update` so Twitter `from_omniauth` create keeps working; `twitter_user` fixture + `user_test.rb`.
- `Users::EmailRegistrationsController` at `users/email_registration` with dummy-only guard, uniqueness collision messaging, `rescue ActiveRecord::RecordNotUnique`, `save` (not `save!`).
- Preferences row + `new` form views; `ja.yml` / `en.yml` keys with parity test; preferences and i18n controller tests.

### What Worked

- **Audit before close:** `v1.17-MILESTONE-AUDIT.md` with **passed** and explicit evidence table aligned archive with implementation.
- **Dedicated controller:** narrow surface vs extending preferences; strong params scoped to `:email_registration`.

### What Was Inefficient

- **GSD automation unavailable:** `gsd-sdk query` / `milestone.complete` not present in this runtime — archive and roadmap surgery manual again.
- **No `*-SUMMARY.md`:** accomplishment extraction for `MILESTONES.md` was hand-authored from VERIFICATION + audit.

### Patterns Established

- **Dummy-only registration route** as the single writable path for elevating Twitter users to real email + Google OAuth compatibility.
- **Tri-suite + VERIFICATION.md** as the acceptance record when SUMMARY/Nyquist artifacts are skipped.

### Key Lessons

1. Keep REQUIREMENTS checkboxes in sync during execution, or normalize at archive (audit called out checkbox drift).
2. `RecordNotUnique` rescue belongs next to the `save` that can race the unique index — document in controller, test with stub.

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.18 — X (Twitter) Account Following

**Shipped:** 2026-05-14  
**Phases:** 4 (60–63) | **Plans:** (autonomous execution, no GSD artifacts)

### What Was Built

- `users.token_secret` column + `encrypts :token, :token_secret`; `User.from_omniauth` Twitter branch persists `uid`/`token`/`token_secret` on create + re-auth; `TwitterLinkRequirement#require_twitter_linked` gates on `uid + token`.
- `XClient` Faraday + `faraday-oauth1` service: `fetch_following` / `fetch_recent_tweets`, 7-symbol error enum, t.co display_url substitution before truncation, following pagination via `pagination_token`/`meta.next_token`, class-level stub accessors.
- `x_accounts` cache table + `XAccount` model (`Crud::ByUser`, soft-delete, gadget_id derivation); `/x_accounts` management UI: refresh diff-upsert (all-soft-delete semantics), per-row selection cap 12 / warn 9, protected-account `🔒` confirmation toggle, last-refreshed timestamp.
- Welcome-page AJAX gadgets via `Portal#get_gadgets`; per-error-symbol localized states; `:unauthorized` re-sign-in CTA; tweet text never `html_safe`; click-through URL constructed server-side.
- `features/06.X.feature` with `@x_gadget` Before/After stub hooks + global state-isolation Before hook; tri-suite green (364 Minitest, 24 Cucumber scenarios).

### What Worked

- **v1.16 Mastodon pattern reuse:** `Crud::ByUser`, `Portal#get_gadgets`, AJAX `show` with `render layout: !request.xhr?`, `stub_fetch_result`-shaped class accessors, Faraday `:test` adapter, Cucumber feature stub hooks — carried over wholesale, reducing design surface to "following list → selection" flow only.
- **Audit-first close:** Milestone audit produced 31/31 requirement evidence before archival; no surprises at close. XTEST-03 controller gap was caught and closed before the audit was signed off.
- **Tech debt acknowledged honestly:** All-soft-delete deviation (XACCT-06) and XAUTH-FUT-01 carry-forward documented in audit + REQUIREMENTS archive with commit reference.

### What Was Inefficient

- **GSD automation unavailable:** `gsd-sdk query` not in runtime — all archive surgery manual.
- **REQUIREMENTS checkbox drift:** Traceability table left as "Pending" throughout execution; normalized at archive time via audit evidence. Keeping checkboxes live during execution would save cross-referencing at close.
- **No per-phase SUMMARY.md:** Accomplishment extraction hand-authored from audit; same pattern as v1.16/v1.17 — accepted but adds close overhead.

### Patterns Established

- **`require_twitter_linked` on `uid + token` (not `name`):** User-editable name is the wrong identity predicate; uid + token is the API credential predicate.
- **All-soft-delete over selective hard/soft-delete:** More recoverable; fewer branches in diff logic; confirm with tests rather than spec complexity.
- **CSS `max()` → `width: 100%` for Dart Sass compatibility:** When Dart Sass interprets a CSS `max()` call as Sass `max()`, replace with explicit property rather than fighting syntax escaping.

### Key Lessons

1. Keep REQUIREMENTS traceability checkboxes in sync during execution — audit evidence already exists in tests, so updating `[x]` inline costs nothing and saves close-time normalization.
2. When a spec says "hard-delete condition-A, soft-delete condition-B" and implementation collapses to all-soft-delete, capture the rationale in the commit message immediately — audit cross-referencing becomes trivial.
3. Test controller endpoints (index, refresh, update, show) before milestone audit — `XTEST-03` gap surfaced at audit time, not phase time.

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.19 — HTTP test stubs → WebMock

**Shipped:** 2026-05-14  
**Phases:** 3 (64–66) | **Plans:** (autonomous execution — Phase 64 has phase dir; Phases 65–66 inline)

### What Was Built

- `webmock` gem added to `:test` group; `test/support/webmock.rb` with `disable_net_connect!(allow_localhost: true)` and fixture feed stubs auto-loaded by both Minitest and Cucumber (Phase 64).
- All Minitest HTTP stubs migrated to Faraday `:test` adapter (service tests via `connection:` injection) and `WebMock.stub_request` (controller integration tests and `XClient#fetch_recent_tweets`); all class-level stub accessors removed from `MastodonClient` and `XClient` (Phase 65).
- Cucumber `@mastodon_gadget` and `@x_gadget` hooks migrated from class-level stub accessors to `WebMock.stub_request` / `WebMock.remove_request_stub`; `test/http_client_test_stubs.rb` deleted (133 lines); `config/environments/test.rb` stub loader removed (Phase 66).
- Tri-suite green: `yarn run lint` ✓ · 363 Minitest ✓ · 24 Cucumber scenarios ✓.

### What Worked

- **WebMock + Faraday `:test` split was the right decomposition:** Service layer tests use Faraday `:test` adapter (injected via `connection:`) for unit-style isolation; full-stack controller and Cucumber tests use WebMock `stub_request` for cross-layer interception. The boundary was clear and required no retrofitting.
- **Deleting 133-line stub file in one phase:** Having a dedicated "cleanup + delete" phase (66) meant the deletion was gated on confirmed green Cucumber, not trusted speculatively.
- **Audit-first close:** `tech_debt` status (not `gaps_found`) confirmed all 5 requirements satisfied before archival; inline execution of Phases 65–66 is accepted-pattern debt consistent with v1.16–1.18.

### What Was Inefficient

- **Phases 65–66 inline (no GSD artifacts):** Same pattern as v1.16–v1.18 — accepted but closes without per-phase SUMMARY.md or VERIFICATION.md. Audit evidence carried traceability.
- **Phase 64 VALIDATION.md draft state:** `nyquist_compliant: false` / `wave_0_complete: false` at close because the file was auto-generated but never signed off. Tests were green; the artifact status was cosmetically wrong.

### Patterns Established

- **`XClient#fetch_recent_tweets` builds its own Faraday connection:** WebMock (not Faraday `:test`) is the right interception layer for methods that don't accept an injected `connection:`. The rule: inject connection → Faraday `:test`; no injection possible → WebMock.
- **`disable_net_connect!(allow_localhost: true)` in shared support file:** A single shared file loaded by both Minitest (`test/test_helper.rb`) and Cucumber (`features/support/env.rb`) enforces the net-connect policy consistently across all test runners without per-file duplication.

### Key Lessons

1. WebMock and Faraday `:test` are complementary, not alternatives — pick by whether the production code accepts a `connection:` injection parameter.
2. When deleting a shared stub file, gate deletion on the test suite that most depends on it (Cucumber in this case) being green first.
3. Auto-generated VALIDATION.md files left in draft/pending state create cosmetic audit noise without affecting quality — sign off or delete them at phase close.

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.20 — Column Count Preference

**Shipped:** 2026-05-15
**Phases:** 2 (67–68) | **Plans:** 4

### What Was Built

- `preferences.portal_column_count` integer column (NOT NULL, default 3); existing rows migrated silently (Phase 67).
- `PORTAL_COLUMN_COUNTS = [3, 4]` constant on `Preference` with inclusion validation; matches `FONT_SIZES` pattern.
- `Portal#portal_columns` fully parameterized — no hardcoded 3; downgrade guard skips `column_no >= column_count` and redistributes via `i % column_count` (Phase 67).
- Preferences select control with `3列`/`4列` (ja) and `3 columns`/`4 columns` (en) locale strings; `portal--4col` conditional class; `.portal--4col .gadgets { width: 25% }` SCSS rule; mobile tab strip unchanged (Phase 68).
- Cucumber scenario in `features/07.設定.feature`; Minitest controller save/render and portal layout 3/4-column tests (Phase 68).
- Tri-suite green: `yarn run lint` ✓ · 377 Minitest ✓ · 25 Cucumber scenarios ✓.

### What Worked

- **`FONT_SIZES` constant as direct template:** `PORTAL_COLUMN_COUNTS = [3, 4]` + inclusion validation + `default_preference` initialization followed the established pattern exactly, requiring no new decisions on the validation shape.
- **Two-phase split (data first, UI second):** Phase 67 delivered green Minitest on the model/portal layer before Phase 68 touched views and Cucumber, keeping blast radius small on each gate.

### What Was Inefficient

- **Phases 67–68 executed without `.planning/phases/` SUMMARY.md artifacts:** Same pattern as v1.19; MILESTONES.md entry carried the accomplishments. Milestone audit file not created for v1.20 (no blocking gaps found).
- **Cucumber selector deviation discovered mid-phase:** `form.preferences-form` (from explicit `html: { class: }` in `form_with`) required instead of `form.edit_user`; the deviation was found during test authoring, not spec time.

### Patterns Established

- **`form_with` with explicit `html: { class: }` drops `edit_user` class:** Use `.preferences-form` as the Cucumber selector for preferences form steps, not `.edit_user`.
- **`portal--4col` modifier + SCSS `@media` rule:** Desktop-only column override stays in `welcome.css.scss`; theme files unchanged; mobile breakpoint unaffected.

### Key Lessons

1. When the new preference value is a fixed small set, a constant (`[3, 4]`) + inclusion validation is the right shape — avoids range boundary edge cases.
2. Confirm the exact CSS class emitted by `form_with` before writing Cucumber steps; `form_for`-era assumptions (`edit_user`) do not apply.

### Cost Observations

- Not tracked in-repo.

---

## Milestone: v1.21 — X Gadget Tweet Count Preference

**Shipped:** 2026-05-16
**Phases:** 1 (69) | **Plans:** 1

### What Was Built

- `display_count` integer column (DB-default 5) on `x_accounts`; `f.number_field :display_count` bound to account value on `/x_accounts` management card.
- `:display_count` permitted in `x_account_params` strong params; PATCH saves to DB.
- `XClient#fetch_recent_tweets(limit:)` requests `[limit, 5].max` from the X API (minimum 5 per API contract), then slices result to user's exact preference — fixes API error when `display_count < 5`.
- `set_display_count_default` `before_save` callback as nil-guard only (fires after validation, which already blocks ≤ 0); DB default handles the practical nil case.
- Controller test verifies PATCH persists changed value; 3 model tests cover callback (default), negative rejection, and float rejection.
- Tri-suite green: `yarn run lint` ✓ · 382 Minitest ✓ · 25 Cucumber scenarios ✓.

### What Worked

- **Single-phase milestone with clear column + UI + test scope:** `display_count` was a natural addition to the existing `x_accounts` row; schema change, UI, and tests landed atomically in one commit.
- **Audit-first close:** `v1.21-MILESTONE-AUDIT.md` reached `passed` (6/6 requirements, 2/2 flows) before archive, giving clean traceability despite autonomous execution.

### What Was Inefficient

- **No GSD discuss → plan → execute workflow for Phase 69:** Executed autonomously without standard artifacts; VALIDATION.md not produced. Tri-suite is the verification gate; Nyquist compliance noted as `missing` in the audit.
- **Debug logging lines required cleanup before milestone close:** `display_count` debug log left in the controller was caught during milestone review, not during implementation.

### Patterns Established

- **X API `max_results` lower-bound clamping pattern:** When passing a user preference as `max_results`, always apply `[pref, API_MINIMUM].max` then slice result to `pref` — separates API constraint (≥ 5) from user preference (any positive integer).
- **Per-account preference on the resource row (not global):** `display_count` on `x_accounts` (not `preferences`) follows the principle of storing preference nearest to the entity it describes.

### Key Lessons

1. The X API `max_results` minimum is 5 — always clamp at call site and slice after; do not expose the constraint to the user.
2. A `before_save` callback that duplicates validation logic is harmless but creates audit noise; prefer a DB default + nil-guard only.
3. Even for single-phase milestones, an audit file as checklist before archive pays for itself by surfacing deferred items formally.

### Cost Observations

- Not tracked in-repo.

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
| v1.6 | 3 (23–25) | First milestone shipped entirely without `.planning/phases/` directories — roadmap + audit + tests carry traceability |
| v1.16 | 5 (52–56) | Manual milestone close (no `gsd-sdk`); tri-suite + audit file carry traceability; Cucumber uses global DB reset for new gadget type |
| v1.17 | 3 (57–59) | Security-first email elevation (dummy-only + collision + race rescue); VERIFICATION-led close without SUMMARY files |
| v1.18 | 4 (60–63) | Highest requirement count (31 REQ-IDs); v1.16 Mastodon pattern reused wholesale; all-soft-delete intentional deviation documented in commit + audit |
| v1.19 | 3 (64–66) | Infrastructure-only milestone (no user-facing features); WebMock + Faraday `:test` replaces bespoke 133-line prepend stub file |
| v1.20 | 2 (67–68) | Preference constant pattern (`PORTAL_COLUMN_COUNTS`) + two-phase data-first split; first portal layout parameterization |
| v1.21 | 1 (69) | Single-phase autonomous execution; X API lower-bound clamping pattern established; per-account preference stored on resource row |
| v1.22 | 3 (70–72) | Routing simplification milestone; `LandingController` deleted, guest path inlined into `WelcomeController#index`; deferred uid bug fixed in parallel phase |
| v1.26 | 5 (84–88) | Visited link persistence + gadget wiring + delegated JS; Phase 88 planning/trace harness (`v1_26_closure_planning_contract_test.rb`); milestone audit passed before archive |

### Cumulative quality

| Milestone | Automated tests | Notes |
|-----------|-----------------|--------|
| v1.1 | Minitest + Cucumber green at close | Manual D-04 smoke for JS-touching flows |
| v1.2 | Minitest + SCSS contract tests | Human UAT 5/5; drawer reduced-motion manual |
| v1.3 | Minitest + Cucumber HEADLESS green | Human UAT 5/5; Phase 10 VERIFICATION skipped |
| v1.4 | Minitest 191/1101 + Cucumber 9/28 green | Locale key parity test enforced; pre-existing Cucumber scenario-order flake surfaced and deferred |
| v1.5 | Minitest + Cucumber green (one-rerun policy) | No new user-facing features; evidence-only + 2 test file changes (+38+16 lines) |
| v1.6 | Minitest + Cucumber green (one-rerun policy) | Theme/UI expansion only; milestone audit notes missing Nyquist artifacts |
| v1.16 | Minitest + Cucumber green (one-rerun policy) | New external HTTP client + gadget; Faraday test adapter + class stub for E2E |
| v1.17 | Minitest + Cucumber green (one-rerun policy) | No new gems/migrations; E2E for email path explicitly deferred per REQUIREMENTS |
| v1.18 | Minitest 364/364 + Cucumber 24 scenarios green | OAuth1 + new HTTP client + gadget pattern; XTEST-03 controller gap caught at audit, closed before archive |
| v1.19 | Minitest 363/363 + Cucumber 24 scenarios green | Infrastructure cleanup only; WebMock `disable_net_connect!` now enforced globally; no regressions |
| v1.20 | Minitest 377/377 + Cucumber 25 scenarios green | First portal layout preference; `portal--4col` SCSS modifier; Cucumber step selector deviation caught mid-phase |
| v1.21 | Minitest 382/382 + Cucumber 25 scenarios green | Per-account tweet count preference; X API `max_results` clamp pattern; autonomous single-phase execution |
| v1.22 | Minitest 384/384 + Cucumber 25 scenarios green | Routing simplification; `LandingController` deleted; `from_omniauth` uid fix; no new test infrastructure needed |
| v1.26 | Minitest 458 + Cucumber 27 scenarios green | Feed-path Cucumber E2E; planning closure locked traceability; pre-close `audit-open` quick-task scanner drift acknowledged in STATE |

### Top lessons (carry forward)

1. Keep SUMMARY one-liners meaningful for `milestone complete` and historiography.
2. Phase dirs not archived to `milestones/v*-phases/` — `/gsd-cleanup` available for retroactive archival.
3. Run `/gsd-audit-milestone` only after **all** phases complete; early audits produce misleading `gaps_found` reports.
4. Create `VERIFICATION.md` with the phase, not retroactively — saves Nyquist remediation work at close.
5. Phase verification must cross the redirect boundary for any flow that changes shared state (locale, theme, session) — the post-action rendered output is the contract, not the handler return (v1.4).
6. Refresh stale milestone audits as part of gap-closure phase verification, not at archive time (v1.4).
7. Archive snapshots (milestones/v*-ROADMAP.md, v*-REQUIREMENTS.md) must be created after all phases complete — mid-execution snapshots are stale at close (v1.5).
8. Verification-debt milestones need a shared rubric phase first; the rubric investment pays for itself across all downstream closure phases (v1.5).
9. If you skip `.planning/phases/` artifacts for speed, publish a milestone audit early so archival/reviews cite one authoritative gap ledger instead of inferring from git history (v1.6).
10. WebMock and Faraday `:test` are complementary: use Faraday `:test` when the production code accepts a `connection:` injection parameter, and WebMock `stub_request` when it doesn't (v1.19).
11. When the new preference is a fixed small set, use a constant + inclusion validation (not a range) — matches the `FONT_SIZES` pattern and avoids boundary edge cases (v1.20).
12. The X API `max_results` minimum is 5 — clamp at call site with `[pref, 5].max`, then slice after fetch; store and display the user's exact preference unchanged (v1.21).
13. For auth-state-aware root routes, a single controller with a `user_signed_in?` branch is simpler than two controllers + redirect — fewer routes, unambiguous test contracts (v1.22).
14. Update the REQUIREMENTS traceability table in the same commit that marks phases complete — "Pending" rows at archive time are a documentation miss that creates confusion during milestone close (v1.22).
15. After `gsd-sdk query milestone.complete`, scan `MILESTONES.md` for placeholder accomplishment bullets — repair from SUMMARY one-liners before tagging (v1.26).
