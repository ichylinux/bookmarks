# Testing Patterns

**Analysis Date:** 2026-11-26

## Suites

| Suite | Framework | Command | Run in CI? |
|-------|-----------|---------|-----------|
| Lint | ESLint 9 | `yarn run lint` | **No**, local only |
| Unit + integration | Minitest 5.27 | `bin/rails test <path>` | Jenkins `unit` stage (full) |
| E2E | Cucumber 10 + Capybara + Selenium (headless Chrome) | `bundle exec rake dad:test <feature[:line]>` | Jenkins `bookmarks-features` job (full) |
| Dependency audit | bundler-audit | `bin/bundler-audit` | Jenkins `unit` stage |

**Scoping policy (from `CLAUDE.md`):** never run the full Minitest or Cucumber suite locally; run the tests related to the change and say which ones you ran. Never call `bundle exec cucumber` directly; `dad:test` starts the server and browser. `DRY_RUN=1 bundle exec rake dad:test <feature>` checks that steps resolve without a browser.

```bash
bin/rails test test/models/visited_link_test.rb
bin/rails test test/controllers/notes_controller_test.rb:42
bin/rails test test/controllers/feeds_controller_test.rb -n /設定/
bundle exec rake dad:test features/08.訪問済みリンク.feature
bundle exec rake dad:test features/15.フィードガジェット.feature:12
```

## Layout

```
test/                                  # 76 *_test.rb files
├── test_helper.rb                     # daddy/test_help, fixtures :all, support/ class_eval, Devise IntegrationHelpers
├── support/                           # bookmarks, feeds, mastodon_accounts, preferences, users (user → User.first),
│                                      # webmock (disable_net_connect!, allow_localhost; RSS stubs), query_counter
├── fixtures/                          # users, oauth_identities, preferences, portals, bookmarks, feeds, notes,
│                                      # todos, mastodon_accounts, visited_links, files/
├── models/                            # incl. user_purge, user_disconnect_auth, user_password_auth, user_two_factor,
│                                      # user_mastodon_handle, visited_link, x_api_call, oauth_identity,
│                                      # active_record_dependent_contract
├── controllers/                       # IntegrationTest; admin/, users/, welcome_controller/{dashboard,layout_structure,root_path}
├── services/                          # x_client, mastodon_client, *_normalizer
├── lib/omniauth/strategies/           # Mastodon strategy
├── assets/                            # 18 source-level contract tests for JS / CSS
├── i18n/                              # locales_parity, rails_i18n_smoke, changelog, admin_users, email_registrations, portal_column_widths
├── helpers/                           # application_helper, welcome_helper
└── integration/ mailers/ system/      # empty

features/                              # 15 feature files (01–15; two share 07)
├── step_definitions/                  # one file per domain (bookmarks, todos, notes, feeds, visited_links, x_accounts,
│                                      # mastodon, preferences, connected_accounts, facebook, admin_*, account_deletion,
│                                      # gadget_settings_dialog, modern_theme, simple_theme)
└── support/
    ├── env.rb                         # require 'daddy/cucumber/rails'
    ├── hooks.rb                       # global Before + tagged Before/After hooks
    ├── login.rb                       # sign_in(user) via the UI (+ TOTP); resets preferences once per user
    ├── preferences_reset.rb           # reset_preferences_via_browser! — fills /preferences with defaults
    ├── gadget_settings_helpers.rb
    ├── test_support.rb                # mixes test/support/*.rb into World
    └── window_resize.rb               # resize_browser_window, @mobile_portal (390×844)
```

## Fixtures

- Primary user `users(:one)` (= `User.first`), password `testtest`, `admin: true`.
- X identities live in `oauth_identities.yml` (e.g. `twitter_user_twitter2`: provider `twitter2`, uid `fixture_twitter_uid`), not on `users`.
- Encrypted columns are plain text in fixtures; `config/environments/test.rb` sets `support_unencrypted_data = true`.

## Minitest Patterns

```ruby
# test/controllers/feed_article_histories_controller_test.rb
class FeedArticleHistoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.find(1)
    @other_user = User.find(2)
    @user.preference.update!(use_feed_article_histories: true)
    VisitedLink.delete_all
  end

  def test_index_success
    sign_in @user
    get feed_article_histories_path
    assert_response :success
    assert_select '#history-page.history-page', count: 1
  end
end
```

Newer tests often load users with `User.find(1)` / `User.find(2)` in `setup` rather than the `user` helper.

