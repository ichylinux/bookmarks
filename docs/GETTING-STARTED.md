<!-- generated-by: gsd-doc-writer -->
# Getting Started

## Prerequisites

Before running the app, ensure these tools are installed at the versions below.

| Tool | Version | Source |
|------|---------|--------|
| Ruby | 3.4.10 | `.ruby-version` — use rbenv or asdf |
| Node.js | 22.23.1 | `.node-version` — use nvm or asdf |
| Yarn | Yarn Classic 1.x (lockfile v1; not pinned in `package.json`; 1.22.22 confirmed working) | installed via `npm install -g yarn` |
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

   Alternatively, put the same values in a `.env` file in the project root. `dotenv-rails` loads `.env` in development and test (there is no `.env.example`).

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

   - `dad:setup` — runs the `default` [itamae](https://github.com/itamae-kitchen/itamae) role (`config/itamae/roles/default.rb`), which includes the `db` and `app` roles: MySQL client, Graphviz, and `bundle install`. May prompt for `sudo` to install OS packages.
   - `dad:setup:test` — runs the `test` role (`config/itamae/roles/test.rb`): MySQL client, `bundle install`, and the Selenium/headless Chrome driver needed by the Cucumber suite (Selenium is skipped when `CI=jenkins`)
   - `dad:db:create` — as MySQL root (`MYSQL_ROOT`, default `root`; prompts for a password unless `MYSQL_ALLOW_EMPTY_PASSWORD` is set), creates the `bookmarks` user at `'bookmarks'@'%'` and the databases in `config/database.yml` (`bookmarks_dev`, `bookmarks_test`, and `bookmarks_pro` unless `RAILS_ENV` limits the run)
   - `db:reset` — drops, creates, schema-loads, and seeds the development database

## First run

Start the Puma server:

```bash
bin/rails s
```

The app is available at `http://localhost:3000` (override the port with `PORT`). Register a new user account or sign in with configured OmniAuth providers.

## Common setup issues

**MySQL connection refused**

`Mysql2::Error: Can't connect to MySQL server` means MySQL is not running or the host/port is wrong.

- Start MySQL: `sudo systemctl start mysqld` (Linux) or `brew services start mysql` (macOS)
- Confirm the `MYSQL_HOST` and `MYSQL_PORT` environment variables match your setup

**MySQL authentication error**

`Mysql2::Error: Access denied for user 'bookmarks'@'127.0.0.1'` means the MySQL user or password is wrong.

- Verify the `MYSQL_USERNAME` and `MYSQL_PASSWORD` env vars are set correctly
- Re-run the SQL `GRANT` statement shown in the installation steps above

**`dad:db:create` root access denied**

`dad:db:create` connects as MySQL root (`MYSQL_ROOT`, default `root`) and prompts for a password.

- Run the task as a user that can authenticate as that MySQL root account
- Set `MYSQL_ALLOW_EMPTY_PASSWORD=1` only if the local root account has no password

**Wrong Ruby version**

`Your Ruby version is X.Y.Z, but your Gemfile specified ~> 3.4.0` means the wrong Ruby is active.

- Run `rbenv install 3.4.10 && rbenv local 3.4.10`, then rerun `bundle install`
- Or with asdf: `asdf install ruby 3.4.10 && asdf local ruby 3.4.10`

**`dad:setup` task not found**

`Don't know how to build task 'dad:setup'` means `bundle exec` is missing or gems are not installed.

- Ensure you ran `bundle install` first
- Always use `bundle exec rake dad:setup` (not bare `rake`)

**Cucumber E2E test failures on first run**

The Cucumber suite (`bundle exec rake dad:test`) requires the test database to be set up. `dad:setup:test` runs `config/itamae/roles/test.rb` (MySQL client, `bundle install`, Selenium unless `CI=jenkins`) and does not create or prepare the test database; database setup is `dad:db:create` / `bin/rails db:test:prepare` (`dad:test` already depends on `db:test:prepare` via closer).

- Run `bundle exec rake dad:setup:test && bin/rails db:test:prepare`

## Next steps

- [Development guide](DEVELOPMENT.md) — day-to-day workflow, build commands, and code style
- [Testing guide](TESTING.md) — running Minitest and Cucumber, coverage requirements
- [Architecture](ARCHITECTURE.md) — how the application is structured
- [Configuration](CONFIGURATION.md) — all environment variables and config files
