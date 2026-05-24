# Development

<!-- gsd-generated: docs-update 2026-05-25 -->

## Daily workflow

```bash
bin/rails s                    # Puma on PORT (default 3000)
bin/rails console              # Rails console
bin/rails routes | grep notes  # Inspect routing
```

After schema changes:

```bash
bin/rails db:migrate
bin/rails db:test:prepare
```

## Code layout

| Path | Contents |
|------|----------|
| `app/controllers/` | HTTP layer, Devise extensions, admin |
| `app/models/` | ActiveRecord, gadgets, concerns |
| `app/services/` | `MastodonClient`, `XClient` |
| `app/views/` | ERB templates and partials |
| `app/assets/javascripts/` | jQuery modules (ESLint + Prettier) |
| `app/assets/stylesheets/` | SCSS; themes in `themes/` |
| `config/locales/` | `ja.yml` / `en.yml` (keep in parity) |
| `features/` | Cucumber scenarios (Japanese) |
| `test/` | Minitest |

## Conventions

- Default locale: Japanese; bilingual UI via Rails I18n.
- JavaScript: `const`/`let`, IIFE or `$(function(){})`, no ES modules (Sprockets `//= require`).
- Do not add `dependent: :destroy` or `dependent: :delete_all` on associations — enforced by `test/models/active_record_dependent_contract_test.rb`.
- Cucumber preference changes: use the `/preferences` UI in steps, not direct ActiveRecord writes (avoids cross-connection leakage).

Detailed style notes: `.planning/codebase/CONVENTIONS.md` (agent-maintained codebase map).

## JavaScript / CSS

```bash
yarn run lint        # ESLint on app/assets/javascripts/**/*.js
yarn run lint:fix
yarn run format      # Prettier
```

CSS contract tests live in `test/assets/*_contract_test.rb`.

## Agent / project docs

- `CLAUDE.md` — test commands and phase verification policy for AI assistants.
- `.planning/codebase/` — deeper architecture, stack, and integration notes from codebase mapping.

## Related

- [Testing](TESTING.md)
- [Configuration](CONFIGURATION.md)
- [Architecture](ARCHITECTURE.md)
