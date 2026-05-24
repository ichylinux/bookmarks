# Testing

<!-- gsd-generated: docs-update 2026-05-25 -->

## Tri-suite gate

All three suites must pass before merging significant changes:

```bash
yarn run lint && bin/rails test && bundle exec rake dad:test
```

| Suite | Command | Purpose |
|-------|---------|---------|
| Lint | `yarn run lint` | ESLint on `app/assets/javascripts/**/*.js` |
| Minitest | `bin/rails test` | Models, controllers, services, assets, i18n |
| Cucumber | `bundle exec rake dad:test` | E2E in headless Chrome (starts Rails server) |

**Do not** run `bundle exec cucumber` directly — use `dad:test` so the server and driver are configured.

## Minitest

```bash
bin/rails test                              # Full suite
bin/rails test test/models/user_test.rb     # Single file
bin/rails test test/controllers/            # Directory
```

Layout:

- `test/models/`, `test/controllers/`, `test/services/`
- `test/assets/` — JS/CSS contract tests (no browser)
- `test/i18n/` — locale parity
- `test/support/` — helpers mixed into `ActiveSupport::TestCase`
- `test/fixtures/` — YAML fixtures

HTTP calls in tests use WebMock (`test/support/webmock.rb`). X API tests may use Faraday `:test` adapter.

## Cucumber

Features are under `features/` with Japanese scenarios (`# language: ja`). Step definitions in `features/step_definitions/`.

`features/support/hooks.rb` resets session and shared DB state between scenarios (preferences via UI, `VisitedLink.delete_all`, etc.).

If `dad:test` fails once, re-run once; a consistent failure on two runs indicates a real regression.

## Contract tests

Regression guards for frontend assets:

- `test/assets/css_architecture_contract_test.rb`
- `test/assets/portal_lazy_js_contract_test.rb`
- `test/models/active_record_dependent_contract_test.rb`
- Others under `test/assets/*_contract_test.rb`

## Coverage

`simplecov` is in the Gemfile (`require: false`) but not auto-loaded in the default test helper.
