---
gsd_state_version: 1.0
milestone: v1.17
milestone_name: Email Registration for X/Twitter Users
status: planning
stopped_at: "Phase 58 context gathered"
last_updated: "2026-05-13T00:02:00.000Z"
last_activity: 2026-05-13
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 58 — Controller, Route, and Guards (context captured)
Plan: —
Status: Context discussed; ready to plan Phase 58
Last activity: 2026-05-13 — Phase 58 context captured (self-discuss)

Progress: [░░░░░░░░░░] 0% (0/3 phases)

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-13)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

**Current focus:** v1.17 — Email Registration for X/Twitter Users. Phases 57–59.

## Performance Metrics

v1.16 execution gate passed with tri-suite policy: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (Cucumber flake rerun policy per `CLAUDE.md`).

## Accumulated Context

### Decisions

- v1.17 architecture: dedicated `EmailRegistrationsController` (NOT PreferencesController extension) — prevents writable-email surface for all users and avoids `save!` 500 on validation failure.
- v1.17 validator scope: `on: :update` only — Twitter `from_omniauth` create path legitimately writes dummy addresses; the validator must not fire on create.
- v1.17 collision guard (CTRL-02) is a security prerequisite and ships in Phase 58 before any UI (Phase 59).
- v1.17 no email confirmation (`:confirmable` out of scope — no DB columns, no mailer pipeline; Google OAuth provides implicit verification).
- v1.17 no new gems, no migration — `users.email` + unique index already exist; Devise `:validatable` handles format/uniqueness.
- v1.17 PITFALL-02 (Twitter `from_omniauth` uses `name` not `uid`) is pre-existing; must NOT be mixed into v1.17 — log as separate task.
- Collision error wording: use Devise default ("has already been taken") — safe; does not confirm another account exists.
- Phase 58 route: `users/email_registration` under `users/` prefix (explicit routes, matching two_factor_setup convention). Controller: `Users::EmailRegistrationsController`. Path helper: `users_email_registration_path`.
- Phase 58 save mechanism: `save` (not `save!`) in `create` — validation failures re-render form. `rescue ActiveRecord::RecordNotUnique` inline in `create` only.
- Phase 58 strong params: `:email_registration` wrapper (not `:user`) — avoids Devise param collision.
- Phase 58 success redirect: `preferences_path`.

### Pending Todos

- Log PITFALL-02 fix as a separate task: `from_omniauth` Twitter branch should use `uid` + `provider` columns instead of `name`.
- Log EDGE-03: after email link + Google sign-in, `provider`/`uid` columns remain Twitter values — any future `uid`+`provider` lookup refactor must handle this.
- Confirm whether current codebase writes to `users.provider` or `users.uid` at all.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-05-13 (Phase 58 context captured — self-discuss)

Resume file: `.planning/phases/058-controller-route-and-guards/058-CONTEXT.md`

Resume: `/gsd-plan-phase 58`
