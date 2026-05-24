# Architecture

<!-- gsd-generated: docs-update 2026-05-25 -->

Bookmarks is a Rails 8.1 MVC application: authenticated users manage bookmarks, feeds, todos, notes, and portal gadgets on a customizable dashboard. Guests see a landing page at `/`.

## System overview

```text
Browser (jQuery, SCSS, Sprockets)
        │ HTTP
        ▼
Rails controllers (Devise auth, Localization)
        │
        ├── Models (ActiveRecord, soft-delete via daddy gem)
        ├── Services (MastodonClient, XClient — Faraday)
        └── Views (ERB partials, theme SCSS)
        │
        ▼
MySQL (utf8mb4)
```

## Request flow

1. `ApplicationController` runs `authenticate_user!` (Devise) except on explicitly skipped actions.
2. `Localization` sets locale from user preference or `Accept-Language`.
3. Resource controllers delegate to models; gadget endpoints return `layout: false` HTML fragments for AJAX.
4. `WelcomeController#index` renders the portal dashboard (`Portal` assembles gadgets from `PortalLayout` rows) or inline landing for guests.

## Major components

| Area | Responsibility | Location |
|------|----------------|------------|
| Portal dashboard | Column layout, gadget ordering, drag-and-drop state | `app/models/portal.rb`, `app/controllers/welcome_controller.rb` |
| Preferences | Theme, locale, feature flags, OAuth connected accounts | `app/models/preference.rb`, `app/controllers/preferences_controller.rb` |
| Bookmarks / feeds / todos / notes | CRUD with per-user scoping | `app/controllers/*_controller.rb`, `Crud::ByUser` |
| X / Mastodon gadgets | External API fetch, cached accounts | `app/services/x_client.rb`, `app/services/mastodon_client.rb` |
| Auth | Devise, 2FA (TOTP), OmniAuth (Google, X, Facebook) | `app/controllers/users/`, `app/models/user.rb` |
| Admin | User list, hard purge, X API usage report | `app/controllers/admin/` |
| Account lifecycle | Soft delete (`destroy_account!`), 90-day hard purge (`purge!`) | `app/models/user.rb` |

## Data and deletion model

- **Soft delete:** Most user content uses the `daddy` gem pattern (`deleted` flag, `not_deleted` scope). `destroy` on models typically calls logical delete, not SQL `DELETE`.
- **Account deactivation:** `User#destroy_account!` sets `deleted` / `deleted_at` without removing child rows.
- **Hard purge:** `User#purge!` (admin-only, after 90 days) runs explicit `delete_all` per table inside a transaction, then `user.delete`. Associations intentionally omit `dependent: :destroy` / `:delete_all` so accidental `user.destroy` does not cascade.

## Gadget system

Gadgets implement the `Gadget` concern (`gadget_id`, `entries`, `visible?`). Plain Ruby classes (e.g. bookmark, todo, calendar gadgets) and account-backed gadgets (feed, Mastodon, X) plug into `Portal#get_gadgets`. Mobile lazy-loads gadget HTML via `portal_lazy.js` and per-gadget AJAX endpoints.

## External integrations

| Service | Client | Used for |
|---------|--------|----------|
| Mastodon | `MastodonClient` | Public lookup + statuses preview |
| X (Twitter) API v2 | `XClient` | Following list, recent tweets, username lookup |
| RSS/Atom | Feedjira (in `Feed` model) | Feed gadget entries |

## Theming

Three themes (`modern`, `classic`, `simple`) set `body` class from `Preference#theme`. SCSS lives under `app/assets/stylesheets/themes/`; shared rules in non-theme files (`common.css.scss`, etc.). Contract tests in `test/assets/` guard CSS architecture.

## Related docs

- [Getting started](GETTING-STARTED.md)
- [Development](DEVELOPMENT.md)
- [API routes](API.md)
- [Configuration](CONFIGURATION.md)
- [Testing](TESTING.md)
