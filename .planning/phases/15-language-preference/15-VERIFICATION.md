---
phase: 15-language-preference
status: passed
verified: 2026-05-01
verifier: gsd-verifier
must_haves_passed: 25
must_haves_total: 25
requirements_verified:
  - PREF-01
  - PREF-02
  - PREF-03
---

# Phase 15 Verification Report

## Status: PASSED

## Goal Achievement Summary

Phase 15 のゴール（「サインイン済みユーザが /preferences から日本語/英語を選択し、その選択がセッションを跨いで永続する」）は達成されている。`Preference::LOCALE_OPTIONS` 定数・`PreferencesController` の `:locale` permit と空文字 → nil 正規化・`/preferences` ビューの言語セレクタと i18n 化された全ラベル、ja.yml/en.yml の対称キー集合、そして PREF-01..03 を網羅する 8 件の統合テスト（既存 6 件と合わせて 14 件、113 アサーション）がすべて green。要求された 3 ファイル合計 21 runs / 145 assertions / 0 failures / 0 errors を確認した。

## Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | A signed-in user can select Japanese or English from /preferences | PASSED | `test_言語セレクタを表示する` が `select[name='user[preference_attributes][locale]']` に value=`""/ja/en` の 3 option を assert（`test/controllers/preferences_controller_test.rb` L90-101）+ `app/views/preferences/index.html.erb` L19-21 で `f.select :locale, Preference::LOCALE_OPTIONS, ...` |
| 2 | After saving, the selected language controls the next rendered page | PASSED | `test_localeをjaに更新できる` / `test_localeをenに更新できる` で patch → DB 永続化を検証（L103-127）。`test_設定画面が{日本語\|英語}ロケールで{日本語\|英語}表示される` で保存後の `<html lang>` と全ラベルが切り替わることを検証（L153-184）。`PreferencesController#update` が `preferences_path` に redirect（L35）するため次のレンダリングが新ロケールに従う |
| 3 | The selected language persists across sign-out/sign-in/refresh | PASSED | `test_localeはサインアウト後も保持される` が patch → reload → `sign_out user` → `sign_in user` → GET preferences_path で `<html lang=en>` と `option[selected]=en` を検証（L186-205）。永続化先は DB (`preferences.locale`) のみで Cookie/session には保存しない（Phase 14 `Localization` concern が毎リクエストで DB を参照） |
| 4 | The preferences page itself renders in the newly selected language after the change | PASSED | `test_設定画面が日本語ロケールで日本語表示される` が `th` に `テーマ/言語/文字サイズ`、`option` に `モダン/大`、submit に `保存` を assert。`test_設定画面が英語ロケールで英語表示される` が同位置に `Theme/Language/Font size`、`Modern/Large`、`Save` を assert。さらに locale select の native ラベル `自動/日本語/English` が en 表示時も維持されることを assert |

## Requirements Traceability

| Req | Source | Verified by | Status |
|-----|--------|-------------|--------|
| PREF-01 | preferences view (`app/views/preferences/index.html.erb` L18-21) | `test_言語セレクタを表示する` + `test_localeをjaに更新できる` + `test_localeをenに更新できる` + `test_localeをnilに戻せる` | PASSED |
| PREF-02 | DB roundtrip (`preferences.locale` column, `Localization` concern from Phase 14) | `test_localeはサインアウト後も保持される` | PASSED |
| PREF-03 | i18n full page (`config/locales/{ja,en}.yml` + `app/views/preferences/index.html.erb`) | `test_設定画面が日本語ロケールで日本語表示される` + `test_設定画面が英語ロケールで英語表示される` | PASSED |

## Plan must_haves Cross-Reference

### Plan 15-01

| must_have | actual | status |
|-----------|--------|--------|
| `Preference::LOCALE_OPTIONS` exists and equals `{ '自動' => nil, '日本語' => 'ja', 'English' => 'en' }` | `app/models/preference.rb` L12-16 で完全一致、`.freeze` 付与 | PASSED |
| `PreferencesController` permits `user[preference_attributes][locale]` | `app/controllers/preferences_controller.rb` L41-46 の permit 配列に `:locale` 含む | PASSED |
| Empty string locale normalized to nil before save | L11-13 (`#create`) および L26-28 (`#update`) の `presence` 正規化、`test_localeをnilに戻せる` で実証 | PASSED |
| `#update` redirects to `preferences_path` | L35 で `redirect_to preferences_path`、`test_保存後preferences_pathにリダイレクトされる` で実証 | PASSED |
| `Preference::FONT_SIZE_OPTIONS` Hash 削除済み | `grep -c FONT_SIZE_OPTIONS app/models/preference.rb` → 0 | PASSED |
| `Preference::FONT_SIZES` 配列保持 | L5-9 で配列定数として保持、`test_文字サイズ...` 系 3 tests が green | PASSED |
| Artifact: `app/models/preference.rb` contains `LOCALE_OPTIONS` | 確認済み | PASSED |
| Artifact: `app/controllers/preferences_controller.rb` contains `preferences_path` (× 2) | `grep -c 'redirect_to preferences_path'` → 2 | PASSED |
| Artifact: `test_更新` redirect path 期待値更新 | L20 `assert_equal '/preferences', path` | PASSED |
| key_link: `LOCALE_OPTIONS\\s*=\\s*\\{` pattern | L12 で hit | PASSED |
| key_link: strong params `:locale` | L44 で hit | PASSED |
| key_link: `redirect_to\\s+preferences_path` | L20, L35 の 2 箇所で hit | PASSED |

