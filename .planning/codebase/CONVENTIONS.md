# Coding Conventions

**Analysis Date:** 2026-05-18

## Language Choices

**Default locale:** Japanese (`ja`). The app is bilingual (ja/en) with locale stored per-user in `Preference#locale`. All UI strings live in `config/locales/ja.yml` and `config/locales/en.yml` — parity between the two files is enforced by `test/i18n/locales_parity_test.rb`.

**Japanese in source code:**
- Controller test method names use Japanese (e.g., `def test_一覧`, `def test_登録`, `def test_削除`)
- Inline comments in models and controllers are often Japanese (e.g., `# フォルダを先に、その後ブックマークをタイトル順で表示`)
- Fixture data uses Japanese text for titles (e.g., `title: 'ブックマーク1'` in `test/fixtures/bookmarks.yml`)
- Test param helpers use Japanese strings (e.g., `title: 'ブックマーク'` in `test/support/bookmarks.rb`)
- Cucumber `.feature` files and step definitions are written entirely in Japanese (`# language: ja`, `機能:`, `シナリオ:`, `もし`, `ならば`)

## Naming Patterns

**Ruby files:**
- Classes: `PascalCase` (e.g., `BookmarksController`, `PreferenceTest`)
- Methods (Ruby/Rails): `snake_case`
- Test methods: `def test_<日本語説明>` for domain actions; `def test_<English_description>` for technical/regression tests (mixed pattern depending on context)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `PRIORITY_NORMAL`, `FONT_SIZE_MEDIUM`, `PORTAL_COLUMN_COUNTS`)
- Private helper methods in controllers: `snake_case` (e.g., `preload_bookmark`, `bookmark_params`)

**JavaScript files:**
- Files: `snake_case.js` (e.g., `portal_lazy.js`, `flash_messages.js`, `portal_mobile_tabs.js`)
- Variables/functions: `camelCase` (e.g., `closeDrawer`, `toggleDrawer`, `loadedColumns`)
- Namespaces: `window.portalLazy`, `window.portalMobileTabs` — global objects mounted on `window`
- No `var` keyword — use `const` and `let` only

**SCSS files:**
- Files: `snake_case.css.scss` for non-theme files (e.g., `bookmarks.css.scss`, `common.css.scss`)
- Theme files live under `app/assets/stylesheets/themes/` (e.g., `modern.css.scss`, `classic.css.scss`, `simple.css.scss`)
- CSS selectors: `kebab-case` class names (e.g., `.breadcrumbs-action-btn`, `.preferences-form`, `.bookmarks-table`)

## Code Style

**Ruby:**
- No `frozen_string_literal: true` pragma in app source files (only two test-support files use it: `test/support/webmock.rb`, `test/controllers/x_accounts_controller_test.rb`)
- Two-space indentation (Rails default)
- No enforced rubocop config detected (`.rubocop.yml` absent)
- Comments explaining business logic are Japanese; technical/architectural comments may be English or Japanese

**JavaScript — Prettier config** (`/.prettierrc.json`):
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5"
}
```

**JavaScript — ESLint config** (`/eslint.config.mjs`):
- Lints only `app/assets/javascripts/**/*.js`
- Parser: `@babel/eslint-parser` with `babel.config.js`
- Globals allowed: `$`, `jQuery`, `ActionCable`, `App` (browser globals + jQuery)
- Extends `eslint:recommended` + `eslint-config-prettier` (disables style rules conflicting with Prettier)
- Run with: `yarn run lint` (ESLint), `yarn run format` (Prettier write)

## Import Organization

**JavaScript:** No ES module `import` — legacy asset pipeline uses `//= require` directives in `app/assets/javascripts/application.js`. Each JS file is a self-contained IIFE or jQuery document-ready wrapper.

**Ruby:** Standard `require 'test_helper'` at top of every test file. No path aliases.

## Module / JavaScript Patterns

**Preferred module pattern:** IIFE, not jQuery document-ready, for reusable modules:
```javascript
(function() {
  window.portalLazy = window.portalLazy || {};
  const portalLazy = window.portalLazy;
  // ...
})();
```

**Legacy interactive code** (page-specific event binding) uses jQuery document-ready:
```javascript
$(function() {
  // event handlers
});
```

**No `var`** — use `const` / `let` throughout. Violations are caught by ESLint.

## CSS Architecture Rules (enforced by contract tests)

- **Non-theme SCSS files** (`bookmarks`, `calendars`, `common`, `devise`, `feeds`, `landing`, `preferences`, `todos`, `welcome`) must contain **no** `.modern`, `.classic`, or `.simple` selectors. Enforced by `test/assets/css_architecture_contract_test.rb`.
- **Theme-specific overrides** go in `app/assets/stylesheets/themes/<theme>.css.scss`.
- **Base/layout rules** (e.g., `.preferences-form input[type="submit"]`) must remain in the non-theme file so all themes inherit them.
- **Mobile rules** (`@media (max-width: 767px)`) for shared components (`.preferences-table`, `.bookmarks-table`) belong in `common.css.scss`, not theme files. Enforced by `test/assets/mobile_responsive_contract_test.rb`.

## Model Conventions

- All models inherit from `ApplicationRecord` (`app/models/application_record.rb`)
- Shared CRUD authorization extracted into concerns under `app/models/concerns/crud/` (e.g., `Crud::ByUser`)
- Scopes use stabby lambdas: `scope :folders, -> { where(url: nil) }`
- Validations: `validates :field, presence: true` + custom `validate :method_name` for complex rules
- Soft-delete pattern: `deleted` boolean column + `destroy_logically!` method + `not_deleted` scope (on `Bookmark`)
- Private section marked with `private` keyword, containing validation helpers and param-filtering methods

## Controller Conventions

- `before_action` for loading resources (e.g., `before_action :preload_bookmark, only: [...]`)
- `current_user` from Devise
- Resource loading gates authorization — non-owned resources return 404 (not 403)
- Transaction blocks wrapping `.save!` / `.destroy_logically!`
- Redirect after mutating actions using `redirect_to action: 'index'`

## Service Layer Conventions

- Services live in `app/services/` (e.g., `mastodon_client.rb`, `x_client.rb`)
- Services return result hashes: `{ success: true, items: [...] }` or `{ success: false, error: :api_error }`
- External HTTP via Faraday — exceptions caught at service layer, not propagated to controllers
- Services accept an optional `connection:` keyword argument for testability (injected Faraday stub)

## Error Handling

- Controllers return 404 for unauthorized resource access (not 403)
- Services return structured error results — callers check `result[:success]`
- Faraday exceptions rescued at service call site

## Comments

- Architecture/regression context documented at the top of contract test files with reference codes (e.g., `# ARCH-01 + ARCH-02`, `# MOB-01`)
- Inline business-rule comments in Japanese within models and controllers
- No JSDoc/RDoc conventions enforced

## i18n Conventions

- All user-facing strings in `config/locales/ja.yml` (primary) and `config/locales/en.yml` (must be kept in parity)
- User's locale preference (`preference.locale`) defaults to `nil` (falls back to app default `ja`)
- Supported locales: `ja`, `en` — validated via `Preference::SUPPORTED_LOCALES`
- User-created content (folder names, bookmark titles) is never translated — only fixture/system labels use i18n
- When adding a new locale key, add it to **both** `ja.yml` and `en.yml` simultaneously

---

*Convention analysis: 2026-05-18*
