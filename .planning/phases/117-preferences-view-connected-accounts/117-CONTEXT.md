# Phase 117: Preferences View — Connected Accounts - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Mode:** Retroactive (code already implemented in commit a559ca1)

<domain>
## Phase Boundary

Add a "Connected Accounts" section to the preferences page listing all 4 auth methods (Google, X, Facebook, Email & Password) with icons, linked/unlinked status badges, and disconnect buttons for linked methods. Also extend `OauthIdentitiesController#destroy` to handle `provider='form'` (form auth disconnect path). Locale keys for all new strings in ja/en.

</domain>

<decisions>
## Implementation Decisions

### View Structure
- **D-01:** Extracted as a partial `_connected_accounts.html.erb` rendered inside preferences `index.html.erb`
- **D-02:** CSS class `connected-accounts` on the section, `connected-accounts__row` per provider, `connected-accounts__badge--connected` / `--unlinked` for status

### Disconnect Form
- **D-03:** Uses Rails `button_to` with `method: :delete` to `oauth_identity_path(provider:)` — no custom JavaScript
- **D-04:** Linked providers show Disconnect button; unlinked show a "Not connected" badge

### Form Auth Row
- **D-05:** `provider='form'` handled in `OauthIdentitiesController#destroy` — calls `disconnect_form_auth!`, safety guard checks oauth_identities count
- **D-06:** Form auth row shows "Not connected" when `password_auth_enabled: false`, Disconnect button when `true`

### Locale Keys
- **D-07:** `preferences.index.connected_accounts.{google,twitter,facebook,email_password,connected,not_connected,disconnect}` in ja.yml and en.yml

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/preferences/index.html.erb` — existing preferences layout
- `app/controllers/oauth_identities_controller.rb` — extended with form provider handling
- Provider icon assets already in app (Google, X, Facebook SVGs)

### Established Patterns
- Partials in `app/views/preferences/` follow `_section_name.html.erb` naming
- `button_to` with `method: :delete` used for destructive actions in existing views

### Integration Points
- `app/views/preferences/_connected_accounts.html.erb` (new partial)
- `app/views/preferences/index.html.erb` (add `<%= render 'connected_accounts' %>`)
- `app/controllers/oauth_identities_controller.rb` (extend destroy for 'form' provider)
- `config/locales/ja.yml`, `en.yml`

</code_context>

<specifics>
## Specific Ideas

- The section must display all 4 methods regardless of current link status
- Safety guard for form auth disconnect: blocked if no remaining oauth_identities (cannot remove last auth method)

</specifics>

<deferred>
## Deferred Ideas

- IDNT-FUT-01: connect new OAuth provider from preferences — deferred to v2

</deferred>

---

*Phase: 117-Preferences View — Connected Accounts*
*Context gathered: 2026-05-24 (retroactive)*
