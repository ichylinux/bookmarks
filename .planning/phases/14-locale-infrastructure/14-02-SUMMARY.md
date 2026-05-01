---
phase: 14-locale-infrastructure
plan: 02
status: complete
wave: 2
completed: 2026-05-01
requirements:
  - I18N-02
  - I18N-03
  - I18N-04
threats_mitigated:
  - T-14-01
  - T-14-02
  - T-14-03
  - T-14-04
  - T-14-05
self_check: PASSED
---

# Plan 14-02 Summary — Localization Concern + Wiring

## What Was Built

Locale resolution パイプライン本体と各リクエスト境界での適用配線を完成させた。

1. **`app/controllers/concerns/localization.rb` (新規)**
   - `extend ActiveSupport::Concern` + `included do around_action :set_locale end`
   - **`set_locale(&block)`** — `I18n.with_locale(resolved_locale, &block)` で thread-local locale を atomic に save / restore（Puma スレッド再利用への locale bleed を完全防止）
   - **`resolved_locale`** — `[saved_locale, accept_language_match]` を順に検査し `Preference::SUPPORTED_LOCALES.include?(candidate.to_s)` を通った最初の候補を `:sym` で返す。マッチなしは `I18n.default_locale` (= `:ja`)
   - **`saved_locale`** — `user_signed_in?` でない場合は `nil`、`current_user.preference&.locale` を返す（safe navigation）
   - **`accept_language_match`** + **`parse_accept_language`** — q-value 順ソート + 先頭 2 文字抽出 + ホワイトリスト検査 + `rescue; nil`（malformed input は黙って `nil` フォールスルー）

2. **`app/controllers/application_controller.rb` (修正)**
   - `include Localization` をクラス本体 1 行目（`protect_from_forgery` より前）に追加
   - 順序が肝心: `around_action :set_locale` が `authenticate_user!` より先に登録されるため、Devise の認証失敗フラッシュも正しい locale で翻訳される

3. **`app/views/layouts/application.html.erb` (修正)**
   - `<html>` → `<html lang="<%= I18n.locale %>">`（I18n.locale は Symbol、ERB の `<%= %>` が `.to_s` を呼ぶので `lang="ja"` / `lang="en"` がレンダリングされる）

## Files Modified / Created

```
created:  app/controllers/concerns/localization.rb
modified: app/controllers/application_controller.rb
modified: app/views/layouts/application.html.erb
```

## Self-Check: PASSED

| Acceptance Criterion | Evidence |
|----------------------|----------|
| concern exists & has `extend ActiveSupport::Concern` | Confirmed |
| `around_action :set_locale` (NOT `before_action`) | `grep -c 'around_action' = 1`, `before_action :set_locale = 0` |
| `I18n.with_locale(resolved_locale, &block)` present | Confirmed |
| `Preference::SUPPORTED_LOCALES.include?` in resolved_locale & parse_accept_language | Confirmed (2 occurrences) |
| `rescue` returning `nil` in parse_accept_language | Confirmed |
| No `params[:locale]` in concern | `grep params\[:locale\]` returns 0 lines |
| `Localization.private_instance_methods(false).sort` returns 5 expected methods | Verified `[:accept_language_match, :parse_accept_language, :resolved_locale, :saved_locale, :set_locale]` |
| `ApplicationController.ancestors.include?(Localization)` | `true` |
| `<html lang="<%= I18n.locale %>">` in layout | Confirmed |
| Full Minitest suite | 123 runs, 609 assertions, 0 failures, 0 errors |

## Commits

```
2142a93 feat(14-02): add Localization concern with thread-safe locale resolution
9562bdf feat(14-02): wire Localization into ApplicationController and bind html lang
```

## Notes for Plan 14-03

- ApplicationController が `around_action :set_locale` を全リクエストに適用済み。
- 既存テストは `lang` 属性を見ていないため非破壊だが、テストが `assert_select 'html[lang=?]'` で属性を検証する道は開いた。
- Plan 14-03 では `user.preference.update!(locale: 'en')` でセーブ済み locale 経路を、`headers: { 'Accept-Language' => '...' }` で Accept-Language 経路を、それぞれ独立に exercise 可能。

## key-files.created

- `app/controllers/concerns/localization.rb`
