---
phase: 15-language-preference
plan: 03
status: complete
completed: 2026-05-01
requirements:
  - PREF-01
  - PREF-02
  - PREF-03
key-files:
  modified:
    - app/views/preferences/index.html.erb
    - test/support/preferences.rb
    - test/controllers/preferences_controller_test.rb
    - config/locales/ja.yml
    - config/locales/en.yml
  created: []
commits:
  - 54bf597 feat(15-03) i18nify /preferences view + add locale select row
  - 9a5bbdb fix(15-03) nest preferences.* keys under preferences.index for lazy lookup (Plan 15-02 を補修)
  - 0d84781 test(15-03) add 8 integration tests proving PREF-01..03
---

# 15-03 — View i18n + locale selector + integration tests

## Self-Check: PASSED

`bin/rails test test/controllers/preferences_controller_test.rb` — 14 runs, 113 assertions, 0 failures, 0 errors。

## What was built

Phase 15 の最終ユーザ可視成果物。`/preferences` ページの view を i18n 化し、
言語セレクタを追加し、PREF-01..03 を 8 件の統合テストで証明。

### Changes

#### `app/views/preferences/index.html.erb`

- `f.label :font_size, '文字サイズ'` の override を削除 (i18n 解決に依存)。
- theme select の hardcode hash を `{ t('.theme_options.modern') => 'modern', ... }` に置換。
- font_size select を `Preference::FONT_SIZES.map { |size| [t(".font_size_options.#{size}"), size] }` で生成。Plan 15-01 で削除した `FONT_SIZE_OPTIONS` Hash の機能的代替。
- locale select row を theme と font_size の間に挿入:
  - `f.select :locale, Preference::LOCALE_OPTIONS, { include_blank: false, selected: @user.preference.locale }`
  - Native ラベル固定 (D-02): `自動 / 日本語 / English`
- `f.submit '保存'` を `f.submit t('.submit')` に置換。

#### `test/support/preferences.rb`

- `preference_params` helper に `locale: options.fetch(:locale, nil)` を追加。
- 既存テストへの影響なし (locale 未指定時は nil で permission を通過、controller の
  `presence` 正規化で nil 維持)。

#### `test/controllers/preferences_controller_test.rb`

新規 8 tests を追加:

| Test | Requirement | 検証内容 |
|------|-------------|---------|
| `test_言語セレクタを表示する` | PREF-01 | locale select の DOM 構造、3 options |
| `test_localeをjaに更新できる` | PREF-01 + PREF-02 | patch → DB 書込み |
| `test_localeをenに更新できる` | PREF-01 + PREF-02 | patch → DB 書込み |
| `test_localeをnilに戻せる` | D-04..D-06 | nil first-class、'' → nil 正規化 |
| `test_保存後preferences_pathにリダイレクトされる` | D-11 | redirect 先 |
| `test_設定画面が日本語ロケールで日本語表示される` | PREF-03 | html[lang=ja] + ja labels |
| `test_設定画面が英語ロケールで英語表示される` | PREF-03 | html[lang=en] + en labels + native locale labels |
| `test_localeはサインアウト後も保持される` | PREF-02 | sign_out → sign_in roundtrip |

#### `config/locales/{ja,en}.yml` (Plan 15-02 補修)

`preferences.{theme_options,font_size_options,submit}` を `preferences.index.*`
にネストし直し。Rails の lazy lookup `t('.foo')` は template path
(`app/views/preferences/index.html.erb` → `preferences.index.foo`) に解決される
ため、Plan 15-02 で `preferences.foo` 直下に置いていたキーが
`translation missing: ja.preferences.index.theme_options.modern` を引き起こした。

ja↔en の symmetry は維持 (`preferences.index` 名前空間で 7 keys)。

### Verification

- `bin/rails test test/controllers/preferences_controller_test.rb` — **14 runs, 113 assertions, 0 failures, 0 errors**
- `grep -c "f.select :locale" app/views/preferences/index.html.erb` → 1
- `grep -c "t('.submit')" app/views/preferences/index.html.erb` → 1
- `grep -c "Preference::FONT_SIZES.map" app/views/preferences/index.html.erb` → 1
- `grep -c "FONT_SIZE_OPTIONS" app/views/preferences/index.html.erb` → 0
- `grep -c '^  def test_' test/controllers/preferences_controller_test.rb` → 14

### Threats addressed

- T-15-10 (locale 値改竄) — model `validates :locale, inclusion:` で Phase 14 で confirmed
- T-15-11 (i18n キー欠損) — `test_設定画面が英語ロケールで英語表示される` で実値検証 → translation missing が出たら即 fail
- T-15-12 (i18n lookup 性能) — accept (memoize 済み)
- T-15-13 (Repudiation) — accept (個人アプリ、updated_at で追跡可能)
- T-15-14 (CSRF/Spoofing) — accept (Devise + form_with の標準 token)

## Deviations

**Plan 15-02 の補修**: `preferences.theme_options/font_size_options/submit` を
Plan 15-02 で `preferences.foo` 直下に追加したが、view の lazy lookup が
template-path-based であるため `preferences.index.foo` に変更が必要だった。
Plan 15-03 の commit でまとめて修正。

Plan 15-02 を retroactively edit するのではなく Plan 15-03 の `fix(15-03):` commit で
追記する形を取り、commit 履歴で原因と修正経路が辿れるようにした。

## What this enables

- v1.4 の Phase 16 (Core Shell) — preferences ページの翻訳パターンを確立した上で、
  layout/menu の `t` 化に進める。`activerecord.attributes.user.name` のような
  Phase 15 で en 化した既存キーは Phase 16 で再利用される。
- v1.4 の Phase 17 (Feature Surface) — Phase 17 で各 gadget surface に i18n を適用する際、
  `preferences.index.*` のような template-path lazy lookup convention を踏襲する。
- VERI18N-01 の自動 test 経路 — Phase 14 の root_path 経由に加え、Phase 15 の
  `preferences_path` 経由でも `<html lang>` 切替が確認された。

## Notes for future phases

- **Lazy lookup template path 慣習**: Phase 16/17 で view を `t` 化する際、`t('.foo')` は
  view path に対応する namespace を使う (`app/views/X/Y.html.erb` → `X.Y.foo`)。
  Phase 15 の Plan 15-02 のミスを繰り返さないよう、yml キーの階層は view path に
  完全一致させる必要がある。
- **Native ラベル原則**: locale select の `自動 / 日本語 / English` は en 表示時も
  native のまま (D-02)。同様の「言語 / 通貨 / 国名」など UI 一般慣習に従う場合、
  Phase 16/17 で再利用可能なパターン。
