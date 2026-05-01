---
phase: 15-language-preference
status: issues_found
severity: low_medium
reviewed: 2026-05-01
files_reviewed: 7
critical_count: 0
high_count: 0
medium_count: 1
low_count: 5
---

# Phase 15 Code Review

## Summary

Phase 15 のソースは仕様意図に対して安全かつ十分網羅的に実装・テストされている。
ブロッカーなし、マージ可。MEDIUM 1 件は将来の locale 関連属性追加時の保守性向上提案。

## Findings

### CRITICAL
(none)

### HIGH
(none)

### MEDIUM

**M1. `create` と `update` で locale 正規化ロジックが重複**
(`app/controllers/preferences_controller.rb:11-13`, `26-28`)

空文字→nil の変換が両アクションでコピペされている。Phase 17 以降で他の nullable
属性が増えると拡散するリスクあり。

推奨修正のいずれか:
1. private メソッドに抽出 (`normalize_preference_params!(attrs)`)
2. `Preference` モデル側で `before_validation { self.locale = locale.presence }` を定義し、
   コントローラからは正規化処理を完全に取り除く

実フォームは PATCH しか送らないので `create` は事実上デッドコード (Phase 15 起因の問題ではない)。

### LOW / STYLE

- **L1**: `respond_to?(:key?)` ガードは冗長 — `attrs[:preference_attributes]&.key?(:locale)` で十分
- **L2**: `LOCALE_OPTIONS` のラベルがモデル定数にハードコード（テストで意図的にロック済み、設計上の非対称性として記録）
- **L3**: `Preference#default_preference` で `locale` がデフォルト未設定 (仕様通り = nil で auto)
- **L4**: `options.fetch(:font_size, nil)` は `options[:font_size]` と等価（既存スタイル踏襲）
- **L5**: ビューの `fields_for` ブロック変数 `f` で外側 `f` をシャドウ（既存パターン）

## Positive observations

- **セキュリティ堅実**: SUPPORTED_LOCALES allowlist + strong params + current_user.id 引き直し +
  自動 HTML エスケープ
- **i18n キー対称性**: ja.yml と en.yml で完全対称
- **遅延 lookup の妥当性**: `preferences.index.*` namespace がテンプレートパスと整合
- **テスト品質**: 日本語メソッド名一貫性、selected 属性検証、html[lang=?] 検証、
  sign_out → sign_in roundtrip まで網羅

## Recommendation

Phase 15 はマージ可。M1 (controller 重複) は将来の locale 関連属性追加のタイミングで
リファクタリングを検討。