### Plan 15-02

| must_have | actual | status |
|-----------|--------|--------|
| ja.yml `activerecord.attributes.preference.locale = '言語'` | `config/locales/ja.yml` L16 | PASSED |
| ja.yml `activerecord.attributes.preference.font_size = '文字サイズ'` | L15 | PASSED |
| ja.yml `preferences.theme_options.{modern,classic,simple}` keys | L51-54（`preferences.index.theme_options.*` に nest 化、Plan 15-03 で補修済み） | PASSED |
| ja.yml `preferences.font_size_options.{large,medium,small}` keys | L55-58（同上、`preferences.index` 配下） | PASSED |
| ja.yml `preferences.submit = '保存'` | L59（`preferences.index.submit`） | PASSED |
| en.yml mirrors ja.yml structure for `activerecord.attributes.{user.name, preference.*}` | `config/locales/en.yml` L4-13、preference 7 keys + user.name | PASSED |
| en.yml contains all `two_factor.*` keys with English values | L18-35、ja と同 17 keys（`section_title`..`invalid_code`） | PASSED |
| en.yml `preferences.theme_options.{modern,classic,simple} = Modern/Classic/Simple` | L39-42（`preferences.index.theme_options.*`） | PASSED |
| en.yml `preferences.font_size_options.{large,medium,small} = Large/Medium/Small` | L43-46 | PASSED |
| en.yml `preferences.submit = 'Save'` | L47 | PASSED |
| en.yml `messages.confirm_delete` mirrors ja with `%{name}` | L15-16 | PASSED |
| Artifact: ja.yml contains `preferences:` | L49 で hit | PASSED |
| Artifact: en.yml contains `activerecord:` | L2 で hit | PASSED |

> Note: Plan 15-02 のキーは元の plan で `preferences.*` 直下に配置されていたが、view の lazy lookup `t('.foo')` が template path（`preferences/index`）に解決される仕様のため、Plan 15-03 commit で `preferences.index.*` に nest 化された（15-03-SUMMARY.md「Deviations」に記載）。最終的なキー構造は ja/en で対称、機能要件は満たされている。

### Plan 15-03

| must_have | actual | status |
|-----------|--------|--------|
| /preferences に locale row + 3 options (`自動/日本語/English`) | `app/views/preferences/index.html.erb` L18-21、`test_言語セレクタを表示する` で実証 | PASSED |
| Saving locale=ja persists `'ja'` and html lang is ja | `test_localeをjaに更新できる` + `test_設定画面が日本語ロケールで日本語表示される` (`assert_select 'html[lang=?]', 'ja'`) | PASSED |
| Saving locale=en persists `'en'` and html lang is en | `test_localeをenに更新できる` + `test_設定画面が英語ロケールで英語表示される` (`assert_select 'html[lang=?]', 'en'`) | PASSED |
| Saving locale='' persists nil | `test_localeをnilに戻せる` で `assert_nil user.preference.reload.locale` | PASSED |
| Saving any preference field redirects to /preferences with new locale rendering | `test_保存後preferences_pathにリダイレクトされる` + `test_設定画面が...ロケールで...表示される` の組合せ | PASSED |
| /preferences renders fully in Japanese when locale='ja' | `test_設定画面が日本語ロケールで日本語表示される` で `テーマ/言語/文字サイズ/モダン/大/保存` を assert | PASSED |
| /preferences renders fully in English when locale='en' | `test_設定画面が英語ロケールで英語表示される` で `Theme/Language/Font size/Modern/Large/Save` を assert | PASSED |
| Locale persists across sign_out → sign_in | `test_localeはサインアウト後も保持される` で sign_out → sign_in → `<html lang=en>` + `option[selected]=en` を assert | PASSED |
| Artifact: view contains `user[preference_attributes][locale]` | L20 の f.select が emit する name 属性、test で assert | PASSED |
| Artifact: `test/support/preferences.rb` contains `locale: options.fetch(:locale, nil)` | `test/support/preferences.rb` L7 | PASSED |
| Artifact: 8 new integration tests covering PREF-01..03 | `test/controllers/preferences_controller_test.rb` に 8 件追加（既存 6 + 新規 8 = 14） | PASSED |
| key_link: `f\\.select :locale, Preference::LOCALE_OPTIONS` | view L20 で hit | PASSED |
| key_link: `t\\(['\"]\\.(theme_options\|font_size_options\|submit)` | view L15, L24, L59 で hit | PASSED |
| key_link: `assert_select 'html\\[lang=\\?\\]'` | test L159, L174, L201 で hit | PASSED |

## Test State

`bin/rails test test/controllers/preferences_controller_test.rb test/controllers/application_controller_test.rb test/models/preference_test.rb`:

```
21 runs, 145 assertions, 0 failures, 0 errors, 0 skips
```

内訳:
- `PreferencesControllerTest` — 14 tests (既存 6 + Phase 15 新規 8)、113 assertions
- `ApplicationControllerTest` — 4 tests (Phase 14 で追加した locale resolution 経路)
- `PreferenceTest` — 3 tests (locale inclusion validation 含む)

すべて green、回帰なし。

## Gaps

なし。Phase 15 の 4 success criteria、PREF-01/02/03 の 3 要求、各 Plan の must_haves はすべて満たされている。

## Human Verification

なし。Phase 15 の挙動はすべて自動統合テストで網羅されている（DB roundtrip、html[lang] 切替、native ラベル維持、sign_out/sign_in 永続化、空文字 → nil 正規化、redirect 先）。手動 UAT が必要な領域は存在しない。
