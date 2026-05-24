# Bookmarks

個人用のブックマーク・フィード・ToDo・カレンダーを一元管理する Rails アプリです。

## 機能

- **ブックマーク** — URL を保存し、ページタイトルを自動取得。フォルダによる階層管理に対応
- **フィード** — RSS/Atom フィードの購読と記事一覧表示
- **ToDo** — タスク管理
- **カレンダー** — 日本の祝日を考慮したカレンダー UI
- **認証** — Devise によるユーザー認証・2 要素認証（TOTP）・OmniAuth 連携
- **テーマ** — モダン・クラシック・シンプルの 3 テーマを提供。設定画面から切り替え可能（デフォルト: モダン）

## 技術スタック

| 層 | 採用技術 |
|---|---|
| 言語 | Ruby 3.4 / JavaScript (ES6, Sprockets) |
| フレームワーク | Rails 8.1 |
| DB | MySQL (`utf8mb4`) |
| フロントエンド | Sprockets + jQuery 4 + SCSS（SPA フレームワークなし） |
| Web サーバー | Puma |
| 認証 | Devise + devise-two-factor + OmniAuth |
| フィード解析 | Feedjira + Nokogiri |
| テスト | Minitest / Cucumber + Capybara + Selenium |

## セットアップ

### 必要条件

- Ruby 3.4（`.ruby-version` で固定）
- Node.js 22（`.node-version` で固定）
- MySQL
- Yarn

### インストール

```bash
bundle install
yarn install
bundle exec rake dad:setup
bundle exec rake dad:setup:test
```

### データベース

```bash
# 環境変数を設定してから実行
# MYSQL_HOST, MYSQL_PORT, MYSQL_USERNAME, MYSQL_PASSWORD

bundle exec rake dad:db:create
bin/rails db:reset
```

### サーバー起動

```bash
bin/rails s
```

## テスト

```bash
# Minitest（ユニット・結合テスト）
bin/rails test

# Cucumber（受け入れテスト）
bundle exec rake dad:test
```

## JavaScript / リンター

```bash
# 依存関係のインストール
yarn install

# リント実行
yarn run lint

# 自動修正
yarn run lint:fix

# フォーマット
yarn run format
```

ESLint 9（flat config）と Prettier を採用。設定は `eslint.config.mjs` / `.prettierrc`、規約は `.planning/codebase/CONVENTIONS.md` を参照。

## Docker

リポジトリルートに `Dockerfile.app` / `Dockerfile.base` / `Dockerfile.test` があります。CI は `Jenkinsfile` で管理されています。

## データベース構成

| 環境 | DB 名 |
|---|---|
| 開発 | `bookmarks_dev` |
| テスト | `bookmarks_test` |
| 本番 | `bookmarks_pro` |

接続は環境変数（`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`）で設定します。

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) | 初回セットアップ |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | 開発ワークフロー |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | アーキテクチャ概要 |
| [docs/API.md](docs/API.md) | 主要ルート一覧 |
| [docs/CONFIGURATION.md](docs/CONFIGURATION.md) | 環境変数・設定 |
| [docs/TESTING.md](docs/TESTING.md) | テスト（tri-suite） |
| [CONTRIBUTING.md](CONTRIBUTING.md) | コントリビューション |
| [CLAUDE.md](CLAUDE.md) | AI エージェント向けテスト方針 |
