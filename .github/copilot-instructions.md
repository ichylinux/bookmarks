# Copilot instructions for Bookmarks

## Build, test, and lint commands

This is a Rails 8.1 / Ruby 3.4 app with Sprockets-managed JavaScript and MySQL. Install dependencies with:

```bash
bundle install
yarn install
```

Database setup uses environment variables from `config/database.yml` (`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`):

```bash
bundle exec rake dad:db:create
bin/rails db:reset
```

Primary checks:

```bash
yarn run lint
bin/rails test
bundle exec rake dad:test
```

Full local check:

```bash
yarn run lint && bin/rails test && bundle exec rake dad:test
```

Single/smaller runs:

```bash
bin/rails test test/models/feed_test.rb
bin/rails test test/controllers/bookmarks_controller_test.rb:80
bin/rails test test/controllers/bookmarks_controller_test.rb --name=/一覧/
bundle exec rake dad:test features/02.タスク.feature
```

Use `bundle exec rake dad:test` for Cucumber acceptance tests; it starts the Rails server and headless Chrome through the project’s custom rake task. Do not use `bundle exec cucumber` directly for normal verification. If `dad:test` fails with symptoms matching known scenario-order state leakage, rerun once; a repeatable failure across two runs is a real regression.

JavaScript tooling:

```bash
yarn run lint
yarn run lint:fix
yarn run format
```

## High-level architecture

- The application is a personal portal combining bookmarks, RSS feeds, ToDos, calendars, notes, authentication, preferences, and themes. Most authenticated pages inherit `ApplicationController`, which applies Devise authentication and wraps requests in locale selection through `Localization`.
- The portal home is `WelcomeController#index`. It loads the current user’s first non-deleted `Portal`, a new `Note`, and recent notes. `Portal#portal_columns` composes the three-column dashboard by combining persisted `PortalLayout` rows with visible gadgets from bookmarks, ToDos, calendars, and feeds.
- Domain logic is model-heavy. Controllers are mostly CRUD orchestration: preload a record, authorize it with `readable_by?`, mutate with `save!` or `destroy_logically!`, and redirect/render. There are no service-object conventions in the current codebase.
- Ownership authorization is centralized in `Crud::ByUser` (`app/models/crud/by_user.rb`) and included by user-owned resources such as `Bookmark`, `Feed`, and `Todo`. Controllers return `404 Not Found` for records owned by other users.
- Soft deletion is represented by a `deleted` boolean and `destroy_logically!`; normal queries and associations use `not_deleted` or `deleted: false` rather than hard deletes.
- Preferences drive visible UI behavior: theme (`modern`, `classic`, `simple`), font size class, optional ToDo/Note widgets, default ToDo priority, link target behavior, and saved locale. `User#preference` returns an unsaved default from `Preference.default_preference(self)` when no row exists.
- The frontend is classic Rails/Sprockets: `app/assets/javascripts/application.js` requires `rails-ujs`, Active Storage, jQuery, jQuery UI, then `require_tree .`; styles are SCSS under `app/assets/stylesheets`, with theme-specific files under `themes/`. There is no SPA framework.
- Internationalization is first-class. The layout sets `<html lang="<%= I18n.locale %>">`; `Localization` prefers the user’s saved preference locale, then `Accept-Language`, then the default locale. Tests assert both Japanese and English UI strings.

## Key conventions

- Ruby code follows Rails defaults without RuboCop. Existing code uses two-space indentation, simple single-quoted strings where practical, Japanese comments where clarification is useful, and Japanese Minitest method names such as `test_一覧`.
- Keep business rules close to models. Existing patterns use constants modules or model constants, model scopes, model-level factory/default methods, and small controller private methods for strong parameters.
- For user-owned resources, include/reuse `Crud::ByUser` authorization predicates and check authorization in `preload_<resource>` before controller actions. Unauthorized access should match existing behavior with `head :not_found`.
- Prefer logical deletion for resources that already use it; use existing `not_deleted` scopes or `deleted: false` filters and avoid introducing hard deletes into those flows.
- Views use classic ERB patterns: `form_for`, shared `_form.html.erb` partials, table-based form layout, `link_to` blocks for icon/label links, inline conditional classes, Rails UJS `data-confirm`, and `.js.erb` responses for AJAX updates.
- JavaScript under `app/assets/javascripts/**/*.js` assumes jQuery and is linted by ESLint 9 flat config. Use `function` callbacks when `this` is the DOM element (`$(this)`, `.each`, event handlers) and arrow functions only where `this` is not used.
- Shared browser globals should follow the existing namespace style, e.g. `window.todos = window.todos || {}; const todos = window.todos;`. Do not introduce unnecessary new global names or reassign existing namespace objects.
- Cucumber features and step definitions are Japanese (`# language: ja`). Acceptance tests rely on the `daddy/cucumber/rails` and `closer` stack through `dad:test`.
- Minitest fixtures are loaded globally in `test/test_helper.rb`, and support helpers from `test/support/*.rb` are evaluated into `ActiveSupport::TestCase`. Integration tests include Devise’s `sign_in` helpers.
- `daddy` is a project-specific dependency that supplies Rails/test/Cucumber helpers and rake tasks. Check existing usages before replacing those flows with stock Rails equivalents.
