# Phase 3: Modernize application scripts - Context

**Gathered:** 2026-04-27  
**Status:** Ready for planning

<domain>
## Phase Boundary

`app/assets/javascripts/` の第一者スクリプトを、Phase 2 で固定した **ESLint / Prettier ベースライン**（`yarn run lint` クリーン）に合わせてモダン化する。範囲は **STYL-01 / STYL-02**（およびプラン内で触れる **STYL-03 / STYL-04**）に従い、**ユーザー向け挙動・UJS・Sprockets 結線は変えない**。新アセット方式や新規グローバル API の導入は含めない。

**ユーザーが今回のディスカッションで扱うのは上記のうち領域 1・2**（`var` 方針、jQuery / `this` と関数形のルール）。領域 3・4（グローバル方針の細部、precompile の頻度）は未議論—プラン/リサーチでロードマップ・要件に照らして補完する。

</domain>

<decisions>
## Implementation Decisions

### STYL-01 — `const` / `let` と `var`（領域 1）

- **D-01:** 第一者 `app/assets/javascripts/**/*.js` では **`var` を使わない**ことをゴールとする。ESLint では `@eslint/js` の `js.configs.recommended` に含まれる **`no-var` 違反をゼロ**にする（既存 `eslint.config.mjs` 前提のまま運用）
- **D-02:** 例外的に `var` のまま残す必要がある場合は **その行直前**に `// eslint-disable-next-line no-var` と、**1 行の理由**を書く。本フェーズでは原則発生させない方針（発生したら要レビュー）
- **D-03:** ループ変数は **`for (let ... of/in)` または従来の `for` で `let`**。再代入のない束縛は `const` を優先

### STYL-02 — イベント/コールバックと jQuery `this`（領域 2）

- **D-04:** jQuery がコールバックの **`this` を要素/DOM として束ねる**箇所は **`function` 宣言/式**を使う（例: `$(el).on('click', function () { $(this) ... })`、`collection.each(function () { ... })`）
- **D-05:** 外枠の `$(document).ready(function () { ... })` は、**そのブロック内で jQuery 由来の `this` を使わない**限り、**アロー関数**にしてよい
- **D-06:** 純粋にデータだけ扱い、**`this` を使わない**コールバック（例: `$.ajax(...).done((data) => { ... })`、配列回の短いコールバック）では **アロー関数**を許容する
- **D-07:** 上記 D-04〜D-06 の要約（短い1ブロック）を、Phase 3 の作業の一環として **`.planning/codebase/CONVENTIONS.md` またはリポジトリ上の同趣旨の追記**に反映する（STYL-02 の「ルール文面の固定」）

### Claude's Discretion

- ファイル単位のリファクタ順、セマンティクス上安全な `const` 選び、軽微な式の整理（挙動同一の範囲）
- 領域 3・4（グローバル方針の境界、precompile 検証の区切り）の具体タスク割り—要件とプラン難易度に合わせてプラン/リサーチで補完

</decisions>

<canonical_refs>
## Canonical References

**下流（plan / research / execute）は実装前に次を参照すること。**

### 要件・ロードマップ

- `.planning/REQUIREMENTS.md` — STYL-01, STYL-02, STYL-03, STYL-04
- `.planning/ROADMAP.md` — Phase 3 のゴールと成功基準
- `.planning/PROJECT.md` — スタック制約（Sprockets, jQuery）

### ツールとビルド

- `eslint.config.mjs` — 推奨 + Prettier; `app/assets/javascripts/**/*.js`
- `babel.config.js` — プリコンパイル整合（変更時は STYL-04）
- `README.md` — JavaScript/リンター手順（Phase 2 で固定したコマンド）

### 慣習

- `.planning/codebase/CONVENTIONS.md` — 追記先（D-07）。Overview の README 指針と整合

### 前フェーズの成果物

- `.planning/phases/02-javascript-tooling-baseline/01-SUMMARY.md` — lint 基盤
- `.planning/phases/02-javascript-tooling-baseline/02-SUMMARY.md` — README / precompile

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- 既存の **jQuery ベース**の gadgets/feeds/todos 等; Phase 2 で **`yarn run lint` 通過済み**の 7 ファイル前後
- `eslint.config.mjs` + `@babel/eslint-parser` + `babel.config.js` — ルール追加時は `no-var` を維持しつつ、必要なら `parserOptions` 維持

### Established Patterns

- Sprockets: `//= require` マニフェスト (`application.js`); グローバルは主に jQuery/ActionCable
- 多く `$(document).ready` と `.on` / `$.get` パターン

### Integration Points

- 変更は `app/assets/javascripts/` に限定; 本番は `assets:precompile`（Phase 2 と同様の検証を継続）

</code_context>

<specifics>
## Specific Ideas

- ユーザーはディスカッションで **領域 1・2 だけ**を指定。上記 D-01〜D-07 は、STYL-01/02 と整合する**推奨案**に基づき確定。細部の調整は `03-CONTEXT.md` 編集で可能

</specifics>

<deferred>
## Deferred Ideas

- 領域 3: 新規 `window.*` 禁止の細部、既存パターンの表現統一（STYL-03）— **プラン/実装段階**で本 CONTEXT と突き合わせ
- 領域 4: `assets:precompile` をプラン毎に何回回すか— **次プラン**で明文化

### Reviewed Todos (not folded)

- なし

</deferred>

---

*Phase: 03-modernize-application-scripts*  
*Context gathered: 2026-04-27*
