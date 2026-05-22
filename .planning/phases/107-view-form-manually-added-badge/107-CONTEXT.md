# Phase 107: View Form & Manually-Added Badge - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a handle input form to the `/x_accounts` index page that POSTs to `lookup_and_add_x_accounts_path`, and add a visible badge to account cards where `manually_added: true`. No JavaScript required. Add all new locale keys (form label, submit button, badge) to both ja.yml and en.yml.

</domain>

<decisions>
## Implementation Decisions

- Form placed in the index page header area, below the refresh button row
- `form_with url: lookup_and_add_x_accounts_path, method: :post, local: true` — no Turbo/Ajax
- Badge placed in the account card header `x-account-card__head` div, alongside identity
- Locale keys: `x_accounts.lookup_and_add.handle_label`, `x_accounts.lookup_and_add.submit`, `x_accounts.index.manually_added_badge`
- Badge CSS class: `x-account-card__manually-added-badge` (styling deferred to Phase 108 if needed)

</decisions>

<code_context>
## Existing Code Insights

- `app/views/x_accounts/index.html.erb` — index view to modify
- `config/locales/ja.yml` and `en.yml` — add under `x_accounts.*` sections
- `XAccount#manually_added?` — available from Phase 104 migration

</code_context>
