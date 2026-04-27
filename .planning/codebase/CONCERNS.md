# Technical Concerns

**Analysis Date:** 2026-04-27

## Overview

This is a Rails 8.1 personal portal application with a generally clean structure, but it carries several security gaps inherited from its 2013 origins — most critically a broken admin check, missing Content Security Policy, and authorization masking 404s as not-found instead of 403. Performance risks are concentrated in the portal page, which fires multiple sequential queries with no eager loading. There is also a `tweets` table in the database with no corresponding model or UI, and a `weathers` table that was created in migration history but never appears in `schema.rb`, both indicating abandoned features that add schema noise.

---

## Security

### Broken Admin Check — User.admin? Races on Record Order

**Risk:** High
**File:** `app/models/user.rb:45`

`admin?` is implemented as `self.email == User.first.email`. This relies on database insertion order — whichever user has the lowest primary key `id` is admin. If the first user is ever deleted and a new user registers, the second user becomes admin. This is also an extra DB query on every admin check.

**Fix approach:** Use the existing `admin` boolean column already present on `users` (see `db/schema.rb:91`). Replace the method body with `self.admin`.

---

### Content Security Policy Entirely Disabled

**Risk:** High
**File:** `config/initializers/content_security_policy.rb`

The entire CSP configuration block is commented out. No `Content-Security-Policy` header is sent to browsers, leaving the app fully exposed to XSS injection via any third-party content (feed entries, bookmark titles rendered into DOM via jQuery).

**Fix approach:** Uncomment and configure the CSP block with at minimum `default_src :self`, `script_src :self`, `style_src :self`, and `img_src :self :https :data`.

---

### Host Authorization Not Configured in Production

**Risk:** Medium
**File:** `config/environments/production.rb:75`

`config.hosts` is commented out. Rails 6+ DNS rebinding protection is present by default, but without an explicit allowlist the protection depends on the Rails default behavior rather than an intentional configuration.

**Fix approach:** Uncomment and set `config.hosts` to the production domain(s).

---

### Authorization Returns 404 Instead of 403 for Unauthorized Records

**Risk:** Medium
**Files:** `app/controllers/bookmarks_controller.rb:68`, `app/controllers/feeds_controller.rb:66`, `app/controllers/calendars_controller.rb:72`, `app/controllers/todos_controller.rb:65`

All `preload_*` before-actions return `head :not_found` when a record belongs to another user. While this is an intentional security-through-obscurity choice (hiding existence of IDs), it is inconsistent: `todos_controller.rb:50` (bulk delete) returns `:not_found` for authorization failure in the same action loop, which could leak partial success information.

**Fix approach:** Document the deliberate 404 pattern, and make the bulk-delete authorization failure consistent with it (abort the whole transaction and return 404 rather than per-item checks mid-loop).

---

### Twitter OAuth Callback Uses Hardcoded Flash Message

**Risk:** Low
**File:** `app/controllers/users/omniauth_callbacks_controller.rb:17`

The `handle_callback` method is called for both Google and Twitter, but the success flash message is hardcoded to `kind: "Twitter"` regardless of which provider authenticated. This is a functional bug, not a security issue, but it indicates the callback code is not provider-agnostic as intended.

**Fix approach:** Pass `kind` as the `kind` parameter from the caller, which already supplies the correct string (`'Google'` or `'Twitter'`).

---

### Twitter OAuth — Dummy Email Collisions Theoretically Possible

**Risk:** Low
**File:** `app/models/user.rb:22`

Twitter users are matched by `name` only, and accounts are created with `dummy_<uuid>@example.com`. If two Twitter accounts have identical display names, the app will silently sign in the first matching user for both. `SecureRandom.uuid` prevents email collisions on creation, but the name-only lookup is fragile.

**Fix approach:** Store and match the Twitter `uid` (available in OmniAuth data) instead of display name.

---

### Active Record Encryption Keys Have Hardcoded Fallback

**Risk:** Medium
**File:** `config/application.rb:30-32`

All three Active Record Encryption keys fall back to the literal string `'dev_dummy_key'` when environment variables are not set. If production is ever deployed without those env vars, encrypted fields use a known key that is publicly visible in the repository.

**Fix approach:** Remove the fallback defaults so `ENV.fetch` raises a `KeyError` on missing config, forcing an explicit key on every deployment.

