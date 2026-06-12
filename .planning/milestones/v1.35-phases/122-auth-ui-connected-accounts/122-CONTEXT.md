# Phase 122: Auth UI & Connected Accounts - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Mode:** Auto-generated from ROADMAP phase 122 and REQUIREMENTS (VIEW-01, VIEW-02, VIEW-03)

<domain>
## Phase Boundary

Brand the Mastodon OAuth entry on sign-in/sign-up (icon + styled submit button integrated with Phase 120 instance form) and add a Mastodon row to Connected Accounts on preferences (icon, linked/unlinked badge, disconnect button). Bilingual ja/en labels. Integration test: preferences page renders Mastodon row.

Does NOT include disconnect last-auth-method guard test (Phase 123), Cucumber connected-accounts scenarios (Phase 123), or changes to OAuth strategy/callback/identity wiring (Phases 119–121).

</domain>

<decisions>
## Implementation Decisions

### OAuth Button (VIEW-01)
- Phase 120 instance form remains; enhance submit with Mastodon icon + branded `.auth-oauth-btn--mastodon` (purple #6364ff, match Google/X/Facebook button structure)
- Use `button_tag type: 'submit'` with `auth-oauth-btn__icon` + `auth-oauth-btn__label` spans (same as other providers)
- Mastodon section stays below other OAuth buttons in `_oauth_buttons.html.erb`

### Connected Accounts Row (VIEW-02)
- Add 5th row after Facebook, before Email & Password — order matches auth provider list
- Provider key: `mastodon`; disconnect via existing `oauth_identity_path('mastodon')` DELETE (controller from Phase 116)
- Reuse existing badge/disconnect patterns from Phase 117 rows

### Locales (VIEW-03)
- Auth labels already exist under `devise.shared.omniauth.mastodon.*` (Phase 120)
- Add `preferences.index.connected_accounts.mastodon` in ja.yml and en.yml
- i18n parity test must pass (no new keys in one locale only)

### Testing
- Extend `test_connected_accounts_section_renders_four_auth_rows` → five rows including mastodon
- Optional: assert Mastodon icon class on sign-in page submit button

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/devise/shared/_oauth_buttons.html.erb` — Mastodon instance form (Phase 120)
- `app/views/preferences/_connected_accounts.html.erb` — 4 provider rows (Phase 117)
- `app/assets/stylesheets/devise.css.scss` — `.auth-oauth-btn--mastodon` hover stub (Phase 120)
- Locale keys `devise.shared.omniauth.mastodon.*` (Phase 120)

### Established Patterns
- OAuth buttons: inline SVG in `auth-oauth-btn__icon`, provider-specific modifier class
- Connected accounts: `linked_providers.include?('provider')` conditional, `oauth_identity_path(provider)` disconnect
- Preferences test: `assert_select` with I18n.t for ja locale

</code_context>

<requirements>
## Requirements Mapped

| ID | Description |
|----|-------------|
| VIEW-01 | Mastodon OAuth button on sign-in/sign-up with instance form integration |
| VIEW-02 | Connected Accounts Mastodon row with icon, status badge, disconnect |
| VIEW-03 | Bilingual ja/en labels for Mastodon auth UI |

</requirements>

<deferred>
## Deferred Ideas

- Disconnect guard Minitest for mastodon (Phase 123)
- Cucumber `@connected_accounts` Mastodon scenarios (Phase 123)

</deferred>
