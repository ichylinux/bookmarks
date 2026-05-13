# Requirements: Bookmarks v1.18 — X (Twitter) Account Following

**Defined:** 2026-05-14
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

**Milestone Goal:** Twitter-linked users (those whose OAuth credentials are persisted) can pick from their X following list to display selected accounts' latest tweets as welcome-page gadgets, mirroring the v1.16 Mastodon pattern with OAuth 1.0a User Context auth and a DB-cached following list.

---

## v1.18 Requirements

Requirements for milestone v1.18. Each maps to exactly one roadmap phase.

### XAUTH — Twitter OAuth Token Persistence

- [ ] **XAUTH-01**: `User.from_omniauth` Twitter branch persists `provider`, `uid`, `token`, and `token_secret` on both the create and the find branches (token rotation on every re-auth)
- [ ] **XAUTH-02**: `users.token_secret` column is added (string, nullable); `User` model declares `encrypts :token, :token_secret` so OAuth 1.0a credentials are encrypted at rest
- [ ] **XAUTH-03**: A `require_twitter_linked` controller `before_action` rejects requests where `current_user.uid.blank? || current_user.token.blank?`, redirecting to preferences with a localized alert; the user-editable `users.name` is NOT part of the gate
- [ ] **XAUTH-04**: Drawer navigation entry and preferences entry-link for X Accounts appear only when `current_user.uid.present? && current_user.token.present?`

### XAPI — XClient Service

- [ ] **XAPI-01**: `XClient` service exposes `fetch_following(user:)` and `fetch_recent_tweets(x_user_id:, limit:)` methods using OAuth 1.0a User Context signing via `faraday-oauth1` middleware with explicit connect (3s) and read (5s) timeouts
- [ ] **XAPI-02**: `XClient` returns `{ success: true, items: [...] }` or `{ success: false, error: <symbol> }` with the symbol enum `:timeout, :network, :not_found, :api_error, :parse_error, :unauthorized, :rate_limited`
- [ ] **XAPI-03**: `XClient` exposes class-level `stub_fetch_following_result` and `stub_fetch_tweets_result` accessors for Minitest + Cucumber stubbing, mirroring `MastodonClient.stub_fetch_result`; cleared in test teardown / Cucumber After
- [ ] **XAPI-04**: Tweet text is normalized before display: `entities.urls[].display_url` substitution for `t.co` shortlinks runs before truncation to `PREVIEW_LENGTH = 100`; edit-history latest id is resolved as the last element of `edit_history_tweet_ids`
- [ ] **XAPI-05**: Following-list pagination uses request param `pagination_token` paired with response `meta.next_token`; `max_results` is clamped to `[requested, 5].max.clamp(5, 100)`; tweet calls pass `?exclude=retweets,replies`

### XACCT — X Account Management UI

- [ ] **XACCT-01**: `/x_accounts` index page lists the user's cached X following entries (avatar, display name, `@handle`) with a per-row select checkbox; `require_twitter_linked` gates the controller
- [ ] **XACCT-02**: User can refresh the following-list cache via a POST "再取得 / Refresh" button that calls `XClient#fetch_following` and diff-upserts the local `x_accounts` table
- [ ] **XACCT-03**: User can toggle which cached accounts render as welcome gadgets via PATCH `/x_accounts/:id` (writes `selected: true/false`); server rejects toggling `selected=true` on rows not owned by `current_user`
- [ ] **XACCT-04**: Total `selected: true` rows per user are hard-capped at **12**; a soft warning is shown when the selected count reaches **9**; attempting to select a 13th account returns a localized error message
- [ ] **XACCT-05**: Protected (private) accounts in the following list are flagged with a 🔒 indicator and require explicit per-account confirmation (server-side `protected_acknowledged: true` write) before they can be marked `selected: true`
- [ ] **XACCT-06**: Refresh diff semantics: rows missing from the API response are soft-deleted (`deleted: true`) when `selected: true` so the UI can surface "this account dropped you / was unfollowed"; otherwise hard-deleted; previously soft-deleted accounts un-soft-delete on next refresh when they reappear in the API
- [ ] **XACCT-07**: Management page shows the last refresh timestamp ("最終更新: YYYY-MM-DD HH:MM" / "Last refreshed: …") above the table
- [ ] **XACCT-08**: Preferences page exposes an entry-link to `/x_accounts` for Twitter-linked users only (same gate as XAUTH-04)

