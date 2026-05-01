---
phase: quick-260501-onx
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - features/support/env.rb
  - features/step_definitions/todos.rb
autonomous: true
requirements:
  - QUICK-FLAKE-01
must_haves:
  truths:
    - "features/02.タスク.feature の2シナリオが実行順に依存せず安定して通る"
    - "タスク設定操作が表示ラベル翻訳や表記揺れに依存せず要素特定できる"
  artifacts:
    - path: "features/support/env.rb"
      provides: "各シナリオ開始前に preference の既定値を明示的にリセットするフック"
    - path: "features/step_definitions/todos.rb"
      provides: "check/select/click のセレクタ安定化と todo_actions 表示待ちの堅牢化"
  key_links:
    - from: "features/support/env.rb"
      to: "features/02.タスク.feature"
      via: "Before hook"
      pattern: "Before do"
    - from: "features/step_definitions/todos.rb"
      to: "app/views/preferences/index.html.erb"
      via: "name/id ベースのフォーム要素選択"
      pattern: "find\\(|check\\(|select\\("
---

<objective>
Order-dependent Cucumber flake を解消し、タスク機能シナリオを安定化する。

Purpose: シナリオ順序やロケールに左右される失敗をなくし、再実行不要の安定テストにする。  
Output: preference 初期化フック + todos step のセレクタ堅牢化。
</objective>

<context>
@.planning/STATE.md
@features/02.タスク.feature
@features/support/env.rb
@features/step_definitions/todos.rb
@app/views/preferences/index.html.erb
@app/views/todos/_actions.html.erb
</context>

<tasks>

<task type="auto">
  <name>Task 1: シナリオ前に preference 既定値を強制リセットして状態リークを遮断</name>
  <files>features/support/env.rb</files>
  <action>Before フックを追加し、対象ユーザーの Preference を毎シナリオ開始時に既定状態（少なくとも use_todo/use_note/default_priority を feature 前提値）へ update する。DBに既存値があれば上書きし、無ければ作成して初期化する。これで scenario-order による .todo_actions / #notes-tab-panel 非表示化の持ち越しを防ぐ。</action>
  <verify>
    <automated>bundle exec cucumber features/02.タスク.feature --format progress</automated>
  </verify>
  <done>どの順序で実行しても当該 feature の前提 UI 状態がシナリオ開始時に一貫する。</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: todos step をラベル依存から name/id ベース選択へ置換</name>
  <files>features/step_definitions/todos.rb</files>
  <behavior>
    - Test 1: ロケールが ja/en どちらでも use_todo チェック操作が成功する
    - Test 2: default_priority 選択が表示ラベルではなく select 要素特定で成功する
    - Test 3: 新規タスク導線は #todo .todo_actions の存在確認後に進み、間欠失敗しない
  </behavior>
  <action>`check 'タスクウィジェットを表示する'` と `select ... from: 'タスク追加時の初期優先度'` を、`preference_attributes_use_todo` や `user_preference_attributes_default_priority` 等の安定した id/name セレクタ基準に変更する。`.todo_actions` の確認は `#todo .todo_actions` にスコープし、必要な待機を明示して誤検知を避ける。</action>
  <verify>
    <automated>bundle exec cucumber features/02.タスク.feature --format progress && bundle exec cucumber features/02.タスク.feature --format progress</automated>
  </verify>
  <done>チェックボックス/セレクトの要素特定が文言非依存になり、同一 feature 連続実行で flaky 再現が止まる。</done>
</task>

<task type="auto">
  <name>Task 3: 回帰確認（関連シナリオ群の順序依存が消えたことを検証）</name>
  <files>features/step_definitions/todos.rb, features/support/env.rb</files>
  <action>タスク feature とノート表示系シナリオを連続実行し、順序入替でも .todo_actions / #notes-tab-panel 欠落が起きないことを確認する。失敗時は step 内のスコープ不足箇所を追加修正して再実行する。</action>
  <verify>
    <automated>bundle exec cucumber features/02.タスク.feature features --format progress</automated>
  </verify>
  <done>対象 flaky 2系統（checkbox 検出失敗・表示要素欠落）が再現せず、quick task の受け入れ条件を満たす。</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| test step→browser DOM | テストコードがUI要素を誤検出すると誤った操作を実行する |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick-01 | T | features/step_definitions/todos.rb | mitigate | ラベル文字列ではなく id/name で要素選択し、翻訳差分による誤動作を防ぐ |
| T-quick-02 | D | features/support/env.rb | mitigate | Before フックで preference 状態を毎回初期化し、状態リークでシナリオが停止するリスクを抑止 |
</threat_model>

<verification>
- `bundle exec cucumber features/02.タスク.feature --format progress` が安定して成功すること
- 連続実行・広域実行でも対象 flaky が再発しないこと
</verification>

<success_criteria>
- 「タスクウィジェットを表示する」チェックボックス未検出エラーが発生しない
- `.todo_actions` / `#notes-tab-panel` 欠落が scenario-order 非依存で発生しない
- 変更範囲が cucumber support/step definitions 内に収まっている
</success_criteria>
