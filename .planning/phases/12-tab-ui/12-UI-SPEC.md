---
phase: 12
slug: tab-ui
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-30
---

# Phase 12 — UI Design Contract（Tab UI）

> フロント段階の視覚・インタラクション契約。`gsd-ui-researcher` 作成、`gsd-ui-checker` 検証対象。
>
> **根拠:** `12-CONTEXT.md`（ロック決定）、`ROADMAP.md` Phase 12、`REQUIREMENTS.md` TAB-01〜03、`STATE.md`、`common.css.scss` / `_menu.html.erb` におけるシンプルテーマ既存スタイル。

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none（Rails サーバー描画、`components.json` なし） |
| Preset | not applicable |
| Component library | none（部分テンプレート + jQuery） |
| Icon library | none（本フェーズ） |
| Font | ブラウザ既定。本文ベースは `common.css.scss` の `body { font-size: 12px; }` に整合 |

---

## Spacing Scale

宣言値（原則 4 の倍数）:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | タブ行とコンテンツの最小隙間、ガジェット `div.title` 系と同系 |
| sm | 8px | コンパクトな内部余白 |
| md | 16px | パネル周りの標準余白 |
| lg | 24px | セクション間 |
| xl | 32px | （必要時）大きめのブロック間 |
| 2xl | 48px | ページレベル（本フェーズでは主に未使用） |
| 3xl | 64px | 同上 |

**例外（既存 UI との整合）:** シンプルテーマの `.header` / `.wrapper` は既に **横 10px** のマージン・パディングを使用している（`common.css.scss` の `.header { margin: 4px 10px 0 10px; }`、`themes/simple.css.scss` の `.wrapper`）。タブストリップは **同一の横 10px ライン**に揃え、ナビと視覚的に連続した帯に見えること。数値はレガシーだが本フェーズでは **「`.header` と横位置を揃える」ことを優先**し、10px を例外として許容する。

**ソース:** `12-CONTEXT.md` D-06、コード `common.css.scss`、`themes/simple.css.scss`。

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 12px | 400 | 1.5（本文ブロックに用いる場合） |
| Label（タブラベル・トップナビ相当） | 12px | 400（非アクティブ）、**700**（アクティブ推奨） | 行ボックス **20px**（`.header` の `height` / `line-height: 20px` に合わせ、`_menu` のクリックターゲットと同系） |
| Heading | 12px〜14px | 700 | 1.2（ノートパネル内のプレースホルダ見出しに限り使用可） |
| Display | 該当なし | — | — |

**ソース:** `common.css.scss` `body` / `.header`、ガジェット `div.title` の `font-weight: bold` パターン。

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant（60%） | `#FFFFFF` | ページ背景（`body`） |
| Secondary（30%） | `#EEEEEE` / `rgba(0, 0, 0, 0.2)` 系 | ドロップダウン・ガジェットタイトル帯など、既存の「薄い面」 |
| Accent（10%） | `#595757` または **アクティブタブ明示用の 1 要素**（下線・`border-bottom` 等） | **予約:** アクティブタブのインジケータ、`:focus-visible` のアウトライン。インタラクティブ全般をアクセントで塗りつぶさない |
| Destructive | （本フェーズではタブ UI に未使用） | 破壊的操作なし。将来 NOTE 削除などで導入時に別途契約 |

**Accent は次にのみ使う:** アクティブタブの境界線／下線、フォーカスリング。**使わない:** 非アクティブタブの背景全面、ホーム／ノートパネルの全面背景。

**ソース:** `common.css.scss`（`#EEEEEE`, `#595757`）、`welcome.css.scss` ガジェットタイトル背景。

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| タブラベル（確定文言） | **ホーム** / **ノート**（`REQUIREMENTS.md` の英語表記ではなく、`ROADMAP` / `12-CONTEXT.md` D-01 に従う） |
| Primary CTA | **本フェーズではなし**（保存ボタン等は Phase 13 `NOTE-01`） |
| Empty state heading | **ノート**パネルは Phase 13 までプレースホルダ可。使用する場合の例:**「ノート」**（見出し 1 行） |
| Empty state body | プレースホルダ 1 行まで可。例:**「ここにメモの一覧と入力欄が表示されます。」**（Phase 13 で `_note_gadget` に置換） |
| Error state | サーバー `NotesController` の `redirect_to ... alert:` メッセージをそのまま表示方針。タブは **`?tab=notes`** で **ノート**をアクティブにした状態で読み込む（ユーザーは入力文脈に留まる） |
| Destructive confirmation | 該当なし |

