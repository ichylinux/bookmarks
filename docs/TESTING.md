<!-- generated-by: gsd-doc-writer -->
# Testing

## Test framework and setup

The project runs three test suites. Jenkins runs the full Minitest and Cucumber suites; ESLint is local-only (Jenkins does not run lint).

| Suite | Framework | Command |
|-------|-----------|---------|
| Lint | ESLint 9 (via `yarn`) | `yarn run lint` |
| Minitest | Minitest ~> 5.0 (5.27.0) + minitest-reporters 1.8.0 | `bin/rails test` |
| Cucumber | Cucumber 9.2.1 + Capybara 3.40.0 + Selenium WebDriver 4.46.0 | `bundle exec rake dad:test` |

Locally, run lint in full and scope Minitest/Cucumber to the files you changed. Full `bin/rails test` and `bundle exec rake dad:test` are slow; Jenkins is the safety net for the rest of the suite.

`test/test_helper.rb` requires `daddy/test_help` first. That file starts SimpleCov when `COVERAGE` is set, and enables minitest-reporters when `FORMAT` is set (see [Configuration](CONFIGURATION.md)).

**Prerequisites:** Create the test database once, then keep its schema in sync.

```bash
bundle exec rake dad:db:create
bin/rails db:test:prepare
```

`dad:db:create` creates `bookmarks_dev` and `bookmarks_test`. After schema changes, re-run `bin/rails db:test:prepare`. `rake dad:test` already depends on `db:test:prepare` (via the `closer` gem).

In Jenkins, `RAILS_ENV=test` is set for the whole job, so `bundle exec rails db:reset` rebuilds the test database there. Locally, `bin/rails db:reset` without `RAILS_ENV=test` resets development, not test.

## Running tests

### Lint (ESLint)

Lints JavaScript files under `app/assets/javascripts/`. Run this in full — it is fast, and Jenkins does not run it.

```bash
yarn run lint          # Check for violations
yarn run lint:fix      # Auto-fix violations
```

ESLint is configured in `eslint.config.mjs` using `@babel/eslint-parser` with `eslint-config-prettier` to avoid conflicts with Prettier formatting.

### Minitest

```bash
bin/rails test                                              # Full suite (Jenkins unit stage)
bin/rails test test/models/user_test.rb                     # Single file
bin/rails test test/controllers/                            # All controller tests
bin/rails test test/models/user_test.rb:42                  # Single test by line number
bin/rails test test/controllers/todos_controller_test.rb -n /一覧/  # By test name
```

### Cucumber (E2E)

```bash
bundle exec rake dad:test                                   # Full suite (Jenkins features job)
bundle exec rake dad:test features/02.タスク.feature         # Single feature
bundle exec rake dad:test features/02.タスク.feature:23      # Single scenario by line number
DRY_RUN=1 bundle exec rake dad:test features/02.タスク.feature  # Step-definition resolution, no browser
```

**Do not** run `bundle exec cucumber` directly. The `dad:test` rake task (from the `daddy` gem) sets `HEADLESS=true` if unset and invokes the `closer` gem's `close` task, which prepares the test DB, writes `features/reports/index.html`, and runs Cucumber with Capybara's embedded Puma server plus the Chrome driver. `dad:test` forwards any feature paths it receives (line numbers included) to Cucumber. Called with no arguments it runs all of `features`.

If `dad:test` fails once, re-run once. A consistent failure across two runs indicates a real regression. Occasional one-off failures caused by timing are possible; the suite is expected to be consistently green.

## Writing new tests

### Minitest file naming and structure

Test files follow Rails conventions:

- `test/models/*_test.rb` — ActiveRecord model tests (includes contract tests such as `active_record_dependent_contract_test.rb`)
- `test/controllers/*_controller_test.rb` — Controller tests using `ActionDispatch::IntegrationTest`
- `test/services/*_test.rb` — Service object tests
- `test/helpers/*_helper_test.rb` — Helper tests (`ActionView::TestCase`)
- `test/assets/*_contract_test.rb` — Frontend asset contract/regression tests (no browser)
- `test/i18n/` — Locale parity and translation smoke tests
- `test/lib/` — Library tests (OmniAuth Mastodon strategy)
- `test/mailers/` — Mailer tests (directory scaffolded via `.keep`, no tests present)
- `test/integration/` — Cross-cutting integration tests (directory scaffolded via `.keep`, currently empty)
- `test/system/` — Rails system tests (directory scaffolded via `.keep`; `ApplicationSystemTestCase` exists but is unused — E2E is Cucumber)

Test method names use Japanese descriptions following the existing convention:

```ruby
class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def test_一覧
    sign_in user
    get bookmarks_path
    assert_response :success
  end
end
```

Controller tests inherit from `ActionDispatch::IntegrationTest` (not `ActionController::TestCase`). `Devise::Test::IntegrationHelpers` is included automatically via `test_helper.rb`.

### Shared test helpers

All files in `test/support/` are loaded and mixed into `ActiveSupport::TestCase` via `class_eval`. Available helpers:

| Helper file | Provides |
|-------------|----------|
| `test/support/users.rb` | `user` — returns `User.first` (fixture `one`, id: 1) |
| `test/support/bookmarks.rb` | `bookmark(user)`, `bookmark_params(user)`, `folder_params(user)`, `bookmark_in_folder_params(user, folder)`, `invalid_bookmark_params(user)` |
| `test/support/preferences.rb` | `preference_params(options)` — default preference hash |
| `test/support/webmock.rb` | WebMock setup, localhost allowed, fixture feed URLs stubbed |
| `test/support/feeds.rb` | `feed_of(user_id)`, `feed_params` |
| `test/support/mastodon_accounts.rb` | `mastodon_account_of(user_id)`, `mastodon_account_params` |
| `test/support/query_counter.rb` | `count_visited_link_queries` — counts SQL queries touching `visited_links` |

### Fixtures

Fixtures live in `test/fixtures/` as YAML files: `users.yml`, `bookmarks.yml`, `feeds.yml`, `notes.yml`, `todos.yml`, `preferences.yml`, `portals.yml`, `visited_links.yml`, `mastodon_accounts.yml`, `oauth_identities.yml`. `visited_links.yml` has no rows — those tests create records in individual test methods.

**Important:** Rails fixture inserts skip ActiveRecord callbacks and encryption. `otp_secret` values in fixtures are stored as plain text. The test environment has `config.active_record.encryption.support_unencrypted_data = true` set to accommodate this.

The primary test user is `users(:one)` — `user@example.com`, id: 1, `admin: true`. The `user` helper method returns `User.first` which resolves to this record. Cucumber also reloads fixtures before each scenario via `ActiveRecord::FixtureSet.create_fixtures` (from `daddy/cucumber/hooks/fixtures.rb`).

### Network mocking

All external HTTP is blocked in Minitest via `WebMock.disable_net_connect!(allow_localhost: true)`. The `allow_localhost: true` flag permits Capybara's embedded Puma server and ChromeDriver (both on 127.0.0.1) so Cucumber is unaffected.

Feed fixture URLs are pre-stubbed in `test/support/webmock.rb` (`GET` matching `/slashdot/`) to prevent `WebMock::NetConnectNotAllowedError` when controllers render pages that load RSS feeds.

### Cucumber feature files and step definitions

Features are under `features/` and written in Japanese (`# language: ja`), except `features/13.Facebook.feature` which has no language header and uses English Gherkin keywords (`Feature:`/`Scenario:`/`Given`). Step definitions are in `features/step_definitions/`. Support modules are in `features/support/`.

To add a new E2E scenario:

