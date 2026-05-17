# Codebase Concerns

**Analysis Date:** 2026-05-18

---

## Security Considerations

### [HIGH] SSRF via `fetch_title` — No Private IP Blocking

- Risk: The `BookmarksController#fetch_title` action accepts a user-supplied URL, validates it is `http`/`https`, then makes a server-side HTTP request via Faraday. It does not block `localhost`, `127.0.0.1`, `10.x`, `172.16.x`, or `192.168.x`. An authenticated user can probe internal services.
- Files: `app/controllers/bookmarks_controller.rb:64–82` (`safe_fetch_title_url!` validates scheme only)
- Current mitigation: Requires authentication (attacker must be a signed-in user). Only `http`/`https` schemes are allowed. No further blocking.
- Recommendation: Resolve the hostname after parsing and reject RFC-1918/loopback addresses before making the request. Similar risk exists in `FeedsController#fetch_title` (`app/controllers/feeds_controller.rb:51–63`) which passes user-supplied `feed_url` directly to `Feed.new` and calls `feed?`, triggering the HTTP request inside `Feed#retrieve_feed`.

### [HIGH] Hardcoded Fallback Encryption Keys in `application.rb`

- Risk: `config.active_record.encryption.*` keys fall back to the literal string `'dev_dummy_key'` when ENV vars are absent. If a production deployment is missing these ENV vars, all encrypted data (`users.token`, `users.token_secret`, `users.otp_secret`) is encrypted with known keys.
- Files: `config/application.rb:30–32`
- Current mitigation: ENV var names are documented. Production deploys should set them.
- Recommendation: Raise at boot if any of the three keys resolves to `'dev_dummy_key'` when `Rails.env.production?`. This prevents silent misconfiguration.

### [MEDIUM] Content Security Policy Not Configured

- Risk: The CSP initializer is entirely commented out. No `Content-Security-Policy` header is sent. Inline scripts and styles are unrestricted.
- Files: `config/initializers/content_security_policy.rb` (all lines commented)
- Current mitigation: Rails escapes template output by default; jQuery-based JS is inline in asset files.
- Recommendation: Enable CSP with at minimum `default-src 'self'` and add nonce support for inline scripts.

### [MEDIUM] `html_safe` on Server-Generated QR Code SVG

- Risk: The QR code SVG string is rendered via `@qr_code.html_safe` without sanitization.
- Files: `app/views/users/two_factor_setup/setup.html.erb:6`
- Current mitigation: `@qr_code` is produced by the `rqrcode` gem from the user's own OTP provisioning URI — not from user-supplied input. Risk is low but violates defence-in-depth.
- Recommendation: Confirm the `rqrcode` gem never embeds user-controlled data in unsafe positions, or wrap with `ActionController::Base.helpers.sanitize`.

### [MEDIUM] `secrets.yml` Contains Plaintext Dev/Test `secret_key_base`

- Risk: `config/secrets.yml` stores plaintext dev and test `secret_key_base` values and is committed to git. Production key is read from `ENV["SECRET_KEY_BASE"]` but falls back to running `` `bin/rails secret` `` at runtime — producing a new key per process restart and invalidating all sessions.
- Files: `config/secrets.yml`
- Current mitigation: Dev/test keys are non-secret by convention.
- Recommendation: Remove the shell-backtick fallback in production. Require `SECRET_KEY_BASE` env var to be set, or migrate to Rails credentials (`credentials.yml.enc`).

### [MEDIUM] `User.save(validate: false)` on Twitter OAuth Update

- Risk: When an existing Twitter-linked user signs in via OAuth, `user.save(validate: false)` is called. This skips email format validation and any future validators.
- Files: `app/models/user.rb:48`
- Current mitigation: Only updates `provider`, `uid`, `token`, `token_secret` attributes — none of which have model-level validations currently.
- Recommendation: Use `update_columns` for the specific attributes to be explicit about bypassing callbacks, or restructure to keep validations active.

### [LOW] Host Authorization Disabled in Production

- Risk: `config.hosts` is commented out in `config/environments/production.rb:75–81`. DNS rebinding protection is not enforced.
- Files: `config/environments/production.rb:75`
- Current mitigation: `config.force_ssl = true` and `config.assume_ssl = true` are active.
- Recommendation: Uncomment and set `config.hosts` to the production hostname.

### [LOW] `admin?` Method Relies on Database Row Order

- Risk: `User#admin?` is implemented as `self.email == User.first.email`. This compares the current user to the first row returned by an unordered query. It works in practice because the seed user is the earliest record, but it is fragile.
- Files: `app/models/user.rb:80–82`
- Current mitigation: The `admin` boolean column exists in the schema (`users.admin`) but is not used by the method. Admin functionality appears to be minimal/unused in controllers.
- Recommendation: Replace with `self.admin` column check. The column already exists.