---

## フェーズ固有 — レイアウトとマークアップ

| 項目 | 契約 |
|------|------|
| 表示テーマ | **シンプルテーマのみ。** `favorite_theme == 'simple'` のときのみ、タブ用マークアップおよびノート用パネル DOM を出力 |
| 配置 | メインコンテンツ**直上**（`wrapper` 内、ウェルカム本体の前）。`_menu.html.erb` と同様の視覚階層（トップナビの延長として読める位置） |
| ホームパネル | 既存の **`div.portal` + gadgets** をラップまたは同一パネル内に配置（DOM は現行ポータルと実質同一） |
| ノートパネル | シンプル専用の **ラッパー 1 つ**（Phase 13 がマウントする安定した `id` またはクラス）。中身は空〜プレースホルダで可 |
| タブ操作子 | **`button type="button"`** のみ。`<a href="#">` / `javascript:` / ナビとの混同を招く単体 `link_to` を主トリガにしない |
| 非シンプル | **タブリンクもノートパネル markup も出力禁止**（ERB + 必要なら JS no-op の二段） |

**ソース:** `12-CONTEXT.md` D-05, D-06, D-08、ROADMAP SC4、`STATE.md`。

---

## フェーズ固有 — インタラクションと URL

| 項目 | 契約 |
|------|------|
| 初期表示 | `URLSearchParams` で `tab` を解釈。**`tab=notes` → ノートパネル表示**。**未指定・`tab=home`・その他の値 → ホーム** |
| クリック時 | jQuery 等で **該当パネルの show / hide**。**ページリロードなし** |
| URL 操作 | **クライアントのタブクリックでは `history.pushState` / `replaceState` およびアドレスバー更新をしない**（`12-CONTEXT.md` D-07）。`?tab=` は **サーバー redirect**（例: ノート保存後）でのみ付与 |
| POST 後 | `NotesController` は既に `root_path(tab: 'notes')`。**ロード時にノートタブがアクティブ**であること（TAB-03） |
| JS ガード | `body` に **`simple` クラスがない**環境では、タブ用スクリプトは **即 return**（`menu.js` のモダン／クラシック早期リターンと対称。正のガード `hasClass('simple')` 推奨） |
| 実装場所 | 新規 `notes.js` または同等のスクリプトを `application` から読み込み、**タブ用ロジックのみ**を担当（既存 `welcome/index` 内 portal sortable は温存） |

**ソース:** `12-CONTEXT.md` D-03, D-04, D-05, D-07、`STATE.md`。

---

## フェーズ固有 — スタイルの所在

| 項目 | 契約 |
|------|------|
| タブ関連 CSS | **`welcome.css.scss` 内の `.simple { ... }` ブロックのみ**に置く。**`common.css.scss` にタブ用ルールを追加しない** |
| ナビとの見た目 | `_menu.html.erb` の **横並びリストナビ**（`ul.navigation` / `inline-block` / 行高 20px）に視覚的に揃える。タブボタンは **ボタンのリセット**（境界・背景はナビリンクに準じたスタイルで統一） |
| モダン／クラシック | テーマ別 SCSS でタブを定義しない（マークアップ自体が無いため） |

**ソース:** ROADMAP SC5、`12-CONTEXT.md`、`STATE.md` Critical Pitfalls。

---

## アクセシビリティ（任意だが推奨）

`12-CONTEXT.md`「Claude's Discretion」に従い必須ではないが、低コストなら次を推奨:

- タブ列に `role="tablist"`、各 `button` に `role="tab"`、`aria-selected` をアクティブ状態で同期
- パネルに `role="tabpanel"` と `aria-labelledby`

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn / 第三者 UI レジストリ | なし | not required |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
