# Phase 38: Existing-user Migration and One-time Notice - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate legacy font-size values (`nil`/`medium`) to `small` safely for existing users and display an in-app one-time notice for affected accounts.

</domain>

<decisions>
## Implementation Decisions

### Migration Strategy
- Use a DB migration to convert existing `nil`/`medium` values to `small`.
- Record affected users with a pending notice flag so notice rendering remains one-time and idempotent.

### Notice Delivery
- Render migration notice in application layout flow via `ApplicationController` before_action.
- Do not override explicit controller-set notice flash; defer migration notice to the next request when needed.

### the agent's Discretion
- Exact flag naming and model helper APIs are at implementation discretion if behavior contract is preserved.

</decisions>

<specifics>
## Specific Ideas

- Keep migration idempotent by targeting only `nil`/`medium` rows.
- Clear pending notice flag immediately after first display.

</specifics>

<deferred>
## Deferred Ideas

- Exposing a permanent changelog/history entry for this migration.

</deferred>
