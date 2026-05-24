# Getting Started

<!-- gsd-generated: docs-update 2026-05-25 -->

## Prerequisites

- Ruby 3.4 (see `.ruby-version`)
- Node.js 22 (see `.node-version`)
- MySQL
- Yarn

## Quick start

```bash
# Clone and install
bundle install
yarn install

# Bootstrap DB and app (dad gem tasks)
export MYSQL_HOST=127.0.0.1
export MYSQL_USERNAME=bookmarks
export MYSQL_PASSWORD=bookmarks

bundle exec rake dad:setup
bundle exec rake dad:setup:test
bundle exec rake dad:db:create
bin/rails db:reset   # development DB

# Run server
bin/rails s
```

Open http://localhost:3000. Register a user or sign in with configured OmniAuth providers.

## OAuth setup (optional)

Set provider credentials before using social login:

```bash
export GOOGLE_CLIENT_ID=...
export GOOGLE_CLIENT_SECRET=...
export TWITTER2_CLIENT_ID=...
export TWITTER2_CLIENT_SECRET=...
export FACEBOOK_APP_ID=...
export FACEBOOK_APP_SECRET=...
```

See [Configuration](CONFIGURATION.md) for the full list.

## Verify installation

```bash
yarn run lint
bin/rails test
bundle exec rake dad:test
```

All three should exit 0. See [Testing](TESTING.md).

## Next steps

- [Development guide](DEVELOPMENT.md) — day-to-day workflow
- [Architecture](ARCHITECTURE.md) — how the app is structured
- [API routes](API.md) — HTTP surface
