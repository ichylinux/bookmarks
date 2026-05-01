---
phase: 15
phase_name: Language Preference
session_date: 2026-05-01
session_time: 11:25-11:45 JST
mode: discuss (default, all areas)
---

# Phase 15 Discussion Log

**Date:** 2026-05-01
**Mode:** Default (all 4 gray areas selected via `all`)
**Outcome:** CONTEXT.md captured 15 numbered decisions (D-01..D-15)

---

## Pre-discussion Setup

### Prior decisions carried forward (not re-asked)

From Phase 14 CONTEXT/SUMMARY/VERIFICATION:
- D-01 (locale on `preferences` table, not `users`)
- D-02 (nil first-class state, no backfill)
- D-03 (`SUPPORTED_LOCALES = %w[ja en]` constant as source of truth)
- D-04 (resolution pipeline whitelist double-defense)
- Localization concern using `around_action :set_locale`
- `<html lang>` bound to `I18n.locale`

From PROJECT.md:
- Per-user UI preferences aggregate on `Preference` model (D-01 in Phase 14)
- `user_id` never in strong params (security, server-side merge)
- Sprockets + jQuery stack, no new JS dependencies

### Pre-decided by Claude (Claude's discretion, no user input needed)

- Test layering: Minitest extension only, no Cucumber (Phase 14 deferred Cucumber to Phase 18 — continue)
- i18n key namespace: Rails standard lazy lookup + `activerecord.attributes.*`
- No DB migration (column already exists from Phase 14 migration `20260501020618_add_locale_to_preferences.rb`)

---

## Gray Areas Presented

```
1. 言語セレクタの形 (widget + label format)
2. 「ブラウザの設定に従う」(nil) 選択肢の取扱い
3. PREF-03 を満たすための翻訳範囲（Phase 16/17 との境界）
4. 保存後の遷移先（PREF-03 evidence の組み立て方）
```

User selected: **all 4** areas via `all` reply.

---

## Area 1: 言語セレクタの形

**Question presented:** widget (select / radio / select+i18n) and label format (native / translated)

**Options offered:**
- (a) OK — `<select>` + native ラベル `{ '日本語' => 'ja', 'English' => 'en' }`, view 直書き
- (b) `Preference::LOCALE_OPTIONS` 定数として model に置く形を locked にする
- (c) 別案

**User selected:** (b)

**Decision (D-01, D-02, D-03):** `Preference::LOCALE_OPTIONS` 定数として model に追加。`<select>` + native ラベル + `include_blank: false`。`FONT_SIZE_OPTIONS` パターン継承。

**Rationale captured:**
- 既存 `theme` select / `font_size` select との完全同形を保つ
- Native ラベルでロックアウト耐性
- 定数化で「サポート値の列挙」と「表示文言」が同じ場所にまとまる（FONT_SIZE_OPTIONS と同じ責務分担）

---

## Area 2: nil 選択肢の取扱い

**Question 1 presented:** nil をどう扱うか（隠す / 露出する）

**Options offered:**
- (a) OK — nil を UI に出さない、ja / en の二択
- (b) 第 3 の選択肢として `(ブラウザの設定に従う)` を露出
- (c) 隠すが初期表示挙動を Context で lock

**User selected:** (c)

**Claude's proposed lock (initial response):** 「locale=nil の場合 select は `日本語` 選択済み、保存ボタンで nil → 'ja' に upgrade」

**User pushback:** "nil のまま保存できるようにして、初期表示の挙動を継続することを可能にしたい。そうすることで設定をずっとデフォルトのまま（モダンで日本語で、、）で変更することに関心がないユーザに対してアプリの提案するデフォルト体験を提供し続けることが可能になる。"

**Re-framed gray area:** 「nil を first-class state として保持しつつ、UI では何と表記するか」

**Question 2 presented:** Path A (3 値 select、`おまかせ / Auto` ラベル) で lock するか

**Options offered:**
- (a) OK — Path A、`おまかせ / Auto` ラベル
- (b) 方向性 OK だがラベル別案
- (c) 別アプローチ

**User selected:** (b) with override `自動`

**Decision (D-04, D-05, D-06):**
- `LOCALE_OPTIONS = { '自動' => nil, '日本語' => 'ja', 'English' => 'en' }.freeze`
- nil は first-class state として保持
- 空文字 → nil 正規化を controller の strong params 通過後に追加
- locale=nil ユーザがフォームを開く → `自動` selected → 何も変更しなければ nil のまま

**Rationale captured:**
- ユーザの UX 哲学「設定変更に無関心なユーザにアプリの提案するデフォルト体験を提供し続ける」を反映
- Phase 14 D-02（nil = first-class state, no backfill）と完全整合
- ロックアウト耐性は `日本語` / `English` の native 表記で確保（`自動` を読めなくても他 2 つを読めれば戻れる）
- en 表示時の混在（`自動` が日本語のまま）を許容

