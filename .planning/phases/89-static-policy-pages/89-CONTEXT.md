# Phase 89: Static Policy Pages - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 89 delivers two publicly accessible, bilingual static pages:
- `/privacy` — privacy policy, readable without authentication, in Japanese and English
- `/terms` — terms of service, readable without authentication, in Japanese and English

Both pages must contain full substantive content satisfying PRIV-01–PRIV-03 and TOS-01–TOS-03. No data layer changes. No footer/nav links (out of scope per REQUIREMENTS). The primary driver is X Developer Portal approval for email scope — the pages must be live and linkable.

</domain>

<decisions>
## Implementation Decisions

### Controller & Routing Architecture
- New `PagesController < ApplicationController` with `skip_before_action :authenticate_user!` — clean separation from authenticated controllers
- Simple `get 'privacy', to: 'pages#privacy'` and `get 'terms', to: 'pages#terms'` routes in `config/routes.rb`
- Use existing `application.html.erb` layout — shows header consistently, same as landing page
- `Localization` concern inherited from `ApplicationController` automatically — locale param works out of the box

### Content Delivery & Structure
- Policy text stored in locale YAML files (`ja.yml` / `en.yml`) under `pages.privacy.*` and `pages.terms.*` — matches existing i18n pattern
- Multiple keys per section (e.g., `pages.privacy.sections.data_collected`, `pages.privacy.sections.x_login`) — each section rendered as a prose block by ERB
- Privacy policy sections: data collected, purpose of X login, email address handling, data retention, contact
- Terms of service sections: acceptable use, service availability, account termination

### Page UX & Testing
- Locale switcher links at top of each page using `privacy_path(locale: 'ja')` / `privacy_path(locale: 'en')` — same pattern as landing page lang switcher
- "← Back to home" link pointing to `root_path` — useful for X Developer Portal reviewers navigating the site
- Minitest integration tests: 200 status unauthenticated (both locales), correct content rendering, no auth redirect — two test files (`privacy_controller_test.rb`, `terms_controller_test.rb`)
- Reuse existing CSS prose styling; add minimal page-specific styles only if section headers need differentiation

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApplicationController` with `before_action :authenticate_user!` — skip with `skip_before_action :authenticate_user!` in PagesController
- `include Localization` in ApplicationController — locale param handling inherited automatically
- Locale YAML pattern: `config/locales/ja.yml` and `en.yml` with nested keys, `t('key')` in views
- Landing page lang switcher: `link_to "日本語", root_path(locale: 'ja')` — adapt to `privacy_path(locale: 'ja')`
- `app/views/layouts/application.html.erb` — existing layout with header, flash, yield

### Established Patterns
- Skip auth: `skip_before_action :authenticate_user!` — used in `Users::SessionsController`, `Users::RegistrationsController`, Devise controllers
- i18n: all UI strings via `t()` helper backed by YAML; no hardcoded strings in views
- Test pattern: `ActionDispatch::IntegrationTest` with `Devise::Test::IntegrationHelpers`; `get path` + `assert_response :success` + `assert_select`

### Integration Points
- `config/routes.rb` — add two `get` routes inside the `unless ARGV.first =~ /^dad:setup/` block
- `config/locales/ja.yml` and `en.yml` — add `pages:` top-level namespace
- `test/controllers/` — two new test files

</code_context>

<specifics>
## Specific Ideas

- Privacy policy must address: data collected (bookmarks, feeds, preferences), X OAuth login flow, email address handling (dummy email → real email scenario), data retention (personal app, user controls their own data), contact
- Terms must address: acceptable use (personal use, no commercial redistribution), service availability (best-effort, no SLA), account termination (user can delete account)
- X Developer Portal will review these pages — content must be substantive, not placeholder text
- Locale switcher placement: top of page content area (not in the header), same visual style as landing page `.landing-lang-switcher`

</specifics>

<deferred>
## Deferred Ideas

- Footer links to `/privacy` and `/terms` — explicitly out of scope per REQUIREMENTS.md ("Footer/nav links to privacy or ToS: Not required by X; links can be added later")
- Landing page links to policy pages — deferred to a future quick task or milestone
- Cookie consent banner — out of scope (personal app with no tracking cookies)
- GDPR data export/deletion — out of scope for this milestone

</deferred>
