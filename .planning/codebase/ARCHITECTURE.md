# Architecture

**Analysis Date:** 2026-11-26

## System Overview

A single Rails 8.1 monolith serving a personal "portal" page: a drag-and-drop grid of **gadgets** (bookmarks, todos, calendar, RSS feeds, Mastodon accounts, X accounts) plus standalone pages for notes, reading history, preferences and admin.

```text
Browser ── jQuery / jQuery UI, IIFE modules, rails-ujs
   │  full-page GET + XHR (gadget bodies, settings dialogs, visit/like beacons, layout save)
   ▼
Rails controllers ─ ApplicationController (authenticate_user!, Localization, font-size notice)
   ├─ WelcomeController            /  landing (guest) or portal dashboard; POST save_state
   ├─ Bookmarks / Todos / Feeds / MastodonAccounts / XAccounts   CRUD + gadget XHR endpoints
   ├─ NotesController              /notes  standalone page (was a welcome tab)
   ├─ VisitedLinksController       POST /visited_links, POST /visited_links/toggle_like
   ├─ FeedArticleHistoriesController /feed_article_histories  reading history (paginated, "liked" filter)
   ├─ PreferencesController        /preferences  section-card settings page
   ├─ OauthIdentitiesController    DELETE /oauth_identities/:provider
   ├─ PagesController              /privacy, /terms
   ├─ Admin::BaseController → Admin::UsersController, Admin::XApiUsagesController
   └─ Users::* (Devise extensions: sessions+2FA, 2FA setup, OmniAuth callbacks,
                email registration, Mastodon instance picker, account deletion)
   ▼
Models ─ User, Preference, Portal, PortalLayout, OauthIdentity
         Bookmark (acts_as_tree), Todo, Note, Feed, MastodonAccount, XAccount
         VisitedLink (visits + likes), XApiCall (API metering)
         Gadget objects: BookmarkGadget, TodoGadget, CalendarGadget
   ▼
Services ─ XClient, MastodonClient, MastodonHandleNormalizer, MastodonInstanceNormalizer
           + lib/omniauth/strategies/mastodon.rb
   ▼
MySQL · X API · Mastodon instances · RSS feeds · AWS SES
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `ApplicationController` | Global auth gate, `assign_entry_link_states(urls)` (sets `@visited_urls` / `@liked_urls`), one-shot font-size notice | `app/controllers/application_controller.rb` |
| `Localization` | `around_action` locale: preference → `Accept-Language` → `:ja` | `app/controllers/concerns/localization.rb` |
| `TwitterLinkRequirement` | Blocks X routes unless `current_user.twitter_linked?` | `app/controllers/concerns/twitter_link_requirement.rb` |
| `Admin::BaseController` | `require_admin` → `head :not_found` for non-admins | `app/controllers/admin/base_controller.rb` |
| `Portal` | Builds gadget map from preferences + DB, distributes into N columns using `PortalLayout`; `update_layout` persists drag-drop | `app/models/portal.rb` |
| `Preference` | Theme, font size, locale, column count (3/4) and widths, feature flags (`use_bookmark`, `use_todo`, `use_calendar`, `use_note`, `use_feed_article_histories`, `show_icons`, `open_links_in_new_tab`, …) | `app/models/preference.rb` |
| `User` | Devise config, `from_omniauth`, auth-method disconnect with optimistic locking, account soft-delete (`destroy_account!`) and hard purge (`purge!`) | `app/models/user.rb` |
| `OauthIdentity` | One row per (user, provider); `(provider, uid)` unique; `upsert_for!` raises `UidOwnedByAnotherUserError` | `app/models/oauth_identity.rb` |
| `VisitedLink` | Per-user URL visit log; `record!`, `toggle_like!`, `link_state_for`, `gadget_titles_for`; sources `feed`/`x`/`mastodon` | `app/models/visited_link.rb` |
| `XApiCall` | Append-only X API call log; `usage_summary`, `usage_by_day` | `app/models/x_api_call.rb` |
| `XClient` / `MastodonClient` | External HTTP, result hashes, never raise | `app/services/` |

## Patterns

- **Auth everywhere:** `before_action :authenticate_user!` globally; skipped only for `WelcomeController#index`, 2FA verification and `Users::MastodonInstancesController#create`.
- **Ownership → 404:** `preload_*` before_actions call `readable_by?(current_user)` (`Crud::ByUser`) or scope through `current_user.<assoc>`; failures return `head :not_found`. Feature-flagged pages also 404 when the flag is off (`NotesController#index`, `FeedArticleHistoriesController#index`, `BookmarksController#gadget`).
- **Soft delete:** `deleted` boolean + `not_deleted` scope + `destroy_logically!` from `daddy` on Bookmark, Todo, Feed, Note, Portal, MastodonAccount, XAccount. Users: `destroy_account!` sets `deleted`/`deleted_at`; `User.active` excludes them and `active_for_authentication?` blocks login. After 90 days an admin may `purge!` (hard `delete_all` across every user-owned table, in one transaction).
- **Lazy preference:** `User#preference` returns an unsaved `Preference.default_preference(user)` when no row exists.
- **Gadget protocol:** any portal item responds to `gadget_id` (string, e.g. `feed_12`, `x_account_3`, `mastodon_account_5`, `bookmark_gadget`), `title`, `entries`, optionally `visible?`. `Gadget` concern supplies defaults; Feed / MastodonAccount / XAccount implement it directly.
- **Service result hash:** `{ success: true, items: [...] }` / `{ success: false, error: :symbol }`; controllers map errors to `t("errors.x_client.#{error}")` flashes.

