---
gsd_state_version: 1.0
milestone: v1.18
milestone_name: X (Twitter) Account Following
status: ready
stopped_at: null
last_updated: "2026-05-14T01:35:00.000Z"
last_activity: 2026-05-14
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# State

## Current Position

Phase: 60 (not started — awaiting `/gsd-plan-phase 60`)
Plan: —
Status: Roadmap created, ready for phase planning
Last activity: 2026-05-14 — v1.18 roadmap created (4 phases, 31 REQ-IDs, 100% coverage)

Progress: [░░░░░░░░░░] 0% (0/4 phases)

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

- **v1.18 で解消される v1.17 carry-forward:** `users.{provider, uid, token}` への書き込み一貫性 — Phase 60 (XAUTH-01) で `from_omniauth` Twitter ブランチが create / update 両方で全 4 フィールド (`provider, uid, token, token_secret`) を保存するように改修される。
- **v1.18 では解消しない v1.17 carry-forward（v1.19+ へ送り）:** PITFALL-02 (`from_omniauth` Twitter ブランチのルックアップを `name` ベース → `uid` ベースに切り替える) — Phase 60 で prerequisite（`users.uid` の persistence）は満たされるが、ルックアップ切り替え自体は pre-v1.18 ユーザーの identity semantics に影響するため別マイルストーン (`XAUTH-FUT-01`)。
- **v1.18 で再評価する v1.17 carry-forward:** EDGE-03（email リンク + Google サインイン時に `provider`/`uid` カラムが Twitter のままになる）— XAUTH-01 で Twitter 再認可のたびに `provider/uid/token/token_secret` を上書きするため、Google サインイン時の挙動は変えない（Google ブランチでは依然書き込まない）。残る懸念は変わらず、別途タスク化。

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-05-14 — v1.18 milestone started, リサーチ完了 (4 軸 + シンセサイザ), REQUIREMENTS.md 31 件作成, ロードマップ作成（Phases 60–63, 100% coverage）.

Resume: `/gsd-plan-phase 60` から実行開始。
