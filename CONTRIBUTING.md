<!-- generated-by: gsd-doc-writer -->
# Contributing

Thank you for your interest in contributing to Bookmarks. This project is released under the [MIT License](LICENSE).

## Development setup

See [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for prerequisites and first-run instructions, and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for local development setup, build commands, and day-to-day workflow.

## Coding standards

- **Ruby:** Follow Rails conventions with two-space indentation. There is no RuboCop config.
- **JavaScript:** ESLint 9 (`eslint.config.mjs`) and Prettier 3 (`.prettierrc.json`). Run `yarn run lint` to check, `yarn run lint:fix` to auto-fix, and `yarn run format` to format. Jenkins does not run ESLint — lint must pass locally before you open a PR.
- **SCSS:** Shared stylesheets must not contain theme-specific selectors (`.modern`, `.classic`, `.simple`); theme overrides belong in `app/assets/stylesheets/themes/`. Do not gate styles on hover/pointer media features — use viewport width instead. Contract tests in `test/assets/` enforce these rules.
- **Locales:** All user-facing strings must be added to both `config/locales/ja.yml` and `config/locales/en.yml`. The `test/i18n/locales_parity_test.rb` test must pass.
- **ActiveRecord:** Do not add `dependent: :destroy` or `dependent: :delete_all` to ActiveRecord associations. This is enforced by `test/models/active_record_dependent_contract_test.rb`.

Further style rules (Japanese test method names, IIFE modules, Cucumber conventions) are in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## PR guidelines

- Fork the repository and create a branch from `master` (the default branch). There is no required branch-name prefix; descriptive names such as `feat/my-feature` or `fix/issue-description` are encouraged.
- Keep changes focused — one feature or fix per PR.
- Add or update tests wherever behavior changes. Before opening a PR, all three suites must pass for the tests related to your change:

  ```bash
  yarn run lint                                              # always run in full (fast; Jenkins does not run lint)
  bin/rails test test/models/user_test.rb                    # scoped Minitest example
  bundle exec rake dad:test features/02.タスク.feature        # scoped Cucumber example
  ```

  Run `yarn run lint` in full. Scope Minitest and Cucumber to the files and features affected by your change — full-suite runs are slow, and Jenkins (`Jenkinsfile` + `Jenkinsfile.features`) runs the complete Minitest and Cucumber suites as the safety net. State which tests you ran and why in the PR description.

  The Cucumber suite runs via `bundle exec rake dad:test`, which spawns a Rails server and headless Chrome automatically. Do not invoke `bundle exec cucumber` directly. Scoped commands and helpers are in [docs/TESTING.md](docs/TESTING.md).

  **Cucumber preference changes** must use the `/preferences` UI in step definitions, not direct ActiveRecord writes — this prevents cross-connection state leakage between scenarios.

- Describe what changed and why in the PR description.
- Reference any related issues in the PR body.

### Security fixes

Follow the normal PR process above, but if your fix would disclose an unreported vulnerability, contact the maintainer privately first rather than opening a public pull request. See [SECURITY.md](SECURITY.md) for reporting channels and scope.

## Reporting issues

Open a GitHub issue at [github.com/ichylinux/bookmarks/issues](https://github.com/ichylinux/bookmarks/issues) and include:

- Steps to reproduce the problem
- Expected behavior and actual behavior
- Environment details: Ruby version, Node.js version, MySQL version, and OS

There are no GitHub issue templates. For security vulnerabilities, do not open a public issue — follow [SECURITY.md](SECURITY.md) instead.

## Related docs

| Document | Contents |
|---|---|
| [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) | First-time setup |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Development workflow and code style |
| [docs/TESTING.md](docs/TESTING.md) | Running and writing tests |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and component overview |
| [docs/CONFIGURATION.md](docs/CONFIGURATION.md) | Environment variables and settings |
| [SECURITY.md](SECURITY.md) | Security policy and vulnerability reporting |
