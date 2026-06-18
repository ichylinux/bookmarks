# Phase 128: Test Coverage & Tri-Suite Gate - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped — autonomous from ROADMAP)

<domain>
## Phase Boundary

Phase 127 で実装したヘッダ集約の完了操作を自動テストで保護し、トライスイートをグリーンに保つ。Minitest（構造 + controller）と Cucumber E2E（選択→ヘッダ完了→一覧から消える）を追加する。

</domain>

<decisions>
## Implementation Decisions

### Test placement
- 構造テストは既存 `dashboard_test.rb` に追加（127 で既に complete-link アサーションあり）
- `TodosController#delete` のバッチ完了・空配列 no-op は `todos_controller_test.rb` に追加
- Cucumber は `features/02.タスク.feature` にシナリオ追加、`features/step_definitions/todos.rb` にステップ追加

### Claude's Discretion
- 127-VERIFICATION で deferred された 3 ランタイム挙動（HDR-02/03, SEL-02 E2E）をこのフェーズでカバー

</decisions>

<deferred>
## Deferred Ideas

None.

</deferred>
