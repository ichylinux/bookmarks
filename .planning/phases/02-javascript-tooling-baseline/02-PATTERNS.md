# Pattern map — Phase 2: JavaScript tooling baseline

## Files in scope (modify / 参照)

| File | Role | Nearest existing analog | Notes |
|------|------|------------------------|--------|
| `app/assets/javascripts/bookmarks.js` | jQuery イベント、Ajax | `app/assets/javascripts/todos.js` 等 | グローバル `$` / `jQuery`；IIFE なし |
| `app/assets/javascripts/application.js` | Sprockets manifest | 同 | `//= require_tree .` |
| `babel.config.js` | トランスパイル | — | ESLint パーサの `babelOptions.configFile` と整合させる |
| `package.json` | scripts / devDependencies | 現状ほぼ空 | `yarn` で追加 |
| `README.md` | コントリビュータ向け手順 | プレースホルダ | TOOL-02: `yarn run lint` 手順を明記 |

## Excerpt: manifest パターン

Sprockets は `//=` ディレクティブ; ESLint 対象は**ソース** `app/assets/javascripts/**/*.js`（コンパイル後 `public/assets` は ignore）。

## PATTERN MAPPING COMPLETE
