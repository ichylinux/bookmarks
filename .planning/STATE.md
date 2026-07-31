---
gsd_state_version: 1.0
milestone: v1.37.0
milestone_name: モバイルでのタスク追加機能
status: Awaiting next milestone
stopped_at: context exhaustion at 82% (2026-06-26)
last_updated: "2026-07-31T12:45:00.000Z"
last_activity: 2026-07-31
last_activity_desc: "Completed quick task 260731-u3v: mobile feed gadget settings tap reveal"
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
current_phase: 37.0
---

# State

## Current Position

Phase: Milestone v1.37.0 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-07-31 - Completed quick task 260731-u3v: mobile feed gadget settings tap reveal

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-26)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.
**Current focus:** Plan and execute Phase 129 with `/gsd-plan-phase 129`

## Performance Metrics

- v1.37.0 close: `yarn run lint` ✓ · `bin/rails test` 684/684 ✓ · `dad:test` 40/40 ✓
- v1.36.0 close: `yarn run lint` ✓ · `bin/rails test` 681/681 ✓ · `dad:test` 39/39 ✓
- v1.35.1 close: `yarn run lint` ✓ · `bin/rails test` 667/667 ✓ · `dad:test` 38/38 ✓
- v1.34 close: `yarn run lint` ✓ · `bin/rails test` 587/587 ✓ · `dad:test` 38/38 ✓

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-06-27:

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
| v2 | LOC-FUT-01 英語ロケールキー `welcome.todo_gadget.new_link` を "Add" に変更 | open |
| v2 | MOB-FUT-01 auto-focus — iOS Safari AJAX callback 制限により延期 | open |
| v2 | MOB-FUT-02 キャンセルボタン — 空タイトル dismiss が既存パターンのため延期 | open |
| debug | disconnect-form-auth-error [awaiting_human_verify] | deferred at v1.35 close; still open at v1.37.0 close |
| quick_task | lock-version-oauth-disconnect (20260529) | deferred at v1.35 close |
| quick_task | 260615-0jw-integrate-note-into-mobile-swipe-cycle-w | deferred at v1.37.0 close (unknown status) |
| quick_task | 260615-9r6-refresh-landing-page | deferred at v1.37.0 close (unknown status) |
| quick_task | 260617-2nf-todo-undo-b | deferred at v1.37.0 close (missing) |

## Accumulated Context

### Decisions

- (v1.37.0) CSS-only approach for mobile layout — no JS changes to `todos.js`; `_form.html.erb` partial is NOT touched (shared by 3 render contexts)
- (v1.37.0) `@media (hover: none)` override scoped to `.todo-gadget-new-link` only in `welcome.css.scss` (MOB-01)
- (v1.37.0) `flex-wrap: wrap` added inside `.todo` scope in `todos.css.scss` mobile media query block (MOB-02)
- (v1.37.0) `<div class="todo">` wrapper added to `new.html.erb` and `edit.html.erb` standalone pages only (MOB-03)
- (v1.37.0) `font-size: 1rem` on form inputs in mobile media query — prevents iOS Safari auto-zoom (MOB-04)
- (v1.37.0) `ensure_mobile_viewport!` must be called explicitly in Cucumber step before `visit root_path` — `@mobile_portal` tag alone does not resize (TEST-02)
- (v1.37.0) Never use bare CSS `min()`/`max()` in SCSS — wrap in `calc()` to avoid Dart Sass misparse (project precedent from v1.18)
- (v1.36.0) 完了アクションはガジェットヘッダ（「新規」リンクと同じ行）に集約；旧 `.todo_actions` 独立 `<li>` 行は撤廃
- (v1.36.0) 既存のタップ選択（行クリック → `span.selected` チェックマーク）と一括完了バックエンド `POST /todos/delete` を流用 — 新規 JS ライブラリは導入しない（Sprockets + jQuery 制約）
- (v1.34) `oauth_identities` table uses unique index on `(user_id, provider)` — one row per provider per user
- (v1.34) `password_auth_enabled` defaults to `false` — no existing users have set passwords via the reset flow
- (v1.34) Disconnect safety guard: blocked if no other linked provider AND `password_auth_enabled: false`
- (v1.34) No "connect new provider" from preferences — sign-in pages remain the only linking surface

### Blockers/Concerns

- Mobile scroll stickiness: `e.preventDefault()` in `portal_mobile_tabs.js` hijacks native scroll if initial touch is slightly horizontal. (Identified 2026-06-04)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260710-p6v | モバイルでタスク完了後にガジェットヘッダの追加ボタンが誤表示される不具合を修正 | 2026-07-10 | 2212e00 | [260710-p6v-mobile-gadget-add-btn-after-done](./quick/260710-p6v-mobile-gadget-add-btn-after-done/) |
| 260712-j75 | Fix failing Cucumber: features/02.タスク.feature:31 モバイルでタスクを完了した直後は「追加」ボタンが表示されない | 2026-07-12 | b0f4c19 | [260712-j75-fix-failing-cucumber-features-02-feature](./quick/260712-j75-fix-failing-cucumber-features-02-feature/) |
| 260716-h4d | モバイルのブックマークガジェットにタスクと同様のヘッダタップで追加ボタンを表示する機能を追加 | 2026-07-16 | 387bfb3 | [260716-h4d-mobile-bookmark-add](./quick/260716-h4d-mobile-bookmark-add/) |
| 4 | フィードガジェット編集ダイアログ更新後に閉じない問題を修正 | 2026-07-29 | 9922647 | — |
| 260729-qew | refresh landing page info | 2026-07-29 | f136f88 | [260729-qew-refresh-landing-page-info](./quick/260729-qew-refresh-landing-page-info/) |
| 260731-u3v | モバイルでフィードガジェットヘッダをタップしても「設定」ボタンが表示されない不具合を修正 | 2026-07-31 | 51c6c9b | [260731-u3v-mobile-feed-settings-tap](./quick/260731-u3v-mobile-feed-settings-tap/) |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

## Session

**Last session:** 2026-06-26T16:13:42.591Z
**Stopped at:** context exhaustion at 82% (2026-06-26)
**Resume file:** None