---

## Performance

### Portal Page Fires Multiple Uncoordinated Queries Per Request

**Risk:** Medium
**File:** `app/models/portal.rb:50-73`

`get_gadgets` issues separate `WHERE user_id = ?` queries for `BookmarkGadget` entries, `Todo`, `Calendar`, and `Feed` every time the portal page loads. There is no caching, memoization beyond the per-request `@portal_columns`, or eager loading of associations. With many feeds or calendar gadgets this compounds on every page visit.

**Fix approach:** Batch the four queries or introduce fragment caching on the portal column rendering.

---

### Portal Layout Update Issues One SELECT Per Gadget Position

**Risk:** Medium
**File:** `app/models/portal.rb:34-35`

`update_layout` calls `PortalLayout.where(...).first` inside a loop — one query per gadget position. For a portal with many gadgets this is a classic N+1 on writes.

**Fix approach:** Load all existing `PortalLayout` records for the user before the loop, then upsert from the in-memory collection.

---

### Feed Fetching Happens Synchronously on Each Request, No Timeout Configured

**Risk:** Medium
**File:** `app/models/feed.rb:62-67`

`retrieve_feed` makes a live HTTP request inside the request/response cycle via `Daddy::HttpClient`. There is no timeout configured and no background job. A slow or hanging upstream RSS feed blocks the Rails thread serving that request.

**Fix approach:** Move feed fetching to a background job (e.g., Active Job with Solid Queue) and cache the result. At minimum configure a request timeout on `Daddy::HttpClient`.

---

### No Database Indexes on Foreign Keys

**Risk:** Medium
**File:** `db/schema.rb`

None of the tables have indexes on `user_id` foreign keys: `bookmarks`, `calendars`, `feeds`, `portal_layouts`, `portals`, `preferences`, `todos`. Every `WHERE user_id = ?` query performs a full table scan. As data grows per-user queries will degrade.

**Fix approach:** Add indexes via migrations:
```ruby
add_index :bookmarks,      :user_id
add_index :calendars,      :user_id
add_index :feeds,          :user_id
add_index :portal_layouts, :user_id
add_index :portals,        :user_id
add_index :preferences,    :user_id
add_index :todos,          :user_id
```

---

### `Date.parse` Called with Unvalidated User Input

**Risk:** Low-Medium
**File:** `app/controllers/calendars_controller.rb:18`

`Date.parse(params[:display_date])` is called without rescue. Malformed input raises `Date::Error` (an `ArgumentError` subclass), producing an unhandled 500.

**Fix approach:** Wrap in a rescue or use `Date.parse` with a fallback: `Date.parse(params[:display_date]) rescue Date.today.beginning_of_month`.

---

## Technical Debt

### `save!` Inside Transactions Without Rescue in Most Controllers

**Files:** `app/controllers/bookmarks_controller.rb:28,46`, `app/controllers/feeds_controller.rb:24,37`, `app/controllers/todos_controller.rb:17,31`, `app/controllers/preferences_controller.rb:13,24`

Most controllers call `save!` inside a transaction block with no `rescue ActiveRecord::RecordInvalid`. Validation failures surface as uncaught 500 errors with a stack trace rather than re-rendering the form with error messages. Only `CalendarsController` correctly rescues `RecordInvalid`. The inconsistency means bookmark, feed, todo, and preference creation/update silently crash on validation failure.

**Fix approach:** Follow the `CalendarsController` pattern — wrap in `begin/rescue ActiveRecord::RecordInvalid` and re-render the appropriate form.

---

### `request.xhr?` Usage (Deprecated Pattern)

**Files:** `app/controllers/todos_controller.rb:10,24`, `app/controllers/feeds_controller.rb:10`

`request.xhr?` checks for the `X-Requested-With: XMLHttpRequest` header, a convention from jQuery AJAX that is not reliably sent by modern `fetch`-based clients. The pattern `render layout: !request.xhr?` will break if JavaScript is migrated away from jQuery.

**Fix approach:** Use `respond_to` with `format.html` / `format.js` blocks, or pass an explicit `layout: false` via a query parameter or separate route.

---

### `uglifier` — Requires ExecJS / Node at Asset Compilation Time

**File:** `Gemfile:30`