### XGAD — Welcome Page Gadget

- [ ] **XGAD-01**: Each `selected: true` X account appears as a separate AJAX-loaded gadget panel on the welcome page, registered via `Portal#get_gadgets` (scoped to `selected: true` and `deleted: false`)
- [ ] **XGAD-02**: Each gadget calls `XAccountsController#show` (XHR via `render layout: !request.xhr?`); the action fetches up to `display_count` recent tweets via `XClient#fetch_recent_tweets`
- [ ] **XGAD-03**: Each tweet preview is a one-line stripped + truncated text linked to `https://x.com/i/status/{latest_tweet_id}`; click target obeys `current_user.preference.open_links_in_new_tab?`
- [ ] **XGAD-04**: Per-error-symbol localized empty/error states are rendered when fetch fails (`:timeout / :network / :api_error / :parse_error / :rate_limited / :unauthorized / :not_found`); `:unauthorized` includes a re-sign-in CTA pointing to `/users/auth/twitter`
- [ ] **XGAD-05**: Tweet text is NEVER rendered as `html_safe` or `raw`; the click-through URL is constructed server-side as `https://x.com/i/status/{id}` and never echoed from `entities.urls[].url` (open-redirect prevention)

### XI18N — Localization

- [ ] **XI18N-01**: All new UI chrome (management page headings, refresh button, error/empty states, gadget labels, preferences entry link, drawer link, alerts) is available in Japanese and English
- [ ] **XI18N-02**: Locale key parity between `ja.yml` and `en.yml` is enforced by the existing parity test for every new `x_accounts.*`, `welcome.x_account.*`, and shared `errors.x_client.*` key
- [ ] **XI18N-03**: User-generated content (tweet text, display name, `@handle`, bio) is rendered untranslated — same convention as bookmark titles and Mastodon toots

### XTEST — Test Coverage and Verification

- [ ] **XTEST-01**: `User` model OAuth persistence (create + update branches) and the encrypted column shape are covered by Minitest (`user_test.rb`)
- [ ] **XTEST-02**: `XClient` is covered by Minitest with the Faraday `:test` adapter, including all error-symbol branches and `stub_*_result` short-circuit; one integration-style test asserts the Authorization header begins with `OAuth oauth_consumer_key=`
- [ ] **XTEST-03**: `XAccount` model and `XAccountsController` are covered by Minitest with stubbed `XClient` calls (selection cap, protected-account confirmation guard, refresh diff branches, soft/hard delete)
- [ ] **XTEST-04**: A Cucumber feature `features/06.X.feature` (`@x_gadget` Before/After hooks for `stub_fetch_*_result`) verifies the welcome gadget appears and renders tweets end-to-end for a Twitter-linked fixture user
- [ ] **XTEST-05**: Cucumber global Before hook clears X-account state (`XAccount.where(user_id: fixture_user.id).delete_all`, both `stub_fetch_*_result` accessors, plus `user.update!(token: nil, token_secret: nil, uid: nil)` where appropriate) to prevent scenario-order leakage per `CLAUDE.md` flake policy
- [ ] **XTEST-06**: Final phase ships with all three suites green: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (tri-suite gate policy from `CLAUDE.md`)

---

## Future Requirements (Deferred to v1.19+)

Acknowledged but not in v1.18 scope; would be a separate milestone.

### XACCT — Management UI improvements

- **XACCT-FUT-01**: In-page client-side filter (substring match on handle + name) on the management list
- **XACCT-FUT-02**: Bulk select-all / clear-all controls
- **XACCT-FUT-03**: Selected-count indicator ("3 / 142 selected")
- **XACCT-FUT-04**: Pagination of the cached following list (defer until caches routinely exceed ~200 rows)

### XGAD — Gadget enhancements

