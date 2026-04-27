---
phase: 2
plan: "02"
type: execute
wave: 2
depends_on: ["01"]
files_modified:
  - README.md
  - .planning/codebase/CONVENTIONS.md
autonomous: true
requirements_addressed: [TOOL-02]
---

# Plan 02 — ドキュメント、本番アセット検証

<objective>
新規コントリビュータが `README.md` だけで `yarn run lint`（および任意で `format`）の再現手順を把握できる（TOOL-02）。`RAILS_ENV=production` の `bin/rails assets:precompile` が成功し、ロードマーク成功基準 3 を満たす。
</objective>

<threat_model>
| ID | 脅威 | 深刻度 | 緩和 |
|----|------|--------|------|
| T-2-01 | 誤手順のコピーで CI を壊す | low | 手順のコマンド文字列を Plan 01 の `package.json` scripts と同一にする（README にそのままコピー） |
| T-2-02 | 本番プリコンパイル未検証で壊れしたデプロイ | medium | 本プランで precompile を必須 verify に含める |
</threat_model>

<must_haves>
- `README.md` に文字列 `yarn run lint` が少なくとも 1 回含まれる
- 同じ文脈に Node/Yarn 前提（例: リポジトリルート、事前に `yarn install` 等）が書かれている
- `RAILS_ENV=production bin/rails assets:precompile` が exit 0
</must_haves>

<tasks>

<task type="auto">
  <name>Task 1: README に JavaScript ツール手順を追記</name>
  <files>README.md</files>
  <read_first>README.md, package.json</read_first>
  <action>
    `README.md` に「## JavaScript / リンター（開発時）」レベル相当の見出し行を 1 つ追加する（`##` で始まる 1 行）。その見出しの直後の本文に、次の**コマンド文字列を**含む行をそれぞれ含む（`package.json` の scripts と**同一の引用符・パス**）:
    - `yarn install`（未導入者向け）
    - `yarn run lint`
    任意行で `yarn run lint:fix` および `yarn run format` を併記してよい。
  </action>
  <verify>grep -n "yarn run lint" README.md</verify>
  <acceptance_criteria>
    - `README.md` に `yarn run lint` という部分文字列が含まれる
    - `README.md` に `##` で始まる行が 1 行以上ある（上記手順用セクション用）
  </acceptance_criteria>
  <done>TOOL-02 の主成果が README に反映されている</done>
</task>

<task type="auto">
  <name>Task 2: CONVENTIONS に JS 節の参照を 1 ブロック追記</name>
  <files>.planning/codebase/CONVENTIONS.md</files>
  <read_first>.planning/codebase/CONVENTIONS.md</read_first>
  <action>
    `## Overview` セクションの直後（文書冒頭付近）に、次の 3 行のブロックを**このまま**新規挿入する:
    空行
    `**JavaScript (Sprockets):** リンター/フォーマッタの手順はルート `README.md` の JavaScript セクションを正とする。`
    空行
  </action>
  <verify>grep -F "JavaScript (Sprockets)" .planning/codebase/CONVENTIONS.md</verify>
  <acceptance_criteria>
    - `.planning/codebase/CONVENTIONS.md` に `JavaScript (Sprockets):` という部分文字列が含まれる
  </acceptance_criteria>
  <done>計画外ドキュメント参照が一元化され README と矛盾しにくい</done>
</task>

<task type="auto">
  <name>Task 3: 本番アセットプリコンパイル</name>
  <files>（実行のみ・成果物の変更は通常なし）</files>
  <read_first>config/application.rb, package.json, eslint.config.mjs</read_first>
  <action>
    リポジトリルートで、データベースを要求しない形で本番相当プリコンパイルを実行する。標準: `RAILS_ENV=production bin/rails assets:precompile`
    失敗した場合: エラーメッセージに従い、**設定ファイル（例: 資格情報のないダミー ENV）の追加が本フェーズ範囲**なら行う; 要 DB 接続のマイグレーションが必要なら、その旨を `.planning/phases/02-javascript-tooling-baseline/02-PLAN.md` の `<verification>` にコメント付きで記録し、可能な `SECRET_KEY_BASE` ダミー等で通す。
  </action>
  <verify>RAILS_ENV=production bin/rails assets:precompile</verify>
  <acceptance_criteria>
    - コマンド `RAILS_ENV=production bin/rails assets:precompile` が終了コード 0
  </acceptance_criteria>
  <done>ロードマーク成功基準 3（アセット/Babel 整合）の確認</done>
</task>

</tasks>

<verification>
- [ ] `README.md` に `yarn run lint` がある
- [ ] `RAILS_ENV=production bin/rails assets:precompile` が成功
- [ ] TOOL-02 の意図（同じ手順の再現性）を満たす
</verification>

<success_criteria>
- 新規参画者が README のみで JS チェック手順に辿り着ける
- 本番相当アセットがビルド可能
</success_criteria>
