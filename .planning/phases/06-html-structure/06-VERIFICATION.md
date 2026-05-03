# Phase 06 Verification (HTML Structure)

**Status:** passed  
**Phase:** 06-html-structure  
**Requirements in scope:** NAV-01, NAV-02  
**Verified commit SHA:** `c56a9a8cb1c198a3540fc0e19c61b5ecf4cc13df`  
**Recorded at:** 2026-05-03T21:22:56+09:00

---

## Baseline runs

| Suite | Command | Outcome | Evidence |
|---|---|---|---|
| Lint | `yarn run lint` | PASS | `eslint "app/assets/javascripts/**/*.js"` 完了（`Done in 0.51s.`） |
| Minitest | `bin/rails test` | PASS | `192 runs, 1103 assertions, 0 failures, 0 errors, 0 skips` |
| Cucumber (run 1) | `bundle exec rake dad:test` | FAIL | `11 scenarios (2 failed, 9 passed)`（tasks/notes の既知順序依存症状） |
| Cucumber (run 2) | `bundle exec rake dad:test` | PASS | `11 scenarios (11 passed)` |
| Combined full check | `yarn run lint && bin/rails test && (bundle exec rake dad:test || bundle exec rake dad:test)` | PASS | 一回目失敗→許容 rerun で PASS |

### Flake / rerun log

| Run | Command | Outcome | Classification |
|---|---|---|---|
| 1 | `bundle exec rake dad:test` | FAIL (`11 scenarios (2 failed, 9 passed)`) | 既知フレーク候補（`features/02.タスク.feature` / `features/04.ノート.feature`） |
| 2 | `bundle exec rake dad:test` | PASS (`11 scenarios (11 passed)`) | `CLAUDE.md` の one-rerun policy により pre-existing flake と分類 |

Policy pointer: see `CLAUDE.md` section **"Cucumber suite — known flakiness"**.

---

## Core traceability table

| Claim ID | REQ-ID(s) | Claim summary | Status | Confidence | Evidence block |
|---|---|---|---|---|---|
| P06-C01 | NAV-01 | モダンテーマでヘッダーにハンバーガーボタンが表示される | PASS | HIGH | § P06-C01 |
| P06-C02 | NAV-02 | モダンテーマでドロワーを開いてナビゲーションできる | PASS | HIGH | § P06-C02 |
| P06-C03 | NAV-01, NAV-02 (+ Phase 6 criterion 4) | 非モダン契約（classic + simple）で既存動作が維持される | PASS | HIGH | § P06-C03 |

---

### P06-C01 — モダンテーマでヘッダーにハンバーガーボタンが表示される

- **Requirement rows:** NAV-01 — "User sees a hamburger button in the header when using the modern theme"
- **Evidence type:** automated test + code reference
- **Artifact:**
  - `test/controllers/welcome_controller/layout_structure_test.rb` の `test_モダンテーマでハンバーガーボタンが表示される`
  - `app/views/layouts/application.html.erb` の `button.hamburger-btn` 描画分岐（`drawer_ui?`）
- **Run record:** baseline runs section（`bin/rails test` PASS + `dad:test` rerun PASS）
- **Confidence:** HIGH — 構造テストとレイアウト実装アンカーが一致し、差異が確認されなかった。

### P06-C02 — モダンテーマでドロワーを開いてナビゲーションできる

- **Requirement rows:** NAV-02 — "User can open a side drawer containing all navigation links by clicking the hamburger"
- **Evidence type:** automated test + code reference + interaction scenario
- **Artifact:**
  - `features/03.モダンテーマ.feature` のモダン系シナリオ（開閉・overlay・Escape・リンク遷移）
  - `features/step_definitions/modern_theme.rb` のドロワー操作ステップ
  - `app/assets/javascripts/menu.js` の `hamburger-btn` / `drawer-overlay` / `keydown` / `drawer nav` ハンドラ
  - `test/controllers/welcome_controller/layout_structure_test.rb` のドロワー構造・リンク検証
- **Run record:** baseline runs section（モダンテーマ feature シナリオ群を含む `dad:test` rerun PASS）
- **Confidence:** HIGH — ドロワーの開閉・dismiss・リンク遷移が実行結果で確認できる。

### P06-C03 — 非モダン契約（classic + simple）で既存動作が維持される

- **Requirement rows:**
  - NAV-01 / NAV-02（v1.2 requirement archive）
  - `.planning/milestones/v1.2-ROADMAP.md` Phase 6 Success Criteria **criterion 4**
    - "The existing non-modern dropdown menu and its inline `<script>` are unaffected and continue to function when a non-modern theme is active"
- **Evidence type:** automated structural test + interaction scenario + code reference
- **Artifact:**
  - `test/controllers/welcome_controller/layout_structure_test.rb`
    - `test_クラシックテーマでハンバーガーとドロワーが表示される`
    - `test_シンプルテーマではドロワーとハンバーガーがなくシンプルメニューが表示される`
  - `features/03.モダンテーマ.feature`
    - `クラシックテーマでもハンバーガー操作でドロワーを開閉できる`
    - `シンプルテーマではドロワー副作用がなくナビゲーションできる`
  - `features/step_definitions/modern_theme.rb` の classic/simple 専用ステップ
  - `app/helpers/welcome_helper.rb` の `drawer_ui?`（`favorite_theme != 'simple'`）
  - `app/assets/javascripts/menu.js` の classic/modern ガード
- **Run record:** baseline runs section（`dad:test` rerun PASS）+ `bundle exec rake dad:test features/03.モダンテーマ.feature` PASS（7 scenarios）
- **Confidence:** HIGH — classic/simple の構造証跡と相互作用証跡が両方揃い、criterion 4 の「非モダン非破壊」を満たす。

---

## Mismatch handling log

- **root cause:** **No remediation required** — 収集した証跡で NAV-01/NAV-02 と非モダン契約（classic/simple）が既存実装と整合した。
- **action taken:** **No remediation required** — 今回は verification artifact と interaction evidence 追加のみを実施。
- **re-verification:** **No remediation required**（追加修正なし）。baseline tri-suite を one-rerun policy で再実行し PASS を確認。

---

## Current phase-closure state

Phase 06 verification is **closure-ready**: `P06-C01..C03` are PASS with reproducible evidence and rerun classification.