## Data Flows

### Portal render
1. `GET /` → `WelcomeController#index`. Guest → landing (`_landing`). Signed-in → `@portal = current_user.portals.first` (`?tab=notes` redirects to `/notes`).
2. `Portal#portal_columns` → gadgets in column / display order.
3. `welcome/_dashboard` → `_portal_column_section` → per-gadget partial.
4. Remote-data gadgets (feed, X, Mastodon) render a shell plus an inline script calling `window.portalLazy.register(col, fn)`. Desktop loads immediately; on mobile only the active column loads, others on tab switch (`portal_lazy.js`, `portal_mobile_tabs.js`). The body is fetched with `$.get(<resource>_path, {format: 'html'})` → `feeds#show`, `x_accounts#show`, `mastodon_accounts#show`, which call `assign_entry_link_states` so entries render visited / liked state.

### Gadget settings dialog
`gadget_header_settings.js`: header link on feed / X / Mastodon gadgets opens an inline settings form (`feeds/_settings_dialog`, `x_accounts/_settings_dialog`, `mastodon_accounts/_settings_dialog`); the form submits via rails-ujs (`remote: true`, handled on `ajax:success` / `ajax:error`) → `update` returns `head :ok` for XHR; then the gadget body is re-fetched and, for feeds, the new title is applied to the header immediately without waiting for the RSS reload.

### Visits, likes and reading history
1. `visited_links.js` delegates clicks on `.gadget … ol li a[href]` (excluding bookmark / todo gadgets), adds `link--visited` instantly, then POSTs `/visited_links` with `url, title, source, gadget_id`.
2. Like button (`common/_entry_like_button`, shown only when `use_feed_article_histories` is on) → `POST /visited_links/toggle_like`; response header `X-Entry-Liked: 1|0`.
3. If the page has no `meta[name=bookmarks-session-active]` (session expired) or any POST fails, the payload is queued in `localStorage` (`bookmarksPendingVisitedLinks`) and replayed on the next page load with an active session.
4. `VisitedLink.record!` upserts on `(user_id, url)` (URL fragment stripped), keeps `liked_at`, validates `gadget_id` belongs to the user.
5. `/feed_article_histories` lists `VisitedLink.feed_history_for(user)` (Kaminari, `?liked=1` filter) with source icon, gadget name, `visited_at`; pager top and bottom.

### Layout save
jQuery UI sortable (`portal_gadget_sort.js`) → `POST /welcome/save_state` with `portal[column_N][]=gadget_id` → `Portal#update_layout` in a transaction → `head :ok`. Column widths are set by `portal_column_width_sliders.js` (saved to `preferences.portal_column_widths`, JSON).

### Sign-in
- Password: `Users::SessionsController#create` → if `otp_required_for_login`, stash `session[:otp_user_id]` → `/users/two_factor_authentication` verify.
- OmniAuth: see INTEGRATIONS.md; signs in directly.

### Account lifecycle
- Self-delete: `/account_deletion/new`, type `DELETE` → `destroy_account!` + sign-out.
- Admin purge: `/admin/users/:id/confirm_purge` → `DELETE /admin/users/:id` (only if `purgeable?`).

## Constraints

- **Route guard:** `devise_for` and user routes are skipped when `ARGV.first =~ /^dad:setup/` so Docker image builds don't load `User` (`config/routes.rb`).
- **Mastodon strategy load order:** required explicitly in `config/application.rb`, and `Dockerfile.base` copies `lib/omniauth` before `dad:setup:base`.
- **`XApiCall.record!` outside transactions**, so the log survives rollbacks (comment in model).
- **No background jobs:** all external fetches run in the request (XHR) thread.
- **Global state:** only `Rails.application.config.app_config` (read at boot).

## Anti-Patterns to Avoid

- Calling `.update!` / `.id` on `user.preference` without checking `persisted?` (see `PreferencesController#index` for `build_preference`).
- Adding an admin controller that doesn't inherit `Admin::BaseController`.
- Adding a user-owned table without adding it to `User#purge!` — `test/models/active_record_dependent_contract_test.rb` and `user_purge_test.rb` guard this.
- `find(params[:id])` without an ownership check.
- Wrapping `XApiCall.record!` inside the caller's transaction.

---

*Architecture analysis: 2026-11-26*
