# Phase 2 — Research: JavaScript tooling baseline

**Status:** Research complete

## Current state (repo facts)

- **Rails 8.1** + **Sprockets** (`app/assets/javascripts/`, `//= require_tree .` in `application.js`).
- **`package.json`**: `dependencies` 空; スクリプト未整備; **Yarn** + `yarn.lock` は STACK 上は利用前提。
- **Babel** (`babel.config.js`): production/development では `preset-env` + `core-js` エントリ、`modules: false`（Sprockets バンドル向け）。
- **ESLint / Prettier** 未導入; `.eslintrc` 等なし。
- **Node** は `.node-version` で 22 系想定; CI 用標準 GitHub Actions 定義は未検出（必要なら後続で追加可）。

## Decision: スタック

| 項目 | 選定 | 理由 |
|------|------|------|
| Linter | **ESLint 9+**（flat `eslint.config.js`） | 現行推奨; Sprockets 配下の素の `.js` を直接対象にできる |
| Formatter | **Prettier 3+** | チーム体験の揃いやすさ; `eslint-config-prettier` で衝突回避 |
| 環境 | `globals` パッケージ + ブラウザ / **jQuery グローバル** | `bookmarks.js` 等は `$` / `jQuery` 前提。`jquery` グローバルに紐づく |
| 除外 | `vendor/**`、生成物、`node_modules` | 意図しない大規模差分を防ぐ |

**明示的非スコープ:** フロントのフレームワーク導入、Sprockets から Vite 等への移行。

## コマンド方針

- 開発用チェック: `yarn run lint`（名称はプラン内で `package.json` に固定、README に同じ文字列を記載＝**TOOL-02** 充足）。
- オート修正: `yarn run lint:fix` および `yarn run format`（必要なら分割）。
- 本番相性: ツールは **Node 上の dev 依存** のみ; **アセットは従来どおり Sprockets + Babel** のため、`RAILS_ENV=production` の `assets:precompile` をフェーズ成功条件の最終ゲートに含める（ロードマップ成功基準 3 一致）。

## リスクと緩和

- **Babel プリセットと ESLint 解釈の差**: プリセット `preset-env` の構文（例: クラス）と ESLint パーサの整合を取る。`@babel/eslint-parser` を使う案と **typescript 未使用** なら **Espree デフォルト + ecmaVersion 最新** でも可。jQuery+ES5/ES6 混在のため **@babel/eslint-parser 推奨**（Babel 設定と一貫）。
- **legacy な `var` / IIFE パターン**: 一括で `const` に置換しない; 初回は違反のうち **明確に機械的修正できるもの** のみ。残りはルール緩和または段階的 follow-up（ロードマップ上はフェーズ 3 以降で想定可）。

## Validation Architecture (Nyquist)

- **即時フィードバック**（各タスク後）: `yarn run lint`（プロジェクト根から実行可能な一枚コマンドに統一する）。
- **波末 / 受け入れ**: `RAILS_ENV=production bundle exec rails assets:precompile`（プロジェクト慣習に合わせ `bin/rails` に揃えてもよい; プラン内で 1 表記に固定）。
- **継続性**: コミット前に手動 or 既存の git hook が無いなら、ドキュメント上で「`yarn run lint` を PR 前に推奨」と明記（必須は ROADMAP の「lint が無違反または解消済み」に合わせる）。

---

## RESEARCH COMPLETE
