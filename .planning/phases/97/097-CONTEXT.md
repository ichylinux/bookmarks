# Phase 97: Instrumentation + Cucumber Isolation - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous)

<domain>
## Phase Boundary

Instrument `XAccountsController#refresh` and `#show` so every X API call writes an `XApiCall` row on success and error paths. Add Cucumber `Before` hook cleanup so scenarios do not leak rows.

</domain>

<decisions>
## Implementation Decisions

### Instrumentation Placement
- Call `XApiCall.record!` immediately after `XClient` returns, before branching on success — matches STATE.md: outside any transaction wrapper
- Private helper `record_x_api_call(endpoint:, result:)` on `XAccountsController` to avoid duplication

### Recorded Values
- `endpoint`: `'fetch_following'` for `#refresh`, `'fetch_recent_tweets'` for `#show`
- `success`: `result[:success]`
- `error_code`: `result[:error].to_s` when `success` is false; `nil` otherwise
- `rate_limit_remaining`: `result[:rate_limit_remaining]` (nil until XClient exposes header — column exists from Phase 96)

### Cucumber Isolation
- Add `XApiCall.delete_all` to global `Before` hook in `features/support/hooks.rb` alongside existing `MastodonAccount`, `XAccount`, `VisitedLink` cleanup

### Tests
- Extend `test/controllers/x_accounts_controller_test.rb` with `XApiCall.delete_all` in setup
- Four new tests: refresh success/error and show success/error each assert `XApiCall.count` increases by 1 with correct endpoint

</decisions>

<code_context>
## Existing Code Insights

### XAccountsController (app/controllers/x_accounts_controller.rb)
- `#refresh` calls `fetch_following`, early-returns on failure with flash + redirect
- `#show` calls `fetch_recent_tweets`, sets `@x_items` / `@x_error` without redirect on error

### XApiCall.record! (app/models/x_api_call.rb)
- Keyword args; `error_code` stored as string (e.g. `'timeout'`)

### hooks.rb pattern
- Global `Before` deletes `MastodonAccount`, `XAccount`, `VisitedLink` — add `XApiCall` same block

</code_context>

<specifics>
## Specific Ideas

- No changes to `XClient` in this phase — rate_limit_remaining stays nil
- Existing `@x_gadget` Cucumber scenario must remain green after instrumentation

</specifics>

<deferred>
## Deferred Ideas

- Extract rate_limit_remaining from Faraday response headers in XClient — future phase if needed

</deferred>
