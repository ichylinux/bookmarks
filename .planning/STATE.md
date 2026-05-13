---
gsd_state_version: 1.0
milestone: v1.18
milestone_name: X (Twitter) Account Following
status: planning
stopped_at: null
last_updated: "2026-05-14T01:05:00.000Z"
last_activity: 2026-05-14
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
Last activity: 2026-05-14 — Milestone v1.18 started

Progress: [░░░░░░░░░░] 0%

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-14)

**Core value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

**Current focus:** v1.18 X (Twitter) Account Following — Twitter サインインユーザーが自分のフォロー中アカウントから選択して welcome ガジェットに表示する。X API v2 Basic 前提、Mastodon (v1.16) パターン最大限流用。

## Performance Metrics

(Will be set at first phase completion. Gate: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test`.)

## Accumulated Context

### Decisions

- (v1.18 起動時) X API v2 Basic プラン前提（既契約／契約予定）。テストはスタブで動かす（v1.16 流儀）。
- (v1.18 起動時) フォロー一覧 = DB キャッシュ + 手動再取得 / ツイート = welcome 表示時ライブ取得（バックグラウンドジョブ無し）。
- (v1.18 起動時) `omniauth-twitter`（OAuth 1.0a User Context）を維持。X API v2 も同方式で叩く。
- (v1.18 起動時) Mastodon (v1.16) パターン（CRUD + `Portal#get_gadgets` + AJAX `show`）を流用。新規 UX は「フォロー一覧 → 選択」フローのみ。
- (Prior v1.17) Dedicated `Users::EmailRegistrationsController`; validator `on: :update`; collision + `RecordNotUnique` rescue; success redirect `preferences_path`.

### Pending Todos

- v1.17 carry-forward: PITFALL-02 (`from_omniauth` Twitter branch should use `uid` + `provider` instead of `name`) — v1.18 の OAuth 拡張フェーズで同時に解消する想定。
- v1.17 carry-forward: EDGE-03（email リンク + Google サインイン時に `provider`/`uid` カラムが Twitter のままになる）— 上の OAuth 拡張で再評価。
- v1.17 carry-forward: `users.provider` / `users.uid` への書き込み一貫性確認 — 同上。

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-05-14 — v1.18 milestone started (`/gsd-new-milestone X(Twitter) Account Following`). PROJECT.md updated with Current Milestone section.

Resume: 要件定義 → `/gsd-plan-phase 60` から実行開始（フェーズ番号は roadmap 作成で確定）。
