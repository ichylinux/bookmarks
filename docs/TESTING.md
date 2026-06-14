<!-- generated-by: gsd-doc-writer -->
# Testing

## Test framework and setup

The project runs three test suites that form a required quality gate before merging changes.

| Suite | Framework | Command |
|-------|-----------|---------|
| Lint | ESLint 9 (via `yarn`) | `yarn run lint` |
| Minitest | Minitest ~> 5.0 + minitest-reporters | `bin/rails test` |
| Cucumber | Cucumber + Capybara + Selenium WebDriver | `bundle exec rake dad:test` |

All three suites must be green before merging. Run the full gate check with:

```bash
yarn run lint && bin/rails test && bundle exec rake dad:test
```

**Prerequisites:** The test database must exist and be seeded before running Minitest or Cucumber.

```bash
bundle exec rake dad:db:create
bundle exec rails db:reset
```

## Running tests

### Lint (ESLint)

Lints JavaScript files under `app/assets/javascripts/`:

```bash
yarn run lint          # Check for violations
yarn run lint:fix      # Auto-fix violations
```

ESLint is configured in `eslint.config.mjs` using `@babel/eslint-parser` with `eslint-config-prettier` to avoid conflicts with Prettier formatting.

### Minitest

```bash
bin/rails test                                        # Full suite
bin/rails test test/models/user_test.rb               # Single file
bin/rails test test/controllers/                      # All controller tests
bin/rails test test/models/bookmark_test.rb:42        # Single test by line number
```

### Cucumber (E2E)

```bash
bundle exec rake dad:test
```

**Do not** run `bundle exec cucumber` directly. The `dad:test` rake task (from the `daddy` gem) spawns the Rails server and configures the headless Chrome driver automatically. Running `cucumber` directly will not have the server available and will fail.

If `dad:test` fails once, re-run once. A consistent failure across two runs indicates a real regression. Occasional one-off failures caused by timing are possible; the suite is expected to be consistently green.

## Writing new tests

### Minitest file naming and structure

Test files follow Rails conventions:

- `test/models/*_test.rb` — ActiveRecord model tests
- `test/controllers/*_controller_test.rb` — Controller tests using `ActionDispatch::IntegrationTest`
- `test/services/*_test.rb` — Service object tests
- `test/mailers/*_mailer_test.rb` — Mailer tests
- `test/assets/*_contract_test.rb` — Frontend asset contract/regression tests (no browser)
- `test/i18n/` — Locale parity tests
- `test/integration/` — Cross-cutting integration tests

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
| `test/support/bookmarks.rb` | `bookmark(user)`, `bookmark_params(user)`, `folder_params(user)` |
| `test/support/preferences.rb` | `preference_params(options)` — default preference hash |
| `test/support/webmock.rb` | WebMock setup, localhost allowed, fixture feed URLs stubbed |
| `test/support/feeds.rb` | Feed-related helpers |
| `test/support/mastodon_accounts.rb` | Mastodon account helpers |
| `test/support/query_counter.rb` | `count_visited_link_queries` — counts SQL queries touching `visited_links` |

### Fixtures

Fixtures live in `test/fixtures/` as YAML files: `users.yml`, `bookmarks.yml`, `feeds.yml`, `notes.yml`, `todos.yml`, `preferences.yml`, `portals.yml`, `visited_links.yml`, `mastodon_accounts.yml`.

**Important:** Fixtures use raw SQL inserts and bypass ActiveRecord callbacks and encryption. `otp_secret` values in fixtures are stored as plain text. The test environment has `config.active_record.encryption.support_unencrypted_data = true` set to accommodate this.

The primary test user is `users(:one)` — `user@example.com`, id: 1, `admin: true`. The `user` helper method returns `User.first` which resolves to this record.

### Network mocking

All external HTTP is blocked in Minitest via `WebMock.disable_net_connect!(allow_localhost: true)`. The `allow_localhost: true` flag permits Capybara's embedded Puma server and ChromeDriver (both on 127.0.0.1) so Cucumber is unaffected.

Feed fixture URLs are pre-stubbed in `test/support/webmock.rb` to prevent `WebMock::NetConnectNotAllowedError` when controllers render pages that load RSS feeds.

### Cucumber feature files and step definitions

Features are under `features/` and written in Japanese (`# language: ja`). Step definitions are in `features/step_definitions/`. Support modules are in `features/support/`.

To add a new E2E scenario:

1. Create or edit a `.feature` file in `features/` starting with `# language: ja`.
2. Add step definitions in a corresponding file in `features/step_definitions/`.
3. Use `features/support/login.rb`'s `sign_in(user)` helper for authentication — it handles the two-step TOTP flow automatically.
4. Use `features/support/preferences_reset.rb`'s `reset_preferences_via_browser!` to reset preference state between scenarios (call via the `Login#sign_in` helper which invokes this automatically).

Hooks in `features/support/hooks.rb` run `Capybara.reset_sessions!` and clear transient DB records (`MastodonAccount`, `XAccount`, `VisitedLink`, etc.) before each scenario. Preference state is reset via the `/preferences` UI form (not direct ActiveRecord writes) to avoid cross-connection snapshot issues.

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

The Cucumber `World` object includes `TestSupport` (which loads all `test/support/*.rb` helpers), `Login`, and `PreferencesReset`.

## Coverage requirements

No minimum coverage thresholds are configured. `simplecov` is present in the Gemfile (`require: false`) and is activated in CI when the `COVERAGE=true` environment variable is set (Jenkinsfile unit stage). No coverage threshold enforcement is defined; reports are generated for informational purposes only.

## CI integration

Two Jenkins pipelines run the test suites:

**`Jenkinsfile` — unit pipeline:**
- Triggers on the main build/release flow
- Runs in a Kubernetes pod with a MySQL sidecar
- Environment: `RAILS_ENV=test`, `COVERAGE=true`, `FORMAT=junit`
- Steps: `rake dad:db:create` → `rails db:reset` → `rails test`
- JUnit results are published via `publishUnitResult()`

**`Jenkinsfile.features` — E2E pipeline:**
- Runs Cucumber separately in a Kubernetes pod with MySQL and Chrome sidecars
- Environment: `RAILS_ENV=test`, `HEADLESS=true`, `REMOTE=true`
- Steps: `rake dad:db:create` → `rails db:reset` → `rake dad:test`
- HTML report published from `features/reports/` as "Features" in Jenkins

There are no GitHub Actions workflows. CI is Jenkins-only.
