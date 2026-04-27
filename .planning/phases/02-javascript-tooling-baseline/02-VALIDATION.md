---
phase: 2
slug: javascript-tooling-baseline
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-27
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ESLint 9 + Prettier 3 (no Jest; repo は Minitest/Cucumber が別系) |
| **Config file** | `eslint.config.js`（導入後）、`package.json` scripts |
| **Quick run command** | `yarn run lint`（プラン 01 で導入する正式名に固定） |
| **Full suite command** | `yarn run lint` 後に `RAILS_ENV=production bin/rails assets:precompile` |
| **Estimated runtime** | 〜1–3 分（初回 precompile 含む） |

## Sampling Rate

- **After every task commit:** `yarn run lint`（`lint` スクリプトが未整備のタスク序盤はスキップ可だが、Plan 01 完了後のタスクから必須）
- **After every plan wave:** 上の Full suite
- **Before `/gsd-verify-work`:** `lint` クリーン + precompile 成功
- **Max feedback latency:** 180 秒目安

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | TOOL-01 | T-2-01 / — | dev 依存はロックファイルで固定 | コマンド | `yarn run lint` | ⬜ W0 後 | ⬜ |
| 2-01-02 | 01 | 1 | TOOL-01 | — | 同上 | コマンド | `yarn run lint` | ⬜ | ⬜ |
| 2-02-01 | 02 | 1 | TOOL-02 | — | ドキュメントにコマンド文字列 | grep | `README.md` に `yarn run lint` | ✅ | ⬜ |
| 2-02-02 | 02 | 1 | 成功基準-3 | — | ビルド壊しなし | コマンド | `RAILS_ENV=production bin/rails assets:precompile` | ✅ | ⬜ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] 既存: Rails + Sprockets + Babel; Node/Yarn; Minitest/Cucumber は別系で維持
- [ ] 新規: ESLint/Prettier 導入（Plan 01）

*Wave 0 = 本リポに既存のテスト基盤; JS リント用コマンドは Plan 01 で追加*

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| 新規依存の審査 | TOOL-01 | 判断が要る | `yarn.lock` 差分をレビューし、devDependencies のみに限定したことを確認する |

*If none: 上記のとおり 1 行のみ（それ以外は自動化でカバー）*

## Validation Sign-Off

- [ ] All tasks have `<verify>` または等価の acceptance_criteria
- [ ] Sampling continuity: 連続 3 タスクで lint なし、を避ける（Plan 01 完了後は各タスクで lint 可能）
- [ ] No watch-mode flags in CI doc
- [ ] `nyquist_compliant: true` へ更新（UAT 前）

**Approval:** pending
