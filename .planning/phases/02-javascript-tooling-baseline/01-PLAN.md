---
phase: 2
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - package.json
  - yarn.lock
  - eslint.config.mjs
  - .prettierignore
  - .prettierrc.json
  - app/assets/javascripts/**/*.js
autonomous: true
requirements_addressed: [TOOL-01]
---

# Plan 01 — ESLint / Prettier 基盤とクリーンな `lint`

<objective>
`yarn run lint` で `app/assets/javascripts` 全体を静的解析でき、 exit 0（違反ゼロ固定）に揃える。Babel 設定（`babel.config.js`）と矛盾しないパーサ設定にする。
</objective>

<threat_model>
| ID | 脅威 | 深刻度 | 緩和（本プラン） |
|----|------|--------|------------------|
| T-2-01 | 悪意ある npm パッケージ混入 | medium | 有名パッケージに限定し、`yarn.lock` をコミットし差分をレビュー可能にする |
| T-2-02 | リント設定誤りによる本番アセットの無言破壊 | low | リントはソースのみ; 最終ゲートは Plan 02 の `assets:precompile` |
</threat_model>

<must_haves>
- `package.json` に `lint` / `lint:fix` / `format` スクリプトが存在し `yarn run lint` が成功する
- `eslint.config.mjs` が `app/assets/javascripts/**/*.js` を対象にする
- 既存 JS の挙動を変えない（リント修正はスタイル・未使用等の機械的範囲に留める）
</must_haves>

<tasks>

<task type="auto">
  <name>Task 1: devDependencies を Yarn で追加</name>
  <files>package.json, yarn.lock</files>
  <read_first>package.json, yarn.lock, babel.config.js, .planning/phases/02-javascript-tooling-baseline/02-RESEARCH.md</read_first>
  <action>
    リポジトリルートで次を実行し、保存する:
    `yarn add -D eslint@^9.0.0 prettier@^3.0.0 @eslint/js@^9.0.0 eslint-config-prettier@^10.0.0 @babel/core@^7.0.0 @babel/eslint-parser@^7.0.0 globals@^15.0.0`
    `package.json` に `devDependencies` ブロックができていること。既存の `name` / `private` / `dependencies` は維持する。
  </action>
  <verify>sh -c 'grep -q eslint package.json && grep -q @babel/eslint-parser package.json'</verify>
  <acceptance_criteria>
    - `package.json` に文字列 `"eslint"` が含まれる
    - `package.json` に文字列 `"@babel/eslint-parser"` が含まれる
    - `yarn.lock` が更新されファイルが存在する
  </acceptance_criteria>
  <done>上記 acceptance_criteria を満たす</done>
</task>

<task type="auto">
  <name>Task 2: Prettier 設定と ignore</name>
  <files>.prettierrc.json, .prettierignore</files>
  <read_first>app/assets/javascripts/bookmarks.js</read_first>
  <action>
    ルートに `.prettierrc.json` を新規作成。内容は次の JSON を**そのまま**入れる:
    `{"semi": true, "singleQuote": true, "trailingComma": "es5"}`
    ルートに `.prettierignore` を新規作成。少なくとも次の行を含む（順不同可、1 行 1 パス）:
    `node_modules`
    `vendor`
    `public/assets`
    `tmp`
    `log`
    `coverage`
  </action>
  <verify>test -f .prettierrc.json && test -f .prettierignore</verify>
  <acceptance_criteria>
    - `.prettierrc.json` に `"singleQuote": true` が含まれる
    - `.prettierignore` に `node_modules` という行がある
  </acceptance_criteria>
  <done>上記ファイルがリポジトリに存在する</done>
</task>

<task type="auto">
  <name>Task 3: ESLint flat 設定（Babel パーサ + ブラウザ + jQuery）</name>
  <files>eslint.config.mjs</files>
  <read_first>babel.config.js, .planning/phases/02-javascript-tooling-baseline/02-RESEARCH.md</read_first>
  <action>
    ルートに `eslint.config.mjs` を新規作成。次の要件をすべて満たす ESM デフォルトエクスポート:
    - `@eslint/js` の `js.configs.recommended` を適用
    - `files: ['app/assets/javascripts/**/*.js']` のブロックで `@babel/eslint-parser` を `languageOptions.parser` に指定し、`parserOptions.babelOptions.configFile` を `'./babel.config.js'`（相対・ルート基準）に設定
    - `languageOptions.globals` に `globals` パッケージの `globals.browser` をスプレッドし、加えて `$` と `jQuery` を `'readonly'` で定義
    - `eslint-config-prettier` を最後に適用（推奨パターン: `...prettier` / `eslint-config-prettier` の flat 用エクスポートに従う）
    - `ignores` に少なくとも `node_modules/**`, `vendor/**`, `public/assets/**`, `tmp/**`, `log/**` を含める
  </action>
  <verify>test -f eslint.config.mjs</verify>
  <acceptance_criteria>
    - `eslint.config.mjs` に文字列 `app/assets/javascripts` が含まれる
    - `eslint.config.mjs` に文字列 `@babel/eslint-parser` が含まれる
    - `eslint.config.mjs` に文字列 `babel.config.js` が含まれる
  </acceptance_criteria>
  <done>設定ファイルがパース可能でルールが有効</done>
</task>

<task type="auto">
  <name>Task 4: package.json の scripts</name>
  <files>package.json</files>
  <read_first>package.json</read_first>
  <action>
    `package.json` のトップレベルに `scripts` オブジェクトを追加またはマージし、少なくとも次の 3 キーを**次の npm script 文字列どおり**（クォート含め推奨）設定する:
    - `lint`: `eslint \"app/assets/javascripts/**/*.js\"`
    - `lint:fix`: `eslint \"app/assets/javascripts/**/*.js\" --fix`
    - `format`: `prettier --write \"app/assets/javascripts/**/*.js\"`
  </action>
  <verify>node -e "const p=require('./package.json'); console.log(p.scripts.lint)"</verify>
  <acceptance_criteria>
    - `node -p "require('./package.json').scripts.lint"` の出力に `app/assets/javascripts` が含まれる
    - `node -p "require('./package.json').scripts.format"` の出力に `prettier --write` が含まれる
  </acceptance_criteria>
  <done>3 スクリプトが定義されている</done>
</task>

<task type="auto">
  <name>Task 5: 違反の解消（lint を exit 0 に）</name>
  <files>app/assets/javascripts/**/*.js</files>
  <read_first>eslint.config.mjs, app/assets/javascripts/application.js, app/assets/javascripts/bookmarks.js</read_first>
  <action>
    1) `yarn run lint:fix` を実行。2) 残る違反は、**挙動を変えない範囲**でソースを修正するか、当該行に限り eslint-disable-next-line を付与する（付与時はコメントに理由を 1 行で明記）。3) 最終的に `yarn run lint` が exit code 0 になるまで繰り返す。
  </action>
  <verify>yarn run lint</verify>
  <acceptance_criteria>
    - コマンド `yarn run lint` が終了コード 0
  </acceptance_criteria>
  <done>TOOL-01 の「チェック可能なベースライン」が緑</done>
</task>

</tasks>

<verification>
- [ ] `yarn run lint` が exit 0
- [ ] `node -e "import('./eslint.config.mjs')"` が例外を出さない（Node が ESM を解決できる環境であること）
</verification>

<success_criteria>
- TOOL-01 を満たす: ドキュメント済みコマンド（次プランで README に同じ文字列を載せる前提）で JS スタイルを検証できる
- 変更は `files_modified` に列挙した範囲に収まる
</success_criteria>