---

## Tech Debt

### [HIGH] Faraday Pinned at v1 (EOL)

- Issue: `Gemfile.lock` shows `faraday (1.10.5)`. Faraday v2 was released and v1 is unmaintained. `faraday_middleware` is a v1-era companion gem.
- Files: `Gemfile:14–16`, `Gemfile.lock`
- Impact: Missing security fixes in HTTP client; `faraday_middleware` gem is deprecated and not compatible with Faraday v2.
- Fix approach: Upgrade `faraday` to `~> 2.0`, replace `faraday_middleware` with Faraday v2 built-in middleware, update `faraday-oauth1` compatibility.

### [HIGH] `omniauth-twitter` Uses OAuth 1.0a Against a Deprecated API Path

- Issue: `omniauth-twitter` (v1.4.0) uses the Twitter v1.1 OAuth 1.0a callback flow, which X Corp has been deprecating. The gem is not actively maintained.
- Files: `Gemfile`, `app/models/user.rb:30–58`
- Impact: Twitter/X login may break without warning if X Corp disables the v1.1 endpoint.
- Fix approach: Evaluate `omniauth-twitter2` or X's official OAuth 2.0 PKCE flow.

### [MEDIUM] `uglifier` Asset Pipeline (Legacy Sprockets JS Minifier)

- Issue: `uglifier` (4.2.1) relies on ExecJS and a system JavaScript runtime. The project uses the Sprockets asset pipeline with jQuery rather than a modern bundler (Webpack, esbuild, importmap is mentioned in CI but assets use Sprockets).
- Files: `Gemfile:30`, `app/assets/javascripts/`
- Impact: Slow asset compilation; ExecJS adds a Node.js runtime dependency; no ES module support.
- Fix approach: Long-term: migrate JS to importmap or esbuild. Short-term: accept current state.

### [MEDIUM] `Portal#update_layout` Has N+1 Writes

- Issue: `update_layout` loops over every gadget ID in every column and issues a `WHERE ... FIRST` + `SAVE!` per entry. For a portal with N gadgets, this is O(N) queries inside a transaction.
- Files: `app/models/portal.rb:31–49`
- Impact: Acceptable for small datasets (personal app), but degrades with more gadgets.
- Fix approach: Load all existing `PortalLayout` records for the user once, diff in memory, then bulk-insert/update.

### [MEDIUM] `Feed#base_url` / `#request_path` URL Parsing is Fragile

- Issue: `base_url` and `request_path` split the feed URL by `/` character rather than using `URI`. A feed URL with an unusual path (double slashes, encoded characters) will produce wrong results silently.
- Files: `app/models/feed.rb:117–139`
- Impact: Feeds with non-standard URLs fail silently (returns `false` from `feed?`).
- Fix approach: Replace string-split logic with `URI.parse(feed_url)` to extract host and path components.

### [MEDIUM] `Preference.default_preference` Returns an Unsaved Record

- Issue: `User#preference` calls `Preference.default_preference(self)` which returns an unsaved `Preference.new`. Callers that call methods on this object get sensible defaults, but any call to `preference.update!` or `preference.save!` will create a new record only if the caller also saves. The `ApplicationController#render_font_size_migration_notice` calls `preference.update_column` on this potentially unsaved object, which would raise.
- Files: `app/models/user.rb:84–86`, `app/models/preference.rb:43–52`, `app/controllers/application_controller.rb:14–23`
- Impact: `font_size_notice_pending?` is guarded so `update_column` is never reached on an unsaved record. Currently safe but the pattern is easy to misuse in future code.
- Fix approach: Use `find_or_create_by` in `User#preference` instead of returning an unsaved record.

### [LOW] `PreferencesController` Duplicates `create` and `update` Actions

- Issue: `PreferencesController#create` and `#update` are identical — same params, same save logic, same redirect. The duplication exists because preferences may or may not exist at create time, but `accepts_nested_attributes_for` on User handles this transparently.
- Files: `app/controllers/preferences_controller.rb:8–38`
- Fix approach: Merge into a single `upsert`-style action, or keep only `update` and redirect `create` to it.

### [LOW] No `dependent:` Option on Most `User` Associations

