# Coding Conventions

**Analysis Date:** 2026-11-26

## Language

- **Default locale `ja`**, with `en` as the second locale. Per-user `Preference#locale` (`nil` = auto). All UI strings go in `config/locales/ja.yml` **and** `en.yml`; parity is enforced by `test/i18n/locales_parity_test.rb`.
- Japanese appears throughout the source: commit messages, many code comments (e.g. `gadget_header_settings.js`, `portal_gadget_sort.js`), domain test names (`def test_一覧`), fixture data, Cucumber features and steps, and rake task messages (`lib/tasks/users.rake`).
- English is used for technical / regression test names (`test 'uses iife wrapper not document ready'`, `def test_index_success`) and many architectural comments.
- The guest landing page contains a dated **changelog** ("新着情報") that is updated with user-visible changes; `test/i18n/changelog_i18n_test.rb` covers it.

## Ruby

- Two-space indent; no RuboCop config; `# frozen_string_literal: true` only in a couple of files (e.g. `admin/users_controller.rb`, `lib/tasks/users.rake`). Not required.
- Constants `SCREAMING_SNAKE_CASE`, often frozen collections (`HISTORY_SOURCES = %w[feed x mastodon].freeze`, `MAX_SELECTION = 12`).
- Scopes use stabby lambdas. Class-level operations are `self.<verb>!` methods on the model (`VisitedLink.record!`, `XApiCall.record!`, `OauthIdentity.upsert_for!`, `XAccount.refresh_cache_from_items!`).
- Domain errors are nested classes: `User::NotPurgeableError`, `User::LastAuthMethodError`, `OauthIdentity::UidOwnedByAnotherUserError`.
- Private class methods are declared with `private_class_method`.
- Requirement IDs from planning docs sometimes appear in comments (`# OAUTH-01`, `# ARCH-01`, `# MOB-01`).

## Models

- Inherit `ApplicationRecord`. User-owned models `include Crud::ByUser`.
- **Soft delete** (`deleted` + `not_deleted` + `destroy_logically!` from `daddy`) for user content; `User.active` for users.
- **No `dependent:` on associations** (contract test). Physical deletion happens only in `User#purge!`, which lists every user-owned table explicitly.
- New boolean columns: `default: false, null: false`; defaults that matter to the UI also go in `Preference.default_preference`.
- Optimistic locking uses an explicit `lock_version` comparison with `update_all` (see `User#disconnect_oauth!`), not AR's automatic locking.
- Concurrency-safe upserts: rescue `ActiveRecord::RecordNotUnique` and retry once (`OauthIdentity.upsert_for!`), or use `upsert` on a unique index (`VisitedLink.record!` on `(user_id, url)`).

## Controllers

- Global `authenticate_user!`; opt out with `skip_before_action` only for public entry points.
- `before_action :preload_<resource>` performs ownership checks → `head :not_found` (never 403). Admin: inherit `Admin::BaseController` (404 for non-admins).
- Feature-flagged screens: `head :not_found and return unless current_user.preference.use_<flag>?`.
- Dual HTML / XHR responses: `if request.xhr?` → partial with `layout: false` / `head :ok|:no_content` / `render plain: msg, status: :unprocessable_entity`; else redirect with flash.
- Flash text always via `t(...)`; service errors map to `t("errors.x_client.#{result[:error]}")`.
- Pagination: `scope.page([params[:page].to_i, 1].max)` (Kaminari, 25 per page).
- Gadget entry endpoints call `assign_entry_link_states(urls)` before rendering.
- X API calls are followed by `record_x_api_call(endpoint:, result:)`.

## Services

- `app/services/`, plain Ruby. Public methods return `{ success: true, … }` / `{ success: false, error: :symbol }` and rescue Faraday errors internally.
- Constructor accepts `connection:` for test injection. Constants for timeouts (`CONNECT_TIMEOUT = 3`, `READ_TIMEOUT = 5`).
- Normalizers (`MastodonHandleNormalizer`, `MastodonInstanceNormalizer`) return a result object with `success?`, the value, and `error_key` (an i18n key suffix).

## JavaScript

- No ES modules; Sprockets `require_tree .` loads every file in alphabetical order. Shared state goes through `window.<namespace>` (`window.portalLazy`, `window.portalMobileTabs`).
- **Preferred:** IIFE `(function () { … })();` with namespaced delegated events (`$(document).on('click.visitedLinks', selector, …)`). Some files still use `$(document).ready` / `$(function …)` (`gadget_header_settings.js`, `menu.js`, …).
- `const` / `let` preferred. ESLint only applies `@eslint/js` recommended with no custom rules, so `var` is **not** blocked (`note_gadget.js` still has some).
- `localStorage` access is always wrapped in `try / catch`.
- Server-rendered `data-*` attributes carry ids and URLs to JS (`data-gadget-id`, `data-gadget-url`, `data-gadget-dom-prefix`).
- Lint: `yarn run lint` / `yarn run lint:fix`. Prettier has been removed; there is no formatter.

## CSS / SCSS

- One `snake_case.css.scss` per screen; theme overrides only in `themes/<theme>.css.scss` (shared partials `_drawer_shared.scss`, `_notes_shared.scss`).
- Non-theme files must not contain `.modern`, `.classic` or `.simple` selectors (`test/assets/css_architecture_contract_test.rb`).
- Shared mobile rules (`@media (max-width: 767px)`) for shared components live in `common.css.scss` (`mobile_responsive_contract_test.rb`).
- Class names are kebab-case, with BEM-ish modifiers in newer code (`title--gadget-with-icon`, `link--visited`, `feed-settings-dialog__form`).
- Body classes set theme and font size (layout `application.html.erb`); three themes: `modern` (default), `simple`, `classic`.

## Views

- Shared partials in `common/`; SVG icons as partials in `icons/` (`render 'icons/like'`).
- Remote-data gadgets render a shell plus an inline `window.portalLazy.register(...)` script.
- User content (titles, notes) is never translated.

## Tests

See TESTING.md. When changing a JS or CSS file, look for a matching `test/assets/*_contract_test.rb`. These tests assert on source text, so renaming selectors or functions can break them.

## Git / Workflow

- Commit subjects are mostly Japanese, describing user-visible behavior; `chore:`, `docs:` and `fix:` prefixes appear occasionally.
- Work is planned in `.planning/` (ROADMAP / STATE / milestones). The phase gate is lint, related Minitest and related Cucumber all green (see `CLAUDE.md`).

---

*Convention analysis: 2026-11-26*
