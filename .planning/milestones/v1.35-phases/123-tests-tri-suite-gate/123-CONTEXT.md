# Phase 123: Tests & Tri-Suite Gate - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Mode:** Auto-generated from ROADMAP phase 123 and REQUIREMENTS (CTRL-02, TEST-01, TEST-02)

<domain>
## Phase Boundary

Close v1.35 Mastodon OAuth with full test coverage and tri-suite gate. No new application code — test and verification closure only.

Includes:
- Minitest disconnect guard for `DELETE /oauth_identities/mastodon` (CTRL-02)
- Audit that Phases 119–122 Minitest paths are present (TEST-01)
- Cucumber `@connected_accounts` extension for Mastodon row presence (TEST-02, no live OAuth)
- Tri-suite green: `yarn run lint && bin/rails test && bundle exec rake dad:test`

Does NOT include new OAuth strategy, instance UI, identity wiring, or Connected Accounts view changes (Phases 119–122).

</domain>

<decisions>
## Implementation Decisions

### Minitest (TEST-01, CTRL-02)
- **D-01:** Add `test_destroy_blocks_disconnect_of_last_auth_method_for_mastodon` in `oauth_identities_controller_test.rb` — mirror existing `google_oauth2` guard test with provider `mastodon` and composite uid
- **D-02:** Phases 119–122 already cover strategy, instance validation, `from_omniauth`, callback — verify presence only; no duplicate tests unless gaps found

### Cucumber (TEST-02)
- **D-03:** Update display scenario in `features/14.連携アカウント.feature` from 4 to 5 auth rows (add Mastodon)
- **D-04:** Extend step def to assert `preferences.index.connected_accounts.mastodon` label within `.connected-accounts`
- **D-05:** No new scenarios — Mastodon is additive to existing display scenario; disconnect/guard scenarios unchanged (Google/X pattern sufficient per v1.34 precedent)

### Hooks
- **D-06:** `@connected_accounts` Before/After hooks unchanged — Mastodon row displays regardless of linked state; disconnect scenarios use Google/X only

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/controllers/oauth_identities_controller_test.rb` — `test_destroy_blocks_disconnect_of_last_auth_method` pattern
- `features/14.連携アカウント.feature` — 3 `@connected_accounts` scenarios from Phase 118
- `features/step_definitions/connected_accounts.rb` — 4-row assertion step
- Phases 119–122 test files: `mastodon_test.rb`, `mastodon_instances_controller_test.rb`, `oauth_identity_test.rb`, `omniauth_callbacks_controller_test.rb`, `preferences_controller_test.rb`

### Established Patterns
- Last-auth guard: single OAuth identity + `password_auth_enabled: false` → delete blocked with `oauth_identities.destroy.last_auth_method` flash
- Cucumber display: `within '.connected-accounts'` + `I18n.t('preferences.index.connected_accounts.*', locale: :ja)`
- Facebook precedent (Phase 113): static row presence in Cucumber, no live OAuth round-trip

</code_context>

<requirements>
## Requirements Mapped

| ID | Description |
|----|-------------|
| CTRL-02 | `DELETE /oauth_identities/mastodon` works with last-auth-method safety guard |
| TEST-01 | Minitest covers strategy uid, instance validation, from_omniauth, callback, disconnect guard |
| TEST-02 | Cucumber extends connected-accounts for Mastodon row (no live OAuth) |

</requirements>

<deferred>
## Deferred Ideas

- Live Mastodon OAuth Cucumber round-trip (out of scope per REQUIREMENTS)
- Connect Mastodon from preferences without sign-in flow (IDNT-FUT-01)

</deferred>

---

*Phase: 123-Tests & Tri-Suite Gate*
*Context gathered: 2026-06-12*
