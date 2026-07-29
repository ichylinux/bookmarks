<!-- generated-by: gsd-doc-writer -->
# Getting Started

## Prerequisites

Before running the app, ensure these tools are installed at the versions below.

| Tool | Version | Source |
|------|---------|--------|
| Ruby | 3.4.9 | `.ruby-version` — use rbenv or asdf |
| Node.js | 22.22.2 | `.node-version` — use nvm or asdf |
| Yarn | not pinned in `package.json` (1.22.22 confirmed working) | installed via `npm install -g yarn` |
| MySQL | not pinned in the repo <!-- VERIFY: confirm minimum supported server version --> | running locally, default port 3306 |

MySQL must be running and reachable at `127.0.0.1:3306` (or override via environment variables — see [Configuration](CONFIGURATION.md)).

## Installation steps

1. Clone the repository:

   ```bash
   git clone https://github.com/ichylinux/bookmarks.git
   cd bookmarks
   ```

2. Install Ruby dependencies:

   ```bash
   bundle install
   ```

3. Install JavaScript dependencies:

   ```bash
   yarn install
   ```

4. Configure the MySQL connection (defaults match a local MySQL with the `bookmarks` user):

   ```bash
   export MYSQL_HOST=127.0.0.1
   export MYSQL_USERNAME=bookmarks
   export MYSQL_PASSWORD=bookmarks
   ```

   Create the `bookmarks` MySQL user if it does not exist:

   ```sql
   CREATE USER 'bookmarks'@'127.0.0.1' IDENTIFIED BY 'bookmarks';
   GRANT ALL PRIVILEGES ON `bookmarks_%`.* TO 'bookmarks'@'127.0.0.1';
   FLUSH PRIVILEGES;
   ```

5. Bootstrap the app and databases using the `daddy` gem rake tasks:

   ```bash
   bundle exec rake dad:setup
   bundle exec rake dad:setup:test
   bundle exec rake dad:db:create
   bin/rails db:reset
   ```

   - `dad:setup` — runs the `default` [itamae](https://github.com/itamae-kitchen/itamae) role (`config/itamae/roles/default.rb`), which installs the MySQL client system package and runs `bundle install`. May prompt for `sudo` to install OS packages.
   - `dad:setup:test` — same as `dad:setup`, plus installs the Selenium/headless Chrome driver needed by the Cucumber suite (`config/itamae/roles/test.rb`)
   - `dad:db:create` — creates `bookmarks_dev` and `bookmarks_test` databases per `config/database.yml`
   - `db:reset` — drops, creates, and seeds the development database

## First run

Start the Puma server:

```bash
bin/rails s
```

The app is available at `http://localhost:3000`. Register a new user account or sign in with configured OmniAuth providers.

## Common setup issues

**MySQL connection refused**

`Mysql2::Error: Can't connect to MySQL server` means MySQL is not running or the host/port is wrong.

- Start MySQL: `sudo systemctl start mysqld` (Linux) or `brew services start mysql` (macOS)
- Confirm the `MYSQL_HOST` and `MYSQL_PORT` environment variables match your setup

**MySQL authentication error**

`Mysql2::Error: Access denied for user 'bookmarks'@'127.0.0.1'` means the MySQL user or password is wrong.

- Verify the `MYSQL_USERNAME` and `MYSQL_PASSWORD` env vars are set correctly
- Re-run the SQL `GRANT` statement shown in the installation steps above

**Wrong Ruby version**

`Your Ruby version is X.Y.Z, but your Gemfile specified ~> 3.4.0` means the wrong Ruby is active.

- Run `rbenv install 3.4.9 && rbenv local 3.4.9`, then rerun `bundle install`
- Or with asdf: `asdf install ruby 3.4.9 && asdf local ruby 3.4.9`

**`dad:setup` task not found**

`Don't know how to build task 'dad:setup'` means `bundle exec` is missing or gems are not installed.

- Ensure you ran `bundle install` first
- Always use `bundle exec rake dad:setup` (not bare `rake`)

**Cucumber E2E test failures on first run**

The Cucumber suite (`bundle exec rake dad:test`) requires the test database to be set up. If `dad:setup:test` was not run, the suite will fail with database-related errors before any scenarios execute.

- Run `bundle exec rake dad:setup:test && bin/rails db:test:prepare`

## Next steps

- [Development guide](DEVELOPMENT.md) — day-to-day workflow, build commands, and code style
- [Testing guide](TESTING.md) — running Minitest and Cucumber, coverage requirements
- [Architecture](ARCHITECTURE.md) — how the application is structured
- [Configuration](CONFIGURATION.md) — all environment variables and config files
