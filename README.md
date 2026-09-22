<!-- generated-by: gsd-doc-writer -->
# Bookmarks

A personal dashboard for bookmarks, feeds, to-dos, notes, calendar, and social timelines, built with Rails.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- **Bookmarks** — Save URLs with auto-fetched page titles; organize into hierarchical folders
- **Feeds** — Subscribe to RSS/Atom feeds and browse articles
- **To-do** — Task management with highlight and done toggles
- **Notes** — Optional notes pane on the dashboard (enabled from preferences)
- **Calendar** — Calendar UI with Japanese public holiday support
- **Social gadgets** — Mastodon and X (Twitter) timeline previews on the dashboard
- **Reading history** — Feed, X, and Mastodon gadget links are marked visited on click; optional paginated history at `/feed_article_histories` (enable from preferences)
- **Authentication** — Devise with two-factor authentication (TOTP) and OmniAuth (Google, X, Facebook, Mastodon)
- **Themes** — Modern, Classic, and Simple themes switchable from the preferences page

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.4 / JavaScript (ES6, Sprockets) |
| Framework | Rails 8.1 |
| Database | MySQL (utf8mb4) |
| Frontend | Sprockets + jQuery 1.12.4 + SCSS |
| Web server | Puma |
| Auth | Devise + devise-two-factor + OmniAuth |
| Feed parsing | Feedjira + Nokogiri |
| Tests | Minitest / Cucumber + Capybara + Selenium |

## Prerequisites

- Ruby 3.4.10 (pinned via `.ruby-version`)
- Node.js 22.23.1 (pinned via `.node-version`)
- MySQL
- Yarn

## Installation

```bash
git clone https://github.com/ichylinux/bookmarks.git
cd bookmarks
bundle install
yarn install
```

Set up databases:

```bash
# Configure connection via environment variables
# MYSQL_HOST, MYSQL_PORT, MYSQL_USERNAME, MYSQL_PASSWORD
# Defaults: 127.0.0.1:3306, user/password bookmarks

bundle exec rake dad:setup
bundle exec rake dad:setup:test
bundle exec rake dad:db:create
bin/rails db:reset
```

Full first-time setup (MySQL user, env vars, common failures) is in [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).

## Quick Start

1. Start the Puma server:

   ```bash
   bin/rails s
   ```

2. Open `http://localhost:3000` (override the port with `PORT`).

3. Register a user or sign in with a configured OmniAuth provider.

## Usage examples

After signing in, the dashboard at `/` shows gadget columns (bookmarks, todos, calendar, feeds, and optional Mastodon/X widgets).

**Add a bookmark**

1. Open the bookmarks gadget (or `/bookmarks`).
2. Enter a URL and use **Fetch from URL** to fill the page title.
3. Save. The bookmark appears in the dashboard gadget.

**Subscribe to a feed**

1. Open `/feeds` and add an RSS/Atom URL (title can be fetched the same way).
2. Return to `/`. The feed gadget lists recent articles.

**View reading history**

1. Open `/preferences` and enable **Show reading history** (`use_feed_article_histories`).
2. Click articles in feed, X, or Mastodon gadgets — links gain a visited style and are recorded with title and source.
3. Open **Reading history** from the header or nav (`/feed_article_histories`) to revisit past articles.

**Switch theme**

1. Open `/preferences`.
2. Choose Modern, Classic, or Simple and save.
3. Reload `/` — layout and chrome follow the selected theme.

## Testing

Run the full quality gate (lint + Minitest + Cucumber):

```bash
yarn run lint && bin/rails test && bundle exec rake dad:test
```

Run suites individually:

```bash
yarn run lint               # ESLint
bin/rails test              # Minitest (unit + integration)
bundle exec rake dad:test   # Cucumber E2E (spawns server automatically; do not use bundle exec cucumber directly)
```

Scoped runs (single file, line, or feature) are documented in [docs/TESTING.md](docs/TESTING.md).

## JavaScript and Linting

```bash
yarn run lint        # Run ESLint
yarn run lint:fix    # Auto-fix lint errors
```

## Database Configuration

| Environment | Database |
|---|---|
| Development | `bookmarks_dev` |
| Test | `bookmarks_test` |
| Production | `bookmarks_pro` |

Connection is configured via environment variables: `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`.

## Docker

The repository includes `Dockerfile.app`, `Dockerfile.base`, and `Dockerfile.test`. CI is managed via `Jenkinsfile`.

## Documentation

| Document | Contents |
|---|---|
| [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) | First-time setup |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Development workflow |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture overview |
| [docs/API.md](docs/API.md) | Route reference |
| [docs/CONFIGURATION.md](docs/CONFIGURATION.md) | Environment variables and settings |
| [docs/TESTING.md](docs/TESTING.md) | Testing guide (tri-suite) |
| [SECURITY.md](SECURITY.md) | Security policy and reporting |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.
