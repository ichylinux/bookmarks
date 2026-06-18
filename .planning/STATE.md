---
gsd_state_version: 1.0
milestone: null
milestone_name: null
current_phase: null
current_phase_name: null
status: between_milestones
last_updated: "2026-06-19T15:00:00Z"
last_activity: 2026-06-19
last_activity_desc: v1.36.0 milestone archived and tagged
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Milestone: v1.36.0 — ARCHIVED ✅
Status: Between milestones — ready for `/gsd-new-milestone`
Last activity: 2026-06-19 — v1.36.0 archived

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-19)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** Start next milestone with `/gsd-new-milestone`

## Performance Metrics

- v1.36.0 close: `yarn run lint` ✓ · `bin/rails test` 681/681 ✓ · `dad:test` 39/39 ✓
- v1.35.1 close: `yarn run lint` ✓ · `bin/rails test` 667/667 ✓ · `dad:test` 38/38 ✓
- v1.34 close: `yarn run lint` ✓ · `bin/rails test` 587/587 ✓ · `dad:test` 38/38 ✓

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2 | HDR-FUT-01 行ごとの個別「完了」操作（タスク単位のワンクリック完了） | open |
| v2 | HDR-FUT-02 ヘッダに「すべて選択 / 選択解除」トグル | open |
| v2 | ACCT-FUT-01b scheduled purge job after 90 days | open |
| v2 | ACCT-FUT-03 data export before purge | open |
| v2 | PURGE-FUT-01 bulk purge of all eligible accounts | open |
| v2 | XMAN-FUT-01 total cap on manually-added accounts | open |
| v2 | XMAN-FUT-02 bulk add by handle list | open |
| v2 | XMAN-FUT-03 dedicated remove action for manually-added accounts | open |
| v2 | IDNT-FUT-01 connect new OAuth provider from preferences page | open |
| v2 | FORM-FUT-01 change password from preferences without reset flow | open |
| debug | disconnect-form-auth-error [awaiting_human_verify] | deferred at v1.35 close |
| quick_task | lock-version-oauth-disconnect (20260529) | deferred at v1.35 close |

## Accumulated Context

### Decisions

- (v1.36.0) 完了アクションはガジェットヘッダ（「新規」リンクと同じ行）に集約；旧 `.todo_actions` 独立 `<li>` 行は撤廃
- (v1.36.0) 既存のタップ選択（行クリック → `span.selected` チェックマーク）と一括完了バックエンド `POST /todos/delete` を流用 — 新規 JS ライブラリは導入しない（Sprockets + jQuery 制約）
- (v1.34) `oauth_identities` table uses unique index on `(user_id, provider)` — one row per provider per user
- (v1.34) `password_auth_enabled` defaults to `false` — no existing users have set passwords via the reset flow
- (v1.34) Disconnect safety guard: blocked if no other linked provider AND `password_auth_enabled: false`
- (v1.34) No "connect new provider" from preferences — sign-in pages remain the only linking surface

### Blockers/Concerns

- Mobile scroll stickiness: `e.preventDefault()` in `portal_mobile_tabs.js` hijacks native scroll if initial touch is slightly horizontal. (Identified 2026-06-04)

## Operator Next Steps

- Start next milestone: `/gsd-new-milestone`
