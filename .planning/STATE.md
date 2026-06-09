---
gsd_state_version: 1.0
milestone: v1.34
milestone_name: milestone
status: "v1.34 shipped — run /gsd:new-milestone to start next milestone"
last_updated: "2026-06-09T09:28:20.338Z"
last_activity: 2026-06-09 - Completed quick task 260609-pnm: refresh landing page
progress:
  total_phases: 15
  completed_phases: 5
  total_plans: 5
  completed_plans: 5
  percent: 33
---

# State

## Current Position

Phase: — (milestone complete)
Plan: —
Status: v1.34 shipped — run /gsd:new-milestone to start next milestone
Last activity: 2026-06-09 — Completed quick task 260609-pnm: refresh landing page

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-24)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** Planning next milestone (v1.35)

## Performance Metrics

- v1.34 close: `yarn run lint` ✓ · `bin/rails test` 587/587 ✓ · `dad:test` 38/38 ✓
- v1.33 close: `yarn run lint` ✓ · `bin/rails test` 567/567 ✓ · `dad:test` 35/35 ✓
- v1.32 close: `yarn run lint` ✓ · `bin/rails test` 559/559 ✓ · `dad:test` 34/34 ✓

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2 | ACCT-FUT-01b scheduled purge job after 90 days | open |
| v2 | ACCT-FUT-03 data export before purge | open |
| v2 | PURGE-FUT-01 bulk purge of all eligible accounts | open |
| v2 | XMAN-FUT-01 total cap on manually-added accounts | open |
| v2 | XMAN-FUT-02 bulk add by handle list | open |
| v2 | XMAN-FUT-03 dedicated remove action for manually-added accounts | open |
| v2 | IDNT-FUT-01 connect new OAuth provider from preferences page | open |
| v2 | FORM-FUT-01 change password from preferences without reset flow | open |

## Accumulated Context

### Decisions

- (v1.34) `oauth_identities` table uses unique index on `(user_id, provider)` — one row per provider per user
- (v1.34) `password_auth_enabled` defaults to `false` — no existing users have set passwords via the reset flow
- (v1.34) Disconnect safety guard: blocked if no other linked provider AND `password_auth_enabled: false`
- (v1.34) No "connect new provider" from preferences — sign-in pages remain the only linking surface
- (v1.33) Facebook uses email-based find-or-create in `User.from_omniauth`, same pattern as `:google_oauth2`; `scope: 'email'` only — no `public_profile`
- (v1.33) No live Facebook OAuth round-trip in Cucumber — static presence check is sufficient for CI
- (v1.32) `purge!` uses explicit `delete_all` per table; final `user.delete` (not `destroy!`)
- (v1.32) `portal_layouts` deleted via `PortalLayout.where(user_id: id).delete_all`
- (v1.32) Cucumber `@admin_purge` uses `purge_e2e_test@example.com` — avoids fixture id 1/2/3
- (v1.31) `upsert_manual!` + refresh guard for manually-added X accounts
- (v1.30) Admin users list at `/admin/users` with `require_admin` gate

### Blockers/Concerns

- Mobile scroll stickiness: `e.preventDefault()` in `portal_mobile_tabs.js` hijacks native scroll if initial touch is slightly horizontal. (Identified 2026-06-04)

### Quick Tasks Completed

| # | Description | Date | Directory |
|---|-------------|------|-----------|
| 20260523-obsolete-adr-audit | Audit for obsolete ADRs / stale decision docs | 2026-05-23 | [20260523-obsolete-adr-audit](./quick/20260523-obsolete-adr-audit/) |
| 20260523-001 | Admin users index pagination (50 per page) | 2026-05-23 | [20260523-001-admin-users-pagination](./quick/20260523-001-admin-users-pagination/) |
| 20260524-oauth-promote | Promote Google/X OAuth buttons above email form | 2026-05-24 | [20260524-oauth-promote](./quick/20260524-oauth-promote/) |
| 20260525-add-lock-version-users | Add lock_version to users table | 2026-05-25 | [20260525-add-lock-version-users](./quick/20260525-add-lock-version-users/) |
| 20260525-refresh-landing-page | Refresh landing page | 2026-05-25 | [20260525-refresh-landing-page](./quick/20260525-refresh-landing-page/) |
| 20260602-suppress-email-autofocus-on-signup | Suppress autofocus on sign-up email field | 2026-06-02 | [20260602-suppress-email-autofocus-on-signup](./quick/20260602-suppress-email-autofocus-on-signup/) |
| 20260604-check-mobile-drag-duration | Identify mobile gadget drag duration | 2026-06-04 | [20260604-check-mobile-drag-duration](./quick/20260604-check-mobile-drag-duration/) |
| 20260604-check-mobile-swipe-thresholds | Identify mobile swipe thresholds | 2026-06-04 | [20260604-check-mobile-swipe-thresholds](./quick/20260604-check-mobile-swipe-thresholds/) |
| 20260604-investigate-mobile-scroll-stickiness | Document mobile scroll stickiness root cause | 2026-06-04 | [20260604-investigate-mobile-scroll-stickiness](./quick/20260604-investigate-mobile-scroll-stickiness/) |
| 260606-188 | ブックマークガジェット部分リロード | 2026-06-05 | [260606-188-bookmark-gadget-partial-reload](./quick/260606-188-bookmark-gadget-partial-reload/) |
| 260609-peo | TODO強調表示 | 2026-06-09 | [260609-peo-todo](./quick/260609-peo-todo/) |
| 260609-pnm | refresh landing page | 2026-06-09 | [260609-pnm-refresh-landing-page](./quick/260609-pnm-refresh-landing-page/) |

## Operator Next Steps

- Run `/gsd:plan-phase 114` to start Phase 114