`uglifier` (version 4.2.1) depends on ExecJS and a JavaScript runtime for JS minification. Rails 8.1 ships with Propshaft/Import Maps as the preferred asset pipeline; uglifier belongs to the old Sprockets-based pipeline. This creates a fragile build dependency on a native JS runtime.

**Fix approach:** Evaluate migrating to Propshaft + a modern bundler (e.g., `jsbundling-rails` with esbuild), or at minimum replace uglifier with `terser` via `mini_racer`.

---

### `httparty` Gem Declared But Not Used in Application Code

**File:** `Gemfile:16`

`httparty` is declared as a runtime dependency but no application file uses `HTTParty` — `feed.rb` uses `Daddy::HttpClient` (via `faraday`). `httparty` adds boot-time load and gem surface area for no benefit.

**Fix approach:** Remove `gem 'httparty'` from `Gemfile`.

---

### `tweets` Table Has No Model, Controller, or UI

**File:** `db/schema.rb:78-88`

A `tweets` table exists in the database schema (with `tweet_id`, `twitter_user_id`, `twitter_user_name`, `content`, `retweet_count`) but there is no `Tweet` model, no controller, and no view referencing it. This is dead schema from an abandoned Twitter integration.

**Fix approach:** Write and run a migration to drop the `tweets` table, or add the table to a documented "parked" list if re-activation is planned.

---

### `admin` Column on `users` Table Is Unused

**File:** `db/schema.rb:91`, `app/models/user.rb:45`

The `users` table has an `admin` boolean column (`default: false`), but `User#admin?` ignores it and instead compares emails. The column is never written to through the application.

**Fix approach:** Fix `admin?` to use `self.admin` (see Security section above).

---

### `Preference.default_preference` Returns an Unsaved Record

**File:** `app/models/preference.rb:5-10`, `app/models/user.rb:49-51`

`User#preference` falls back to `Preference.default_preference(self)` which returns a `new` (unsaved) `Preference` instance. Code calling `user.preference.use_todo?` works, but any code that calls `user.preference.save` or passes the preference to a nested attributes form may behave unexpectedly because the record has no `id`.

**Fix approach:** Either always create a `Preference` record on user creation (in an `after_create` callback), or make the fallback explicit (`build_preference` rather than returning a virtual object).

---

### Portal Gadget Registry Is Hardcoded

**File:** `app/models/portal.rb:53`

`get_gadgets` has `[BookmarkGadget]` as a hardcoded array literal. Adding a new gadget type requires editing this method directly. The `Gadget` concern already exists as an abstraction point but there is no registry or auto-discovery.

**Fix approach:** Maintain a class-level registry (e.g., `Gadget::REGISTRY`) that gadget classes register into, and iterate the registry in `get_gadgets`.

---

## Other Concerns

### No Indexes on `bookmarks.parent_id` or `bookmarks.deleted`

**File:** `db/schema.rb:14-22`

`bookmarks` is queried by `WHERE parent_id = ? AND deleted = false` frequently, but neither `parent_id` nor `deleted` is indexed. A composite index on `(user_id, parent_id, deleted)` would cover the common query pattern.

---

### `weathers` Migration Exists But Table Is Absent from Schema

**File:** `db/migrate/20140317034635_create_weathers.rb`

An old migration creates a `weathers` table, but it does not appear in `db/schema.rb`, suggesting it was dropped in a subsequent migration that is not clearly documented. The orphaned migration remains in the history and could cause confusion when auditing the migration chain.

---

### Two Factor Disable Has No Confirmation Step

**File:** `app/controllers/users/two_factor_setup_controller.rb:23-26`

`disable` is a simple `DELETE` request that disables 2FA immediately on the current session without requiring OTP verification or a confirmation prompt. An attacker with a stolen session cookie can silently downgrade 2FA protection.

**Fix approach:** Require a valid `otp_attempt` before calling `disable_two_factor!`.

---

### No Rate Limiting on Authentication Endpoints

The application relies entirely on Devise defaults for login and OTP verification. There is no rack-attack or equivalent middleware configured to throttle brute-force attempts against `/users/sign_in` or `users/two_factor_authentication` (OTP verify).

**Fix approach:** Add `rack-attack` gem and configure throttles on sign-in and OTP endpoints.

---

*Concerns audit: 2026-04-27*
