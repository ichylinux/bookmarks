---
phase: 15-language-preference
plan: 01
status: complete
completed: 2026-05-01
requirements:
  - PREF-01
  - PREF-02
  - PREF-03
key-files:
  modified:
    - app/models/preference.rb
    - app/controllers/preferences_controller.rb
    - test/controllers/preferences_controller_test.rb
  created: []
commits:
  - 125d4f9 feat(15-01) Preference model — add LOCALE_OPTIONS, drop FONT_SIZE_OPTIONS Hash
  - ff7bf65 feat(15-01) PreferencesController — :locale permit, blank-to-nil, preferences_path redirect
  - 8054bba test(15-01) expect /preferences redirect path
---

# 15-01 — Backend wiring (Preference + PreferencesController)

## Self-Check: PASSED (within plan scope)

## What was built

Phase 15 のバックエンド層を実装。Plan 15-03 の view と Plan 15-02 の i18n が
依拠する model 定数とコントローラ挙動を確定。

### Changes

1. **`app/models/preference.rb`** — `LOCALE_OPTIONS` Hash 定数を `SUPPORTED_LOCALES`
   の直後に追加 (`{ '自動' => nil, '日本語' => 'ja', 'English' => 'en' }.freeze`)。
   `FONT_SIZE_OPTIONS` Hash 定数を削除 (Plan 15-03 で view が `FONT_SIZES` 配列を
   `t` 経由で hash に組む方式へ変わるため重複)。`FONT_SIZE_LARGE/MEDIUM/SMALL`
   定数および `FONT_SIZES` 配列は保持 (`welcome_helper#font_size_class` が参照)。

2. **`app/controllers/preferences_controller.rb`** —
   - `user_params` の `preference_attributes` permit 配列に `:locale` 追加。
   - `#update` および `#create` 両方で空文字 → nil 正規化を `presence` で実装
     (`<option value="">自動</option>` 経由の `locale=""` を nil 化)。
   - redirect 先を `root_path` から `preferences_path` に一律変更 (D-11)。
   - `key?` ガードで `preference_attributes` 自体が無いリクエストでも安全。

3. **`test/controllers/preferences_controller_test.rb`** —
   `test_更新` の `follow_redirect!` 後 `path` 期待値を `'/'` から `'/preferences'`
   へ更新 (D-12)。他 5 件は path assertion を持たないため変更不要。

### Verification

- `bin/rails test test/models/preference_test.rb` — 3 runs, 0 failures
- `bin/rails runner` で `LOCALE_OPTIONS` 定数の中身が期待通り
- `Preference.const_defined?(:FONT_SIZE_OPTIONS)` が `false`
- `bin/rails test ...test_open_links_in_new_tabを保存する` — 1 runs, 0 failures
- `bin/rails test ...test_文字サイズを保存する` — 1 runs, 0 failures
- `grep -c 'redirect_to preferences_path' app/controllers/preferences_controller.rb` → 2

### Intermediate state note

この plan の commit 完了時点で、`app/views/preferences/index.html.erb` line 20 が
まだ削除済みの `Preference::FONT_SIZE_OPTIONS` を参照しているため、view を
レンダリングする 4 件のテスト (`test_更新`, `test_設定画面に文字サイズ選択肢を表示する`,
`test_文字サイズのbodyクラスを描画する`, `test_文字サイズ未設定ならbodyクラスはmediumにフォールバックする`)
は **意図された中間状態** で失敗する。Plan 15-03 Task 1 (view i18n 化、
`FONT_SIZES.map { |size| [t(...), size] }` への移行) で復旧する。

Wave 1 の Plan 15-02 (i18n catalog) は view に触らないため、Wave 1 完了時点でも
この中間状態は継続する。Wave 2 の Plan 15-03 完了で全 suite green に戻る。

## Deviations

なし。Plan 通り。

## What unblocks

- Plan 15-03 の view 修正 — `Preference::LOCALE_OPTIONS` 定数を `f.select :locale` に
  渡せる。
- Plan 15-03 の統合テスト — `assert_redirected_to preferences_path` が controller の
  新挙動と一致する。

## Threats addressed

T-15-01 (Tampering: form locale field) — strong params で permit 制御。Mitigate.
T-15-02 (Tampering: empty string to DB) — controller で `presence` 正規化、model
inclusion validation が二重防御。Mitigate.
T-15-03 (Tampering: invalid locale) — model `validates :locale, inclusion:` 既存。Mitigate.
