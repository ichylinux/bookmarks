# HTTP API / Routes

<!-- gsd-generated: docs-update 2026-05-25 -->

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
| `bookmarks` | CRUD + `GET /bookmarks/fetch_title` | Folder tree |
| `feeds` | CRUD + `GET /feeds/fetch_title` | RSS gadgets |
| `todos` | CRUD + `POST /todos/complete` | Bulk complete |
| `notes` | `create`, `update`, `destroy` + `GET /notes/gadget` | AJAX gadget HTML |
| `preferences` | `index`, `update` | Nested preference attrs |
| `mastodon_accounts` | Full CRUD | Management + gadget preview |
| `x_accounts` | `index`, `show`, `update` + `POST refresh`, `lookup_and_add` | Cached X accounts |
| `visited_links` | `POST create` | 204 — visited URL tracking |
| `calendars` | `GET /calendars/get_gadget` | Calendar gadget fragment |
| `welcome` | `POST /welcome/save_state` | Portal drag state |

## Account & security

| Method | Path | Purpose |
|--------|------|---------|
| GET/POST | `/users/two_factor_authentication` | 2FA challenge |
| GET/POST/DELETE | `/users/two_factor_setup` | Enable/disable TOTP |
| GET/POST | `/users/email_registration` | X users: register real email |
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
