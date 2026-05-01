---
phase: 14-locale-infrastructure
plan: 01
status: complete
wave: 1
completed: 2026-05-01
requirements:
  - I18N-01
  - I18N-03
threats_mitigated:
  - T-14-01
  - T-14-02
self_check: PASSED
---

# Plan 14-01 Summary — Locale Data Layer

## What Was Built

Locale infrastructure 永続化レイヤと boot-time I18n 制限を完成させた。

1. **Migration** `db/migrate/20260501020618_add_locale_to_preferences.rb`
   - `add_column :preferences, :locale, :string, null: true`
   - dev / test 両 DB に適用済み (`db/schema.rb` 更新確認)

2. **Model** `app/models/preference.rb`
   - 定数 `SUPPORTED_LOCALES = %w[ja en].freeze` を `FONT_SIZE_OPTIONS` 直後に追加
   - 検証 `validates :locale, inclusion: { in: SUPPORTED_LOCALES }, allow_nil: true` を `validates :font_size` 直後に追加
   - 既存の `FONT_SIZES` 検証パターンに完全一致

3. **Boot config** `config/application.rb`
   - `config.i18n.available_locales = %i[ja en]` を `default_locale = :ja` の直後に追加
   - インラインリテラル使用（Zeitwerk boot 順序の都合で `Preference::SUPPORTED_LOCALES` を直接参照しない）

4. **Test** `test/models/preference_test.rb`
   - `test_localeはsupported_localesのみ有効` を追加（TDD: RED → GREEN サイクル）
   - 'ja' / 'en' / nil OK、'fr' / 'zh' NG を検証

## Files Modified / Created

```
created: db/migrate/20260501020618_add_locale_to_preferences.rb
modified: app/models/preference.rb
modified: app/models/preference.rb
modified: config/application.rb
modified: db/schema.rb (auto-updated by migration)
modified: test/models/preference_test.rb
```

## Self-Check: PASSED

| Acceptance Criterion | Evidence |
|----------------------|----------|
| `SUPPORTED_LOCALES = %w[ja en].freeze` in preference.rb | Confirmed via grep |
| `validates :locale, inclusion:` line present | Confirmed via grep |
| Migration creates `locale` column | `bin/rails db:migrate` exit 0 |
| `db/schema.rb` contains `t.string "locale"` | Confirmed |
| `bin/rails test test/models/preference_test.rb` exits 0 | 3 runs, 16 assertions, 0 failures |
| `bin/rails runner 'puts I18n.available_locales.inspect'` outputs `[:ja, :en]` | Verified |
| `config/application.rb` does NOT reference `Preference::SUPPORTED_LOCALES` | Confirmed |

## Commits

```
8b0e6e2 feat(14-01): add locale column, SUPPORTED_LOCALES, and inclusion validation
5c68669 feat(14-01): restrict I18n.available_locales to [:ja, :en]
```

## Notes for Plan 14-02

- `Preference::SUPPORTED_LOCALES` はモデル定数として参照可能（Zeitwerk autoload 経由）。
- `I18n.with_locale` は :ja / :en 以外を渡すと `I18n::InvalidLocale` を上げる挙動が固まったので、Plan 14-02 の Localization concern は **必ず** `SUPPORTED_LOCALES.include?` チェックを `with_locale` 呼び出しの前に置くこと。
- `validates :locale` は既存 fixture (locale: nil) を壊さない（`allow_nil: true` のため）。

## key-files.created

- `db/migrate/20260501020618_add_locale_to_preferences.rb`
- (locale validation logic in app/models/preference.rb)