- **XGAD-FUT-01**: Relative timestamps next to tweets ("2 hours ago")
- **XGAD-FUT-02**: Pinned tweet rendered first per account
- **XGAD-FUT-03**: Quote-tweet rendering with referenced-tweet text expansion
- **XGAD-FUT-04**: Media indicator icon (photo / video badge)
- **XGAD-FUT-05**: Media thumbnail rendering

### XAUTH — Identity follow-ups

- **XAUTH-FUT-01**: Fix v1.17 PITFALL-02 (`from_omniauth` Twitter branch should look up by `uid` not `name`); prerequisite (`users.uid` persisted) is laid by v1.18 XAUTH-01

---

## Out of Scope

Explicitly excluded; documented to prevent scope creep.

| Feature | Reason |
|---|---|
| Posting, replying, liking, retweeting from the gadget | Read-only dashboard scope; write scopes not requested; matches v1.16 Mastodon precedent |
| Following / unfollowing accounts from `/x_accounts` | Write surface lives on x.com — same rationale |
| Embedded `widgets.js` / X oEmbed | Third-party JS conflicts with "no new client-side state" constraint and degrades as x.com changes embed rules |
| Real-time updates (WebSocket / SSE / Turbo Streams) | No ActionCable in stack; welcome-render-time fetch is the contract |
| Background jobs for following sync or tweet caching | "新規バックグラウンドインフラは入れない" (Q6 decision); no sidekiq / solid_queue migration |
| Cross-platform merged Mastodon + X timeline | Couples two clients that fail independently; v1.16 set per-platform separation precedent |
| DMs, Spaces, Communities, threaded conversation view | Out of dashboard scope and out of Basic-tier API scope |
| Engagement-metric badges (RT count, like count) | Visual noise; doesn't help "what did this account say recently" |
| In-page OAuth re-connect / scope-upgrade flow | Redirect to standard `/users/auth/twitter` is sufficient for revoked-token recovery |
| Mute words, content warnings, sentiment scoring | Users self-curate by account selection |
| Dropping the `users.name` UNIQUE INDEX | Identity-touching; deferred alongside the `from_omniauth` lookup fix |
| Three new `twitter_*` columns (Option 2 from Q8) | Q8=1: reuse existing `users.{provider, uid, token}` + add only `token_secret`. Dead-column cleanup is a separate task |

---

## Traceability

Populated by the roadmapper after phase decomposition.

| Requirement | Phase | Status |
|---|---|---|
| XAUTH-01 | 60 | Pending |
| XAUTH-02 | 60 | Pending |
| XAUTH-03 | 60 | Pending |
| XAUTH-04 | 60 | Pending |
| XAPI-01 | 61 | Pending |
| XAPI-02 | 61 | Pending |
| XAPI-03 | 61 | Pending |
| XAPI-04 | 61 | Pending |
| XAPI-05 | 61 | Pending |
| XACCT-01 | 62 | Pending |
| XACCT-02 | 62 | Pending |
| XACCT-03 | 62 | Pending |
| XACCT-04 | 62 | Pending |
| XACCT-05 | 62 | Pending |
| XACCT-06 | 62 | Pending |
| XACCT-07 | 62 | Pending |
| XACCT-08 | 62 | Pending |
| XGAD-01 | 63 | Pending |
| XGAD-02 | 63 | Pending |
| XGAD-03 | 63 | Pending |
| XGAD-04 | 63 | Pending |
| XGAD-05 | 63 | Pending |
| XI18N-01 | 63 | Pending |
| XI18N-02 | 63 | Pending |
| XI18N-03 | 63 | Pending |
| XTEST-01 | 60 | Pending |
| XTEST-02 | 61 | Pending |
| XTEST-03 | 62 | Pending |
| XTEST-04 | 63 | Pending |
| XTEST-05 | 63 | Pending |
| XTEST-06 | 63 | Pending |

**Coverage:**
- v1.18 requirements: **31 total** (XAUTH: 4 / XAPI: 5 / XACCT: 8 / XGAD: 5 / XI18N: 3 / XTEST: 6)
- Mapped to phases: 31
- Unmapped: 0 ✓

---

*Requirements defined: 2026-05-14*
*Last updated: 2026-05-14 after v1.18 roadmap creation (phases 60–63, 100% coverage)*