- Issue: Most `User` associations lack `dependent: :destroy` or `dependent: :nullify`. A hard-delete of a User record leaves orphaned rows across `notes`, `bookmarks`, `feeds`, `todos`, `portals`, `portal_layouts`, `preferences`, and `mastodon_accounts`. The comment in `user.rb` acknowledges this for `:notes` but the problem extends to all associations.
- Files: `app/models/user.rb:19–25`
- Impact: Orphaned data on user hard-delete. In practice, user deletion is rare, but there is no protection.
- Fix approach: Add `dependent: :destroy` to associations, or add database-level `ON DELETE CASCADE` via migration, or enforce a soft-delete-only policy and document it explicitly.

---

## Performance Bottlenecks

### [MEDIUM] `Portal#portal_columns` Makes Multiple Separate Queries Per Page Load

- Issue: `get_gadgets` in `portal.rb` issues separate queries for `Todo`, `Feed`, `MastodonAccount`, and `XAccount` for every page render of the portal. No eager loading.
- Files: `app/models/portal.rb:53–85`
- Impact: Linear in number of gadget types; currently bounded by the small number of gadget types. Acceptable for personal use.

### [MEDIUM] Feed RSS Fetch on Every Request (No Caching)

- Issue: `Feed#feed` fetches the remote RSS URL synchronously on the first call per request. The portal page renders each feed gadget, which triggers a separate HTTP call per feed. No HTTP-level caching, no background jobs, no ETag support.
- Files: `app/models/feed.rb:13–24`, `app/models/feed.rb:67–72`
- Impact: Portal page load time scales linearly with the number of feeds. A slow or unavailable RSS server blocks the page render for that gadget.
- Fix approach: Introduce background fetching (ActiveJob) to cache feed content in the database, serve from cache on page render, and refresh asynchronously. The portal already uses XHR lazy loading (`portal_lazy.js`) for gadgets, which partially mitigates visible slowness.

### [LOW] `XAccount.refresh_cache_from_items!` Has N+1 Updates on Soft-Delete

- Issue: The soft-delete loop calls `acc.update!(deleted: true)` per missing record.
- Files: `app/models/x_account.rb:51–55`
- Fix approach: Replace with `XAccount.where(user_id: user.id).where.not(x_user_id: seen.keys).update_all(deleted: true, updated_at: Time.current)`.

### [LOW] Missing DB Indexes on Frequently Filtered Columns

- Issue: `bookmarks.user_id`, `feeds.user_id`, `todos.user_id`, `portals.user_id`, `portal_layouts.user_id`, `preferences.user_id` have no explicit indexes in `db/schema.rb`. Only `mastodon_accounts`, `notes`, and `x_accounts` have `user_id` indexes.
- Files: `db/schema.rb`
- Impact: Full table scans on `bookmarks`, `feeds`, `todos`, `portals` when filtering by `user_id`. Negligible for a single-user app; significant if the user base grows.
- Fix approach: Add indexes via migration: `add_index :bookmarks, :user_id`, `add_index :feeds, :user_id`, etc.

---

## Test Coverage Gaps

### [MEDIUM] `Portal#update_layout` Has No Unit Test

- What's not tested: The `update_layout` method that processes drag-and-drop portal layout saves. Authorization boundary (can a user update another user's portal via `save_state`?) is only tested end-to-end via Cucumber, not in Minitest.
- Files: `app/models/portal.rb:31–49`, `app/controllers/welcome_controller.rb:10–13`
- Risk: A regression in layout persistence would only be caught by Cucumber, which is the slowest suite.
- Priority: Medium

### [MEDIUM] `Feed#base_url` / `#request_path` URL Edge Cases Untested

- What's not tested: Feed URLs with query strings, encoded characters, no path segment, trailing slashes.
- Files: `app/models/feed.rb:117–139`, `test/models/feed_test.rb`
- Risk: Silent misfetch for unusual but valid feed URLs.
- Priority: Medium

### [MEDIUM] `BookmarksController#fetch_title` SSRF Guard Has No Test

- What's not tested: No unit or integration test verifies that `fetch_title` rejects private IPs or non-http/https schemes.
- Files: `test/controllers/bookmarks_controller_test.rb`
- Risk: SSRF guard regression could go undetected.
- Priority: High (given SSRF risk noted above)

### [LOW] `User#admin?` Not Tested

- What's not tested: The `admin?` method. No test verifies the first-user-is-admin logic or that the `admin` column is the correct source of truth.
- Files: `app/models/user.rb:80–82`, `test/models/user_test.rb`
- Priority: Low (admin functionality is minimally used in controllers)

### [LOW] Missing Translation Detection Not Enforced in Tests

- What's not tested: `config.i18n.raise_on_missing_translations` is commented out in both `development.rb` and `test.rb`. Missing translation keys produce silent `translation missing:` strings.
- Files: `config/environments/test.rb:46`, `config/environments/development.rb:62`
- Risk: UI silently shows raw translation keys if a new locale key is added to one locale but forgotten in another.
- Priority: Low (covered partially by `test/i18n/locales_parity_test.rb`)

