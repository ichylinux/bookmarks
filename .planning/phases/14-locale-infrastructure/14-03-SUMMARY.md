---
phase: 14-locale-infrastructure
plan: 03
status: complete
wave: 3
completed: 2026-05-01
requirements:
  - VERI18N-01
threats_mitigated:
  - T-14-06
  - T-14-07
self_check: PASSED
---

# Plan 14-03 Summary — VERI18N-01 Integration Tests

## What Was Built

`test/controllers/application_controller_test.rb` を新規作成し、VERI18N-01 が要求する 4 経路すべての回帰テストを Minitest 統合テストで自動化した。

各テストは:
1. `user.preference.update!(locale: ...)` で fixture state を毎回リセット（テスト独立）
2. `sign_in user` で Devise 認証
3. `get root_path` （+ optional `Accept-Language` ヘッダ）でアプリ層を経由した本番に近い経路を exercise
4. `assert_select 'html[lang=?]'` で実際にレンダリングされた `<html lang>` 属性を検証（I18N-04 evidence）

| # | テスト名 | locale 値 | Accept-Language | 期待 lang |
|---|---------|-----------|------------------|-----------|
| 1 | `test_保存済みlocaleがenのユーザは英語でレンダリングされる` | 'en' | (irrelevant) | en |
| 2 | `test_AcceptLanguageがenのリクエストは英語でレンダリングされる` | nil | `en-US,en;q=0.9,ja;q=0.8` | en |
| 3 | `test_無効なlocaleは無視されてデフォルトの日本語になる` | nil | `fr-FR,fr;q=0.9` | ja |
| 4 | `test_locale未設定かつAcceptLanguage未指定の場合はデフォルト日本語` | nil | (none) | ja |

## Files Modified / Created

```
created: test/controllers/application_controller_test.rb
```

## Self-Check: PASSED

| Acceptance Criterion | Evidence |
|----------------------|----------|
| `class ApplicationControllerTest < ActionDispatch::IntegrationTest` | Confirmed |
| Exactly 4 test methods | `grep -c 'def test_'` = 4 |
| `assert_select 'html[lang=?]', 'en'` exists | Confirmed (×2 — tests 1 & 2) |
| `assert_select 'html[lang=?]', 'ja'` exists | Confirmed (×2 — tests 3 & 4) |
| `headers: { 'Accept-Language' =>` present | Confirmed (×2 — tests 2 & 3) |
| Test file alone runs green | 4 runs, 16 assertions, 0 failures |
| Full suite green | 127 runs, 625 assertions, 0 failures |

## Commits

```
3f3b098 test(14-03): cover all 4 VERI18N-01 locale resolution paths
```

## Notes

- Tests use the canonical `user` helper (memoized `User.first` from `test/support/users.rb`); fixture user 1 has a persisted `Preference` row in `preferences.yml`.
- Devise `Test::IntegrationHelpers` is included into `ActionDispatch::IntegrationTest` in `test/test_helper.rb` line 18, so `sign_in user` works without any extra setup.
- Cucumber coverage is intentionally NOT added at this phase — UI strings remain Japanese-only until Phases 16/17, so the only browser-visible difference at Phase 14 is the `<html lang>` attribute, which is best validated by Minitest. Cucumber coverage is scheduled for Phase 18.

## key-files.created

- `test/controllers/application_controller_test.rb`
