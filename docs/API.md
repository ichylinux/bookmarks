# HTTP API / Routes

<!-- gsd-generated: docs-update 2026-11-26 -->

This app is server-rendered HTML, not a JSON API. Routes below are the main HTTP surface from `config/routes.rb`. All authenticated routes require a signed-in user unless noted.

## Public

| Method | Path | Controller#action | Notes |
|--------|------|-----------------|-------|
| GET | `/` | `welcome#index` | Dashboard if signed in; landing if guest |
| GET | `/privacy` | `pages#privacy` | Privacy policy |
| GET | `/terms` | `pages#terms` | Terms of service |
| GET | `/up` | `rails/health#show` | Health check |

Devise routes under `/users/*` (sessions, registration, passwords, OmniAuth callbacks).

## User resources

| Resource | Paths | Notes |
|----------|-------|-------|
| `bookmarks` | CRUD + `GET /bookmarks/fetch_title`, `GET /bookmarks/gadget` | Folder tree; `gadget` returns the bookmark gadget fragment (404 when `use_bookmark` is off) |
| `feeds` | CRUD + `GET /feeds/fetch_title` | RSS gadgets; `GET /feeds/:id` returns the gadget body; XHR `update` (settings dialog) returns `200` |
| `todos` | CRUD + `POST /todos/complete`, `PATCH /todos/:id/toggle_highlight`, `PATCH /todos/:id/toggle_done` | Bulk complete; per-row toggles |
| `notes` | `GET /notes`, `create`, `update`, `destroy` | Standalone notes page (404 when `use_note` is off); XHR create/update return the `_note_item` partial. Legacy `/?tab=notes` redirects to `/notes` |
| `preferences` | `index`, `update` | Nested preference attrs |
| `mastodon_accounts` | Full CRUD | Management + gadget preview; XHR `update` (settings dialog) returns `200` |
| `x_accounts` | `index`, `show`, `update` + `POST refresh`, `lookup_and_add` | Cached X accounts |
| `visited_links` | `POST /visited_links`, `POST /visited_links/toggle_like` | Both return `204`. `create` records a visit (`url`, optional `title`, `source` = `feed`/`x`/`mastodon`, `gadget_id`). `toggle_like` requires a history `source` (else `422`) and returns the new state in the `X-Entry-Liked: 1\|0` header |
| `feed_article_histories` | `GET /feed_article_histories` | Reading history (404 when `use_feed_article_histories` is off). Params: `page`, `liked=1` (liked only) |
| `calendars` | `GET /calendars/get_gadget` | Calendar gadget fragment |
| `welcome` | `POST /welcome/save_state` | Portal drag state |

## Account & security

| Method | Path | Purpose |
|--------|------|---------|
| GET/POST | `/users/two_factor_authentication` | 2FA challenge |
| GET/POST/DELETE | `/users/two_factor_setup` | Enable/disable TOTP |
| GET/POST | `/users/email_registration` | X users: register real email |
| POST | `/users/mastodon_instance` | Pick a Mastodon instance before Mastodon OAuth (unauthenticated); renders an auto-submitting POST to `/users/auth/mastodon` |
| GET | `/account_deletion/new` | Account deletion confirmation form |
| DELETE | `/account_deletion` | Soft-delete account (`users/account_deletions#destroy`) |
| DELETE | `/oauth_identities/:provider` | Disconnect OAuth or form auth |

## Admin (`current_user.admin?`)

| Resource | Actions |
|----------|---------|
| `/admin/users` | `index`, `destroy`, `confirm_purge` (member) |
| `/admin/x_api_usages` | `index` — API usage report |

## Inspect routes

```bash
bin/rails routes
bin/rails routes -g oauth
```
