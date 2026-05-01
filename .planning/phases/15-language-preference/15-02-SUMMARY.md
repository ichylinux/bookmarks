---
phase: 15-language-preference
plan: 02
status: complete
completed: 2026-05-01
requirements:
  - PREF-01
  - PREF-03
key-files:
  modified:
    - config/locales/ja.yml
    - config/locales/en.yml
  created: []
commits:
  - deb4e93 feat(15-02) ja.yml — add Phase 15 i18n keys
  - 228b705 feat(15-02) en.yml — rebuild as Phase 15 scope mirror of ja.yml
---

# 15-02 — i18n catalogs (ja.yml + en.yml)

## Self-Check: PASSED

## What was built

Phase 15 で `/preferences` ページを全面翻訳するための i18n キー群を ja/en 両カタログに追加。

### Changes

#### `config/locales/ja.yml` (+14 lines)

`activerecord.attributes.preference` ブロックに 2 キー挿入 (アルファベット順):
- `font_size: 文字サイズ` (view の override 削除を支える)
- `locale: 言語` (Plan 15-03 で追加する `f.label :locale` を i18n 解決)

末尾に新規 namespace `preferences:` を追加 (lazy lookup 用):
- `theme_options.{modern,classic,simple}` = `モダン / クラシック / シンプル`
- `font_size_options.{large,medium,small}` = `大 / 中 / 小`
- `submit: 保存`

#### `config/locales/en.yml` (boilerplate + Hello world を完全置換)

ja.yml の Phase 15 スコープを完全ミラーした構造で再構築:
- `activerecord.attributes.preference` 全 7 キーの英訳
- `activerecord.attributes.user.name = 'Username'`
- `messages.confirm_delete` 英訳 (`%{name}` 補間維持)
- `two_factor.*` 17 キーの英訳 (Phase 15 から実質 link されるのは 4 キーだが、
  fallback で ja の値が混在するのを防ぐため全キーを en 化)
- `preferences.theme_options/font_size_options/submit` 英訳 7 キー

D-07 に従い、Phase 17 スコープの `bookmark/calendar/feed/todo` 名前空間は en.yml に
追加していない (Phase 17 で別途対応)。

### Verification

- `ruby -ryaml -e 'YAML.load_file(...)'` 両 YAML valid
- `bin/rails runner` で `I18n.t` lookup を ja/en 両方で実値確認
- ja↔en の `activerecord.attributes.preference` キー集合が symmetric (7=7)
- ja↔en の `two_factor` キー集合が symmetric (17=17)
- ja↔en の `preferences` キー集合が symmetric (3=3)

### Threats addressed

- T-15-06 (YAML 改竄) — accept (git 管理 + Devise 認証境界)
- T-15-07 (en.yml に ja 文字列混在) — mitigate (Plan 15-03 の view 統合 test で実値検証)
- T-15-08 (YAML 構文エラーで boot 失敗) — mitigate (`YAML.load_file` + `bin/rails runner`)
- T-15-09 (`%{name}` 補間で XSS) — accept (view の auto-escape、Phase 15 で user 入力補間なし)

## Deviations

なし。Plan 通り。

## What unblocks

Plan 15-03 (view 修正 + 統合 test) が以下を `t` 経由で解決可能になる:
- `f.label :locale` → 言語/Language
- `f.label :font_size` (override 削除) → 文字サイズ/Font size
- `t('.theme_options.*')` → モダン/Modern など
- `t('.font_size_options.*')` → 大/Large など
- `t('.submit')` → 保存/Save

## Notes for downstream phases

- Phase 16 で Core Shell 翻訳が必要になった際、`messages.confirm_delete` などの
  既存キーは Phase 15 で en.yml に追加済み。
- Phase 17 で各 gadget surface (bookmarks/calendars/feeds/todos) を翻訳する際、
  対応する `activerecord.attributes.{bookmark,calendar,feed,todo}` を en.yml に
  追加する必要がある (現時点では未追加)。
- Phase 18 で Devise pages を翻訳する際、`two_factor.*` は既に Phase 15 で en 化
  済みなので touch 不要。Devise 自身のキー (`devise.*`) のみ追加すれば良い。