1. Create or edit a `.feature` file in `features/` starting with `# language: ja`.
2. Add step definitions in a corresponding file in `features/step_definitions/`.
3. Use `features/support/login.rb`'s `sign_in(user)` helper for authentication — it handles the two-step TOTP flow automatically.
4. Use `features/support/preferences_reset.rb`'s `reset_preferences_via_browser!` to reset preference state between scenarios (call via the `Login#sign_in` helper which invokes this automatically).

Hooks in `features/support/hooks.rb` run `Capybara.reset_sessions!`, clear transient DB records (`MastodonAccount`, `XAccount`, `XApiCall`, `VisitedLink`), and resize the browser to 1280×800 before each scenario. Preference state is reset via the `/preferences` UI form (not direct ActiveRecord writes) to avoid cross-connection snapshot issues. `daddy/cucumber/rails.rb` sets `DatabaseCleaner.strategy = :truncation`.

Available Cucumber tags for per-scenario setup:

| Tag | Effect |
|-----|--------|
| `@mastodon_gadget` | Creates a MastodonAccount and stubs Mastodon API requests |
| `@x_gadget` | Creates an XAccount and stubs X/Twitter API requests |
| `@x_manual_add` | Stubs X API user lookup endpoints for manual account add flow |
| `@feed_visited_links` | Stubs a specific feed URL for visited-links scenarios |
| `@account_deletion` | Switches Capybara to `:rack_test` driver, resets user 3 state |
| `@admin_purge` | Creates a soft-deleted user for admin purge scenarios |
| `@connected_accounts` | Creates OauthIdentity records for OAuth disconnect scenarios |
| `@admin_x_api_report_rack` | Switches Capybara to `:rack_test` for admin report tests |
| `@mobile_portal` | Marks the scenario for a 390×844 viewport (`window_resize.rb`) |

The Cucumber `World` object includes `TestSupport` (which loads all `test/support/*.rb` helpers), `Login`, and `PreferencesReset`.

## Coverage requirements

No minimum coverage thresholds are configured.

`simplecov` 1.0.3 is in the Gemfile (`require: false`). `daddy/test_help` starts SimpleCov when `ENV['COVERAGE']` is set, skipping `features/`, `test/`, `user_stories/`, and `vendor/`. HTML output goes to `coverage/` (gitignored). The Jenkins unit stage sets `COVERAGE=true` and publishes that directory as the "Coverage" HTML report.

There is no `coverageThreshold` (or equivalent) anywhere in the repo.

## CI integration

Two Jenkins pipelines run the test suites. There are no GitHub Actions workflows. CI is Jenkins-only. <!-- VERIFY: Jenkins job triggers and instance URL are configured outside this repo -->

**`Jenkinsfile` — unit pipeline:**
- Runs the build, unit, and release stages <!-- VERIFY: SCM trigger is Jenkins job config, not in this file -->
- Runs in a Kubernetes pod with a MySQL sidecar (`inheritFrom 'default mysql'`)
- Environment: `RAILS_ENV=test`, `COVERAGE=true`, `FORMAT=junit`
- Steps: `rake dad:db:create` → `rails db:reset` → `rails test`
- JUnit results from `test/reports/**/*.xml` via `publishUnitResult()`
- Coverage HTML from `coverage/` published as "Coverage"
- Does not run ESLint
- On success, automatically triggers the `bookmarks-features` pipeline (`build job: "${APP_NAME}-features"`, `APP_NAME=bookmarks`) without waiting (`wait: false`)

**`Jenkinsfile.features` — E2E pipeline:**
- Triggered automatically by the unit pipeline on success, or can be run independently
- Runs Cucumber in a Kubernetes pod with MySQL and Chrome sidecars (`inheritFrom 'default mysql chrome'`)
- Environment: `RAILS_ENV=test`, `HEADLESS=true`, `REMOTE=true`
- Steps: `rake dad:db:create` → `rails db:reset` → `rake dad:test`
- HTML report published from `features/reports/` as "Features" in Jenkins (`index.html`)
