# Contributing

<!-- gsd-generated: docs-update 2026-05-25 -->

Thank you for your interest in Bookmarks. This project is released under the [MIT License](LICENSE).

## Development setup

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Pull requests

1. Fork and create a branch from `master`.
2. Make focused changes with tests where behavior changes.
3. Run the full gate before opening a PR:

   ```bash
   yarn run lint && bin/rails test && bundle exec rake dad:test
   ```

4. Describe what changed and why in the PR body.

## Code style

- Ruby: Rails conventions, two-space indent.
- JavaScript: ESLint + Prettier (`yarn run lint`).
- Locales: update both `config/locales/ja.yml` and `en.yml`; `test/i18n/locales_parity_test.rb` must pass.
- Do not add `dependent: :destroy` or `dependent: :delete_all` on ActiveRecord associations.

## Reporting issues

Open an issue with steps to reproduce, expected vs actual behavior, and environment (Ruby, Node, MySQL versions).
