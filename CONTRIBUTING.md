<!-- generated-by: gsd-doc-writer -->
# Contributing

Thank you for your interest in contributing to Bookmarks. This project is released under the [MIT License](LICENSE).

## Development setup

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for prerequisites and first-run instructions, and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for local development setup.

## Coding standards

- **Ruby:** Follow Rails conventions with two-space indentation.
- **JavaScript:** ESLint + Prettier are enforced. Run `yarn run lint` to check and `yarn run lint:fix` to auto-fix. Config: `eslint.config.mjs`.
- **Locales:** All user-facing strings must be added to both `config/locales/ja.yml` and `config/locales/en.yml`. The `test/i18n/locales_parity_test.rb` test must pass.
- **ActiveRecord:** Do not add `dependent: :destroy` or `dependent: :delete_all` to ActiveRecord associations without explicit discussion.

## PR guidelines

- Fork the repository and create a branch from `master`.
- Keep changes focused — one feature or fix per PR.
- Add or update tests wherever behavior changes. All three test suites must pass before opening a PR:

  ```bash
  yarn run lint && bin/rails test && bundle exec rake dad:test
  ```

  Note: the Cucumber suite runs via the custom rake task `bundle exec rake dad:test`, which spawns a Rails server and headless Chrome automatically. Do not invoke `bundle exec cucumber` directly.

- Describe what changed and why in the PR description.
- Reference any related issues in the PR body.

## Reporting issues

Open a GitHub issue at [github.com/ichylinux/bookmarks/issues](https://github.com/ichylinux/bookmarks/issues) and include:

- Steps to reproduce the problem
- Expected behavior and actual behavior
- Environment details: Ruby version, Node.js version, MySQL version, and OS
