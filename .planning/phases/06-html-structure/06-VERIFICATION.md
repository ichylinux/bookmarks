# Phase 06 Verification (HTML Structure)

**Status:** in_progress  
**Phase:** 06-html-structure  
**Requirements in scope:** NAV-01, NAV-02  
**Verified commit SHA:** `TBD`  
**Recorded at:** TBD

---

## Baseline runs

| Suite | Command | Outcome | Evidence |
|---|---|---|---|
| Lint | `yarn run lint` | PENDING | To be recorded in Plan 21-02 |
| Minitest | `bin/rails test` | PENDING | To be recorded in Plan 21-02 |
| Cucumber (run 1) | `bundle exec rake dad:test` | PENDING | To be recorded in Plan 21-02 |
| Cucumber (run 2) | `bundle exec rake dad:test` | PENDING | To be recorded in Plan 21-02 |
| Combined full check | `yarn run lint && bin/rails test && bundle exec rake dad:test` | PENDING | To be recorded in Plan 21-02 |

### Flake / rerun log

| Run | Command | Outcome | Classification |
|---|---|---|---|
| 1 | `bundle exec rake dad:test` | PENDING | To be classified in Plan 21-02 |
| 2 | `bundle exec rake dad:test` | PENDING | To be classified in Plan 21-02 |

Policy pointer: see `CLAUDE.md` section **"Cucumber suite — known flakiness"**.

---

## Core traceability table

| Claim ID | REQ-ID(s) | Claim summary | Status | Confidence | Evidence block |
|---|---|---|---|---|---|
| P06-C01 | NAV-01 | モダンテーマでヘッダーにハンバーガーボタンが表示される | PENDING | PENDING | § P06-C01 |
| P06-C02 | NAV-02 | モダンテーマでドロワーを開いてナビゲーションできる | PENDING | PENDING | § P06-C02 |
| P06-C03 | NAV-01, NAV-02 (+ Phase 6 criterion 4) | 非モダン契約（classic + simple）で既存動作が維持される | PENDING | PENDING | § P06-C03 |

---

### P06-C01 — モダンテーマでヘッダーにハンバーガーボタンが表示される

- **Requirement rows:** NAV-01 — "User sees a hamburger button in the header when using the modern theme"
- **Evidence type:** automated test + code reference
- **Artifact:**
  - `test/controllers/welcome_controller/layout_structure_test.rb` の `test_モダンテーマでハンバーガーボタンが表示される`
  - `app/views/layouts/application.html.erb` の `button.hamburger-btn` 描画分岐（`drawer_ui?`）
- **Run record:** baseline runs section（Plan 21-02で最終記録）
- **Confidence:** PENDING — Plan 21-02で確定

### P06-C02 — モダンテーマでドロワーを開いてナビゲーションできる

- **Requirement rows:** NAV-02 — "User can open a side drawer containing all navigation links by clicking the hamburger"
- **Evidence type:** automated test + code reference + interaction scenario
- **Artifact:**
  - `features/03.モダンテーマ.feature` のモダン系シナリオ（開閉・overlay・Escape・リンク遷移）
  - `features/step_definitions/modern_theme.rb` のドロワー操作ステップ
  - `app/assets/javascripts/menu.js` の `hamburger-btn` / `drawer-overlay` / `keydown` / `drawer nav` ハンドラ
  - `test/controllers/welcome_controller/layout_structure_test.rb` のドロワー構造・リンク検証
- **Run record:** baseline runs section（Plan 21-02で最終記録）
- **Confidence:** PENDING — Plan 21-02で確定

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
- **Run record:** baseline runs section（Plan 21-02で最終記録）
- **Confidence:** PENDING — Plan 21-02で確定

---

## Mismatch handling log

- **root cause:** PENDING
- **action taken:** PENDING
- **re-verification:** PENDING

---

## Current phase-closure state

Phase 21 実行中。Plan 21-02 で baseline tri-suite を記録し、`P06-C01..C03` を PASS/FAIL 確定する。
