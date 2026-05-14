# Phase 64: WebMock baseline - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Add `webmock` gem to Gemfile `:test` group; configure `WebMock.disable_net_connect!` in `test/test_helper.rb` or a new `test/support/webmock.rb` support file; allowlist localhost / 127.0.0.1 / `::1` (and any Capybara/Selenium endpoints). Smoke: `bin/rails test` boots without unintended stub of internal requests.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Key constraints:
- WebMock config belongs in `test/support/webmock.rb` (consistent with existing `test/support/*.rb` pattern — auto-loaded by `test_helper.rb` via `Dir[...]`)
- Allowlist must cover localhost, 127.0.0.1, ::1 so Capybara/Selenium driver traffic is never blocked
- Do NOT yet touch `config/environments/test.rb` stub loader or `test/http_client_test_stubs.rb` — those are Phase 65/66

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/test_helper.rb` auto-loads all `test/support/*.rb` files via `Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')]` — a new `test/support/webmock.rb` will be picked up automatically
- Capybara + selenium-webdriver in Gemfile `:test` group (lines 48, 55)

### Established Patterns
- Support files added to `test/support/` are class_eval'd into `ActiveSupport::TestCase` — WebMock config should be a top-level `require`/configure call in the support file, not a module method
- `config/environments/test.rb` still loads `test/http_client_test_stubs.rb` — Phase 64 leaves this untouched

### Integration Points
- `Gemfile` `:test` group (after existing `capybara`/`selenium-webdriver`)
- `test/support/webmock.rb` (new file, auto-loaded)
- WebMock allowlist must include Capybara server (typically `127.0.0.1`) and Selenium Chrome driver

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Use standard WebMock disable_net_connect! with localhost allowlist.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