- Both `def test_<日本語>` (domain) and `test 'English description' do` (contract / regression) are used.
- Ownership tests: request another user's record → `assert_response :not_found`.
- Query-count guards: `count_visited_link_queries { … }` (`test/support/query_counter.rb`).

**Asset contract tests** read source files and assert on strings or regexes (no browser), e.g. `visited_links_js_contract_test.rb` checks the IIFE wrapper, the delegated selector excluding bookmark / todo gadgets, and that `addClass('link--visited')` comes before `postVisitedLink(`. `css_architecture_contract_test.rb` forbids theme selectors in non-theme SCSS. When you change a JS / CSS file that has a contract test, run that test.

**Structural contract:** `active_record_dependent_contract_test.rb` fails if any model declares `dependent: :destroy` or `dependent: :delete_all`.

## HTTP Stubbing

- **WebMock** globally (`test/support/webmock.rb`); localhost allowed for Capybara / ChromeDriver.
- **Faraday test adapter** for services: `XClient.new(connection: Faraday.new { |f| f.adapter :test, stubs })`.
- **`Faraday.new` singleton swap** in `BookmarksControllerTest` for `fetch_title`.
- X data stubs target `api.twitter.com`; token refresh targets `api.x.com`.

## Cucumber Patterns

- Most features use `# language: ja` (`機能:` / `シナリオ:` / `もし` / `ならば`); `13.Facebook.feature` is written in English Gherkin.
- `capture` at the end of steps saves screenshots to `features/reports/images/`.
- **DB cleanup:** `daddy/cucumber/rails` sets DatabaseCleaner truncation and reloads fixtures per scenario (per `docs/TESTING.md`).
- **Global `Before`:** `Capybara.reset_sessions!`, clears the memoized user and preference-reset marker, deletes all `MastodonAccount`, `XAccount`, `XApiCall`, `VisitedLink` rows, and resizes to 1280×800.
- **Preference state is reset through the browser** (`/preferences` form) on the first `sign_in` of each scenario. Do not write preferences through ActiveRecord in steps; that caused the cross-connection leakage fixed in `bce47df`.
- **Tags with hooks:** `@mastodon_gadget`, `@x_gadget`, `@x_manual_add`, `@feed_visited_links`, `@mobile_portal`, `@account_deletion`, `@admin_purge`, `@admin_x_api_report_rack` (switches to `:rack_test`), `@connected_accounts`. Feature-level tags without hooks: `@facebook`, `@admin_x_api_report`.
- Remote APIs are stubbed with WebMock inside the hooks, so the in-process server never reaches X, Mastodon or RSS hosts.

## Choosing Related Tests

| Changed | Run |
|---------|-----|
| `app/models/visited_link.rb`, `visited_links_controller.rb` | `test/models/visited_link_test.rb`, `test/controllers/visited_links_controller_test.rb`, `features/08.訪問済みリンク.feature` |
| `feed_article_histories` | its controller test + `features/08.訪問済みリンク.feature` |
| Feed gadget / settings dialog | `feeds_controller_test.rb`, `test/assets/gadget_header_settings_contract_test.rb`, `features/15.フィードガジェット.feature` |
| X | `x_accounts_controller_test.rb`, `test/services/x_client_test.rb`, `features/06.X.feature`, `07.X手動追加.feature`, `10.X_API利用状況.feature` |
| Mastodon gadget / OAuth | `mastodon_accounts_controller_test.rb`, services, `test/lib/omniauth/…`, `features/05.Mastodon.feature` |
| Preferences | `preferences_controller_test.rb`, `preference_test.rb`, `features/07.設定.feature` |
| Auth disconnect / identities | `oauth_identities_controller_test.rb`, `user_disconnect_auth_test.rb`, `features/14.連携アカウント.feature` |
| Account delete / purge | `user_purge_test.rb`, `admin/users_controller_test.rb`, `features/09.…`, `12.…` |
| Theme CSS | relevant `test/assets/*` + `features/03.モダンテーマ.feature` |
| Locale YAML | `test/i18n/` |

## Coverage

Jenkins sets `COVERAGE=true` and publishes `coverage/index.html`. SimpleCov is started by `daddy/test_help` when `COVERAGE` is set (per `docs/TESTING.md`; the gem source isn't in this repo). No threshold is enforced.

## Flakiness

Resolved 2026-05-19 (`bce47df`, browser-driven preference resets). If `dad:test` fails, re-run once; a failure that repeats is a real regression.

---

*Testing analysis: 2026-11-26*
