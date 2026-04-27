# Phase 3: Modernize application scripts - Discussion Log

> **監査用。** plan / research / execute への入力は `03-CONTEXT.md` を用いる。

**Date:** 2026-04-27  
**Phase:** 3 - Modernize application scripts  
**Areas discussed (selected):** `var` / const-let 方針; jQuery と `this` / コールバック形

---

## グレー領域の選択

| Option | Description | Selected |
|--------|-------------|----------|
| 領域 1 | `var` 除去のやり方と例外 | ✓ |
| 領域 2 | jQuery / `this` と `function` vs アロー | ✓ |
| 領域 3 | グローバル/名前空間 | |
| 領域 4 | precompile 検証の頻度 | |

**User's choice:** 領域 `1, 2` のみ

---

## 領域 1 — `var` と `const`/`let`

| Topic | 取った方針 |
|-------|------------|
| ゴール | `no-var` 違反ゼロ（`eslint:recommended`）、`var` 不使用 |
| 例外 | 原則なし; やむを得ない場合は `eslint-disable-next-line` + 理由1行 |
| ループ | `let` / `const` 適用、再代入なしは `const` 優先 |

**Notes:** インタラクティブの細問答は未実施。STYL-01 準拠の推奨案を CONTEXT の D-01〜D-03 に固定。

---

## 領域 2 — jQuery と `this`

| Topic | 取った方針 |
|-------|------------|
| `this` が要素として意味を持つハンドラ | 従来の `function` |
| `$(document).ready` | 外枠で `this` 不要ならアロー可 |
| データだけのコールバック | アロー可 |
| 文面 | CONVENTIONS 等に短く追記（D-07） |

**Notes:** STYL-02 準拠の推奨案を CONTEXT の D-04〜D-07 に固定。

---

## Claude's Discretion

- 実装の順序・式レベルで挙動不変の整理はプラン/実装者裁量

## Deferred Ideas

- 領域 3・4 は未討議。`03-CONTEXT.md` deferred に記載
