---
status: complete
phase: 10-data-layer
source: 10-01-SUMMARY.md, 10-02-SUMMARY.md, 10-03-SUMMARY.md
started: 2026-04-30T07:59:50Z
updated: 2026-04-30T08:10:33Z
---

## Current Test

number: "[testing complete]"

## Tests

### 1. notes テーブルのスキーマ確認
expected: db/schema.rb に `notes` テーブルが存在し、body (text, not null), user_id (integer, not null), created_at/updated_at, deleted (boolean, default: false), composite index (user_id, created_at) がある
result: pass

### 2. Note モデルの構造確認
expected: app/models/note.rb が存在し、`belongs_to :user`、`include Crud::ByUser`、`validates :body, presence: true, length: { maximum: 4000 }`、`:recent` スコープ、soft-delete の `destroy` オーバーライドが実装されている
result: pass

### 3. Note モデルのユニットテスト
expected: `bin/rails test test/models/note_test.rb` を実行すると 8 runs, 0 failures, 0 errors — 所有権・バリデーション・recent スコープ・soft-delete がすべてグリーン
result: pass

### 4. User アソシエーション確認
expected: app/models/user.rb に `has_many :notes, dependent: :destroy` が存在する
result: issue
reported: "Note model overrides destroy() for soft-delete, but Bookmark uses an explicit destroy_logically! instead — overriding the framework method is non-standard. Note should follow the same pattern."
severity: major

### 5. ルーティング確認
expected: config/routes.rb に `resources :notes, only: [:create, :destroy]` が存在し、`bin/rails routes` で `POST /notes` と `DELETE /notes/:id` が確認できる
result: [pending]

## Summary

total: 5
passed: 3
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Note model follows the same explicit soft-delete pattern as Bookmark (destroy_logically! instead of overriding destroy)"
  status: failed
  reason: "User reported: Note model overrides destroy() for soft-delete, but Bookmark uses an explicit destroy_logically! instead — overriding the framework method is non-standard. Note should follow the same pattern."
  severity: major
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
- truth: "resources :notes is placed alphabetically between :feeds and :preferences in config/routes.rb"
  status: failed
  reason: "User reported: routes exist and work, but resources :notes should be placed alphabetically between :feeds and :preferences, not between :todos and :welcome"
  severity: minor
  test: 5
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
