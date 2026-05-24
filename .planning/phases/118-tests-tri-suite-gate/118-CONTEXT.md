# Phase 118: Tests & Tri-suite Gate - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Mode:** Retroactive (code already implemented across phases 115–117 commits)

<domain>
## Phase Boundary

Verify all v1.34 behavior end-to-end across unit, integration, and browser test layers, and close the tri-suite gate. Includes 3 Cucumber E2E scenarios for the Connected Accounts feature. No new application code — test/verification closure only.

</domain>

<decisions>
## Implementation Decisions

### Cucumber Scenarios
- **D-01:** 3 scenarios under `@connected_accounts` tag in `features/14.連携アカウント.feature`
  1. Display: all 4 auth methods visible
  2. Disconnect: linked OAuth provider → row transitions to "Not connected"
  3. Safety guard: last auth method cannot be disconnected → error flash, row stays linked

### Hooks
- **D-02:** `Before('@connected_accounts')` creates two OauthIdentity rows for the test user (Google + X) so disconnect scenarios have a linked provider to work with
- **D-03:** `After('@connected_accounts')` cleans up OauthIdentity rows

### Step Definitions
- **D-04:** Step defs in `features/step_definitions/connected_accounts.rb`
- **D-05:** Use `I18n.t(...)` for locale-sensitive label lookups, matching pattern from other step defs

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `features/support/hooks.rb` — Before/After hook registration pattern
- `features/step_definitions/` — existing step def pattern
- `user` helper returns `User.first` (fixture user1)

### Established Patterns
- `@tag` Before hook creates test-specific data, After hook cleans up via `delete_all`
- `within('.css-selector', text: label)` pattern for scoped assertions
- `assert_selector '.badge-class', text: label` for status checks

</code_context>

<specifics>
## Specific Ideas

- `Before('@connected_accounts')` must create `OauthIdentity` rows directly (not via OAuth flow) — use `OauthIdentity.create!`
- The "last auth method" scenario requires Google to be disconnected first (leaving only X), then X disconnect attempt triggers the guard

</specifics>

<deferred>
## Deferred Ideas

- None

</deferred>

---

*Phase: 118-Tests & Tri-suite Gate*
*Context gathered: 2026-05-24 (retroactive)*
