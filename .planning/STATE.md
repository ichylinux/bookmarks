---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: — Internationalization
status: ready-to-execute
stopped_at: Phase 15 planned — 3 plans across 2 waves; ready for /gsd-execute-phase 15
last_updated: "2026-05-01T03:27:38.812Z"
last_activity: 2026-05-01 — Phase 15 planning complete (3 plans: 15-01 backend, 15-02 i18n catalog, 15-03 view+tests)
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 6
  completed_plans: 3
  percent: 50
---

# State

## Current Position

Phase: 15 (Language Preference) — READY TO EXECUTE
Plans: 3 (15-01, 15-02, 15-03)
Last completed: Phase 14 — Locale Infrastructure (3/3 plans, 2026-05-01)
Status: Phase 15 plans created, awaiting execution
Last activity: 2026-05-01 — Phase 15 plans written (15-01 backend wiring, 15-02 i18n catalogs, 15-03 view+tests)
Resume: `/gsd-execute-phase 15` — execute Phase 15 plans

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-01)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.
**Shipped:** v1.1 (2026-04-27), v1.2 (2026-04-29), v1.3 (2026-04-30)
**Current milestone:** v1.4 — Internationalization

## v1.4 Roadmap

| Phase | Name | Status |
|-------|------|--------|
| 14 | Locale Infrastructure | Complete (2026-05-01) |
| 15 | Language Preference | Planned (2026-05-01); 3 plans, ready to execute |
| 16 | Core Shell & Shared Messages Translation | Not started |
| 17 | Feature Surface Translation | Not started |
| 18 | Auth, 2FA & Translation Verification | Not started |

## Accumulated Context

### Shipped in v1.4 so far

- `preferences.locale` nullable string column (migration `20260501020618_add_locale_to_preferences`)
- `Preference::SUPPORTED_LOCALES = %w[ja en].freeze` + `validates :locale, inclusion:` model contract
- `config.i18n.available_locales = %i[ja en]` boot-time restriction (combined with `enforce_available_locales = true`)
- `Localization` controller concern (`app/controllers/concerns/localization.rb`) — `around_action :set_locale` (thread-safe), saved → Accept-Language → :ja resolution pipeline with whitelist guard at every step, q-value-aware Accept-Language parser, no `params[:locale]` recognition
- `ApplicationController` includes `Localization` as the first include (before `protect_from_forgery` / `authenticate_user!`)
- `<html lang="<%= I18n.locale %>">` in `app/views/layouts/application.html.erb`
- `test/controllers/application_controller_test.rb` covers all 4 VERI18N-01 paths via integration tests asserting `<html lang>` attribute

### Critical Pitfalls (carry forward to Phase 15+)

- **Zeitwerk boot order:** `config/application.rb` cannot reference `Preference::SUPPORTED_LOCALES` (uninitialized constant at boot). Use inline `%i[ja en]` and treat the duplication as documented (with comment).
- **Puma thread reuse:** `I18n.locale` is thread-local; always use `around_action` + `I18n.with_locale` (NEVER `before_action`) to prevent locale bleed across requests reusing the same thread.
- **Whitelist before with_locale:** Even though `enforce_available_locales = true` raises on bad input, the concern MUST whitelist via `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` BEFORE calling `I18n.with_locale` — silent fall-through is the contract for stale DB / malformed Accept-Language values.
- **Carry forward from v1.3:** Rails 8.1 `has_many ... delete_all` nullify incompatibility with NOT NULL FK; theme leakage requires both ERB guard + CSS scope; CSRF use `form_with(local: true)`.

## Quick Tasks Completed

| # | Description | Date | Commit |
|---|-------------|------|--------|
| 260501-q01 | Replace Bookmarks nav with Home/Note in simple theme menu | 2026-05-01 | 66f2ebf |
| 260501-q02 | Remove simple-tabstrip nav (superseded by menu links) | 2026-05-01 | f73c484, 090f7cc |
| 260501-q03 | simple theme — Note tab visibility toggle via use_note preference | 2026-05-01 | f7b2267, bf98fd1, d8fb406 |
| 260501-q04 | remove table 'tweets' since there is no reference to it | 2026-05-01 | 3f215d4 |
| 260501-q05 | Font size preference (large, medium, small) | 2026-05-01 | 7ac28f1, e8608a0 |

## Session Continuity

Last session: 2026-05-01T03:27:00Z
Stopped at: Phase 15 plans written — 3 PLAN.md across 2 waves (15-01 + 15-02 parallel, 15-03 depends on both)
Resume: `/gsd-execute-phase 15` — execute Phase 15 plans (recommended)
        or `/gsd-plan-phase 15 --reviews` — replan with cross-AI review feedback
