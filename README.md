<!-- generated-by: gsd-doc-writer -->
# Bookmarks

A personal bookmarks, feed reader, to-do, and calendar management app built with Rails.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- **Bookmarks** — Save URLs with auto-fetched page titles; organize into hierarchical folders
- **Feeds** — Subscribe to RSS/Atom feeds and browse articles
- **To-do** — Task management
- **Calendar** — Calendar UI with Japanese public holiday support
- **Authentication** — Devise with two-factor authentication (TOTP) and OmniAuth (Google, X, Facebook)
- **Themes** — Modern, Classic, and Simple themes switchable from the preferences page

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.4 / JavaScript (ES6, Sprockets) |
| Framework | Rails 8.1 |
| Database | MySQL (utf8mb4) |
| Frontend | Sprockets + jQuery 4 + SCSS |
| Web server | Puma |
| Auth | Devise + devise-two-factor + OmniAuth |
| Feed parsing | Feedjira + Nokogiri |
| Tests | Minitest / Cucumber + Capybara + Selenium |

## Prerequisites

- Ruby 3.4.9 (pinned via `.ruby-version`)
- Node.js 22.22.2 (pinned via `.node-version`)
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

bundle exec rake dad:setup
bundle exec rake dad:setup:test
bundle exec rake dad:db:create
bin/rails db:reset
```

## Quick Start

```bash
bin/rails s
```

The app runs at `http://localhost:3000`.

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

## JavaScript and Linting

```bash
yarn run lint        # Run ESLint
yarn run lint:fix    # Auto-fix lint errors
yarn run format      # Format with Prettier
```

ESLint 9 (flat config) with Prettier. Configuration: `eslint.config.mjs`.

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.
