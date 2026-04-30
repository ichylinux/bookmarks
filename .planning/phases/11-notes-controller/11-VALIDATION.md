---
phase: 11
slug: notes-controller
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 11 — Validation Strategy

> Nyquist 契約: PLAN 11-01 の自動検証コマンドと `notes_controller_test.rb` を一本化し、タスクごとのトレース可能性をもたせる。

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest (`ActionDispatch::IntegrationTest` + ルーティングアサーション) |
| **Config file** | `test/test_helper.rb`, `ENV['RAILS_ENV']=test` |
| **Quick run command** | `bin/rails test test/controllers/notes_controller_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | 全スイート ~2.5s–120s（環境依存）、コントローラに絞り ~1–2s |

---

## Sampling Rate

- **After every task commit:** `bin/rails test test/controllers/notes_controller_test.rb`
- **After wave / plan completion:** `bin/rails test`
- **Before `/gsd-verify-work`:** Full suite must be green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Must-have / threat trace | Automated command | Test evidence | Status |
|---------|------|------|-------------|-------------------------|---------------------|---------------|--------|
| 11-01-01 | 01 | 1 | NOTE-01 | POST のみ（`destroy` 未定義）・攻撃面最小 — PLAN trust boundary「Route surface」 | `bin/rails test test/controllers/notes_controller_test.rb` | `test_routing_post_notes_to_create`, `test_delete_notes_member_not_routed` | **COVERED** |
| 11-01-02 | 01 | 1 | NOTE-01 | T-11-01: `user_id` 昇格阻止（`permit` + `merge`）／T-11-03: 他ユーザー名義作成不可 | 同上 | `test_user_id_param_cannot_override_current_user`, `test_successful_create` | **COVERED** |
| 11-01-03 | 01 | 1 | NOTE-01 | T-11-02: 未認証 POST → サインイン／無効 body・長さ超過は非作成 + `flash[:alert]` | 同上 | `test_unauthenticated_redirects_to_sign_in`, `test_blank_body_does_not_create`, `test_body_over_max_length_does_not_create` | **COVERED** |

---

## Wave 0 Requirements

- 新規テストランナーは不要 — 既存 Minitest + `fixtures :all`。プラン検証にある `grep` / `rails routes` は `11-VERIFICATION.md` と CI 運用で補強。

---

## Manual-Only Verifications

*(なし)* — 本フェーズのプラン検証項目は自動テストおよび既存 PLAN verification コマンドで実行可能。

---

## Validation Audit 2026-04-30

| Metric | Count |
|--------|-------|
| Gaps found | 4（ドラフト時の pending 行 3 + ルート明示テストの欠落） |
| Resolved | 4 |
| Escalated | 0 |

**Actions:** `Per-Task Verification Map` を実装に合わせて更新。Task 1（ルート面）向けに `test_routing_post_notes_to_create` と `test_delete_notes_member_not_routed` を追加。全スイートグリーンを確認。

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter when approved

**Approval:** verified 2026-04-30
