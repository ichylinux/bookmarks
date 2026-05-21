# Phase 103: Navigation, Locale & Tri-suite Gate - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Add drawer nav link for admin users pointing to `/admin/users`, wire all UI strings through ja/en locale YAML, add i18n parity test for new keys, add Cucumber scenario for admin navigation to user list, and close with green tri-suite (lint + Minitest + Cucumber).

</domain>

<decisions>
## Implementation Decisions

### Nav Link Placement
- Nav link order in admin section: `/admin/users` first, then `/admin/x_api_usages` — new feature leads
- Japanese label: `nav.users` key → 「ユーザー一覧」
- English label: `nav.users` key → "Users"
- Location: `nav.users` locale key alongside existing `nav.x_api_usages` in the `nav:` namespace

### Locale Key Structure
- View strings: `admin.users.index.*` namespace — matches `admin.x_api_usages.index.*` pattern
- Nav link: `nav.users` key (not under `admin.users`) — consistent with `nav.x_api_usages` key
- Keys needed: `admin.users.index.title` + one key per column header (id, email, x_user_name, admin_flag, last_sign_in_at, created_at, updated_at)

### Cucumber Coverage
- Scenario: admin signs in, navigates to `/admin/users`, sees user table with expected columns present
- Tag: no special tag needed (uses standard Selenium driver)
- File: `features/08.Admin.feature` or append to existing admin feature if one exists

### i18n Parity Test
- Dedicated test asserting all `admin.users.index.*` keys and `nav.users` key present in both ja.yml and en.yml
- Pattern: matches v1.29 i18n parity test structure

### Claude's Discretion
- Tri-suite closure is the gate for this phase — all three (lint, Minitest, Cucumber) must be green before marking complete
- If the admin feature file doesn't exist, create `features/08.Admin.feature`
- Cucumber step: use `visit admin_users_path` pattern; sign in as admin first

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/common/_nav_sections.html.erb` — admin section already exists with `current_user.admin?` guard and `drawer-nav-section--admin` class; add `nav.users` link before `nav.x_api_usages`
- `config/locales/ja.yml` — `nav:` section has `x_api_usages:` key; add `users:` key
- `config/locales/en.yml` — same structure
- v1.29 i18n parity test — reference pattern for new parity test

### Established Patterns
- Nav item render: `render 'common/nav_item', variant: variant, label: t('nav.users'), url: admin_users_path, icon: :preferences`
- Admin nav section: already wrapped in `if current_user.admin?` in `_nav_sections.html.erb`
- Cucumber admin sign-in: use existing step `Given I sign in as admin user`

### Integration Points
- `app/views/common/_nav_sections.html.erb` — add users link before x_api_usages
- `config/locales/ja.yml` + `en.yml` — `nav.users` + `admin.users.index.*` keys
- `features/` — new or existing admin feature file
- `test/` — new i18n parity test for admin.users keys

</code_context>

<specifics>
## Specific Ideas

- The Phase 102 view can use placeholder hardcoded strings for column headers; Phase 103 replaces them with `t('.col_*')` locale key calls
- OR Phase 102 can add locale keys directly — acceptable if simpler

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
