<!-- generated-by: gsd-doc-writer -->
# Contributing

Thank you for your interest in contributing to Bookmarks. This project is released under the [MIT License](LICENSE).

## Development setup

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for prerequisites and first-run instructions, and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for local development setup.

## Coding standards

- **Ruby:** Follow Rails conventions with two-space indentation. There is no RuboCop config.
- **JavaScript:** ESLint 9 (`eslint.config.mjs`) and Prettier 3 (`.prettierrc.json`). Run `yarn run lint` to check, `yarn run lint:fix` to auto-fix, and `yarn run format` to format. Jenkins does not run ESLint — lint must pass locally before you open a PR.
- **Locales:** All user-facing strings must be added to both `config/locales/ja.yml` and `config/locales/en.yml`. The `test/i18n/locales_parity_test.rb` test must pass.
- **ActiveRecord:** Do not add `dependent: :destroy` or `dependent: :delete_all` to ActiveRecord associations. This is enforced by `test/models/active_record_dependent_contract_test.rb`.

Further style rules (SCSS theme isolation, Japanese test method names, IIFE modules) are in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## PR guidelines

- Fork the repository and create a branch from `master` (the default branch). There is no required branch-name prefix; descriptive names such as `feat/my-feature` or `fix/issue-description` are encouraged.
- Keep changes focused — one feature or fix per PR.
- Add or update tests wherever behavior changes. All three suites must pass before opening a PR:

  ```bash
  yarn run lint && bin/rails test && bundle exec rake dad:test
  ```

  The Cucumber suite runs via `bundle exec rake dad:test`, which spawns a Rails server and headless Chrome automatically. Do not invoke `bundle exec cucumber` directly. Scoped commands and helpers are in [docs/TESTING.md](docs/TESTING.md).

  Jenkins (`Jenkinsfile`) runs Minitest, then triggers `Jenkinsfile.features` for Cucumber. It does not run `yarn run lint`.

- Describe what changed and why in the PR description.
- Reference any related issues in the PR body.

## Reporting issues

Open a GitHub issue at [github.com/ichylinux/bookmarks/issues](https://github.com/ichylinux/bookmarks/issues) and include:

- Steps to reproduce the problem
- Expected behavior and actual behavior
- Environment details: Ruby version, Node.js version, MySQL version, and OS

There are no GitHub issue templates. For security vulnerabilities, do not open a public issue — follow [SECURITY.md](SECURITY.md) instead.