**Alternatives explicitly rejected:**
- `prompt:` 経由の未選択状態（複雑、原則矛盾）
- locale だけ独立 disclosure / 別ページ（UI 複雑度に対する利益小）
- `おまかせ / Auto` の bilingual label（ユーザが単純な `自動` を希望）

---

## Area 3: PREF-03 を満たす翻訳範囲

**Question presented:** Phase 15 の翻訳スコープをどこまで広げるか（PREF-03 strict vs Phase 16/17 のスコープ侵食）

**Options offered:**
- (a) OK — `/preferences` ページ単体の全面翻訳（layout / menu / 他 surface は Phase 16/17 に残す）
- (b) 方針 OK だが追加キー粒度をさらに詰めたい
- (c) スコープ縮小（locale セクションのみ、PREF-03 strict には満たさず）
- (d) スコープ拡大（layout / menu まで Phase 15 に取り込む）
- (e) もう少し練りたい

**User selected:** (a)

**Decision (D-07, D-08, D-09):** `/preferences` ページ単体の全面翻訳。Phase 16/17/18 のスコープ境界は厳守:
- Phase 16 (Core Shell): layout / menu / drawer / flash messages — Phase 15 は触らない
- Phase 17 (Feature Surface): bookmarks / notes / todos / feeds / calendars views — Phase 15 は触らない
- Phase 18 (Auth): Devise pages 本体の翻訳 — Phase 15 では二段階認証関連の link from `/preferences` 範囲のみ

**Rationale captured:**
- PREF-03 の文面 strict 解釈を満たす
- Phase 16/17 のスコープを侵食しない（フェーズ境界 = ROADMAP の不可侵原則）
- 作業量現実的（en.yml ~15 keys, ja.yml ~5 keys, view 修正 3 行）
- 既存 i18n 機構（`activerecord.attributes.*`）を活用、新規 helper 不要

**Specific keys to add captured in D-08.**

**Open question for Plan:** font_size 表示部の翻訳実装方針（D-09 で 3 案提示、(a) 推奨だが Plan で最終決定）。

---

## Area 4: 保存後の遷移先

**Question presented:** `redirect_to root_path` を維持 / 変更 / 条件分岐するか

**Options offered:**
- (a) OK — 一律 `redirect_to preferences_path` に変更（既存テスト 3 件も更新）
- (b) `root_path` 維持、PREF-03 を loose 解釈
- (c) locale 変更時のみ条件分岐
- (d) もう少し練りたい

**User selected:** (a)

**Decision (D-11, D-12):**
- `PreferencesController#update` の最後の `redirect_to root_path` を `redirect_to preferences_path` に変更
- locale 変更時に限らず一律変更
- 既存テスト 3 件の expected URL を `/preferences` に更新

**Rationale captured:**
- PREF-03 strict 解釈を最も明確に満たす（保存後即座に新 locale でフォーム再描画）
- 一律変更が最小複雑度（条件分岐なし）
- Form 慣習（保存後リソース自身に戻る）と整合
- Existing user の認知コスト増加は小

**Alternatives explicitly rejected:**
- 条件分岐（D-13 で test cases 増、controller 太る）
- render（PRG パターン違反、再 submit リスク）

---

## Summary

| Area | User choice | Decision IDs | Sub-discussion needed? |
|------|-------------|--------------|------------------------|
| 1 | (b) 定数 lock | D-01, D-02, D-03 | No |
| 2 | (c) → reframed → (b: 自動) | D-04, D-05, D-06 | Yes (1 round) |
| 3 | (a) 全面翻訳 | D-07, D-08, D-09 | No |
| 4 | (a) 一律変更 | D-11, D-12 | No |

Total decisions captured: 15 (D-01..D-15, including 4 from Claude's discretion)
Deferred ideas captured: 6
Reviewed todos: 3

---

## Notable Patterns

- **User's UX philosophy emerged in Area 2:** "設定変更に関心がないユーザにアプリの提案するデフォルト体験を提供し続ける" — first-class nil state preservation. This is consistent with Phase 14 D-02 and informs how all preference defaults should be designed.
- **User defers test layering and i18n namespace to Claude consistently:** Phase 14 同様、Cucumber 不採用 / Minitest only / Rails 標準 lazy lookup を Claude 裁量領域として明示せず受容。Pattern 確立。
- **User accepts mixed-language UI (`自動` in en context):** UI consistency をテキスト混在より優先しない、ロックアウト耐性さえ保てれば mixed OK という pragmatic stance。
- **User chose strictest interpretation for both PREF-03 evidence (Area 3 + 4):** translation scope を `/preferences` 全面 + redirect 先変更で「保存→即新 locale ページ」の最強組合せを採用。

---

*Discussion log captured: 2026-05-01 11:45 JST*