---

## Fragile Areas

### [MEDIUM] Cucumber Suite — Shared DB State Between Scenarios

- Files: `features/support/hooks.rb`, all `features/*.feature` files
- Why fragile: Scenarios share a single database with no truncation between runs. The `Before` hook resets `Preference` fields and destroys `MastodonAccount`/`XAccount` rows but does not reset `Bookmark`, `Feed`, `Todo`, `Note`, or `PortalLayout` rows. Scenario-order-dependent failures are known and documented in `CLAUDE.md`.
- Safe modification: Always tag new scenarios that create data; add cleanup in `After` hooks or add DB truncation for affected tables in the global `Before` hook.

### [MEDIUM] `User#create_default_portal` Fires on Every `after_save`

- Files: `app/models/user.rb:117–122`
- Why fragile: The `after_save` callback runs on every user save (not just create), executing a `Portal.where(...).not_deleted.empty?` query each time. If portal creation fails (e.g., validation error), the error is raised inside the callback chain.
- Safe modification: Change to `after_create` to only run on initial user creation.

### [LOW] `Preference#migrate_legacy_font_sizes!` One-Time Migration Left in Model

- Files: `app/models/preference.rb:60–66`
- Why fragile: The migration method is still present in the model. It was designed as a one-time data migration but has no idempotency guard — calling it again would set `font_size = 'small'` and re-raise the notice for all users.
- Safe modification: Move to a rake task or data migration script, then remove from the model once the migration is confirmed complete in production.

---

## Scaling Limits

### [LOW] Single-User Architecture Assumptions Baked Into Tests and Model Logic

- `User#admin?` uses `User.first`. The Cucumber `user` helper uses `User.first`. The fixture assumes `id: 1`.
- Current capacity: Works for personal use with a single primary user.
- Scaling path: Not applicable for current use case, but limits operability if the app is ever shared.

---

## Dependencies at Risk

### [HIGH] `omniauth-twitter` (1.4.0) — Unmaintained, Twitter v1.1 API

- Risk: Gem last released 2019; depends on `omniauth-oauth` which uses Twitter API v1.1. X Corp deprecation of v1.1 endpoints could break Twitter/X sign-in without notice.
- Impact: Twitter OAuth login broken.
- Migration plan: Evaluate `omniauth-twitter2` (OAuth 2.0) or remove Twitter login and migrate existing Twitter users to email auth.

### [HIGH] `faraday` (1.10.5) — Major Version Behind

- Risk: Faraday v1 is unmaintained. `faraday_middleware` companion is not compatible with v2.
- Impact: No upstream security patches for the HTTP client used in feed fetching and X/Mastodon API calls.
- Migration plan: Upgrade to `faraday ~> 2.0`, remove `faraday_middleware`, update middleware usage in `app/services/x_client.rb` and `app/services/mastodon_client.rb`.

### [MEDIUM] `uglifier` (4.2.1) — Requires ExecJS / Node.js Runtime

- Risk: Depends on a system Node.js runtime for asset compilation. ExecJS is in maintenance mode.
- Impact: Build breakage if Node.js environment changes; no path to ES modules.
- Migration plan: Migrate to importmap (already partially referenced in `config/ci.rb`) or esbuild.

### [MEDIUM] `jquery-rails` / `jquery-ui-rails` — Legacy jQuery Dependency

- Risk: No known active security vulnerabilities, but the gems pin the project to a legacy frontend model incompatible with modern asset strategies.
- Impact: Blocks adoption of modern JS patterns (Stimulus, Turbo, importmap-native modules).
- Migration plan: Long-term rewrite to stimulus/vanilla JS; not urgent.

---

## Missing Critical Features

### [MEDIUM] No Background Job Processing for Feed Fetches

- Problem: RSS feeds are fetched synchronously during page render. There is no `ActiveJob` adapter configured for production (commented out in `production.rb`). Active Storage is configured but Active Job queue adapter is the default (inline/synchronous).
- Blocks: Feed reliability and portal page performance at scale.

### [MEDIUM] No Rate Limiting on Auth or API Endpoints

- Problem: No `rack-attack` or equivalent rate limiting is configured. The `fetch_title` endpoints and Devise sign-in have no brute-force or flood protection.
- Blocks: Hardening against credential stuffing and SSRF amplification attacks.

### [LOW] No Error Tracking / Observability

- Problem: No Sentry, Honeybadger, or equivalent error tracker configured. Errors are logged to STDOUT only in production.
- Blocks: Visibility into production errors without log access.

---

*Concerns audit: 2026-05-18*
