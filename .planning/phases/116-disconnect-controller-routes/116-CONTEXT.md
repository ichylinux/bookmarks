# Phase 116: Disconnect Controller & Routes - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Mode:** Retroactive (code already implemented in commit dc82abe)

<domain>
## Phase Boundary

Add `OauthIdentitiesController#destroy` handling `DELETE /oauth_identities/:provider` with a safety guard: disconnect is blocked if it would leave the user with no remaining auth method (no other oauth_identities AND `password_auth_enabled: false`). Also add `has_many :oauth_identities` to `User`. Locale keys for all three flash states in ja/en. 5 Minitest controller tests.

</domain>

<decisions>
## Implementation Decisions

### Routing
- **D-01:** `resources :oauth_identities, only: [:destroy], param: :provider` — uses `:provider` as the URL param (not `:id`)
- **D-02:** Requires authentication (Devise `authenticate_user!` before_action)

### Safety Guard Logic
- **D-03:** After removing the target provider, check if user has any remaining `oauth_identities` OR `password_auth_enabled: true` — if neither, block with `last_auth_method` flash
- **D-04:** Guard checked before deletion — no delete if would leave empty

### Graceful No-op
- **D-05:** Provider not linked → `not_connected` notice flash, no 500

### Association
- **D-06:** `has_many :oauth_identities, dependent: :destroy` on `User` (added in this phase)

### Locale Keys
- **D-07:** `oauth_identities.destroy.success`, `.not_connected`, `.last_auth_method` in both ja.yml and en.yml

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OauthIdentity` model from Phase 114 with `upsert_for!` class method
- `ApplicationController` with Devise helpers

### Established Patterns
- Controller access guard via `before_action :authenticate_user!`
- Flash `:notice` for success, `:alert` for errors
- `redirect_to preferences_path` on success (consistent with other preference-related flows)

### Integration Points
- `app/controllers/oauth_identities_controller.rb` (new)
- `config/routes.rb`
- `app/models/user.rb` (add `has_many :oauth_identities`)
- `config/locales/ja.yml`, `en.yml`
- `test/controllers/oauth_identities_controller_test.rb` (new)

</code_context>

<specifics>
## Specific Ideas

- Provider param is the OmniAuth provider string: `google_oauth2`, `twitter2`, `facebook` — plus `form` for email/password disconnect (added in Phase 117)
- `find_by(provider: params[:provider])` returns nil for already-unlinked providers — handled gracefully

</specifics>

<deferred>
## Deferred Ideas

- `form` provider handling in destroy — handled in Phase 117

</deferred>

---

*Phase: 116-Disconnect Controller & Routes*
*Context gathered: 2026-05-24 (retroactive)*
