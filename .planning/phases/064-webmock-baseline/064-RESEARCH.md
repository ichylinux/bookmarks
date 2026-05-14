# Phase 64: WebMock Baseline - Research

**Researched:** 2026-05-14
**Domain:** WebMock gem configuration for Minitest + Cucumber coexistence
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All implementation choices are at Claude's discretion — pure infrastructure phase. Key constraints:
- WebMock config belongs in `test/support/webmock.rb` (consistent with existing `test/support/*.rb` pattern — auto-loaded by `test_helper.rb` via `Dir[...]`)
- Allowlist must cover localhost, 127.0.0.1, ::1 so Capybara/Selenium driver traffic is never blocked
- Do NOT yet touch `config/environments/test.rb` stub loader or `test/http_client_test_stubs.rb` — those are Phase 65/66

### Claude's Discretion
All implementation choices (exact require form, allowlist syntax, comments).

### Deferred Ideas (OUT OF SCOPE)
None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HTTP-01 | `webmock` declared in Gemfile `:test`; Minitest loads WebMock configuration from `test/support/` with `WebMock.disable_net_connect!` and explicit allowances for localhost / Capybara / Selenium so the suite does not flake on legitimate local traffic. | See Standard Stack (version 3.26.2 verified) and Architecture Patterns (support file placement + correct require form). |
</phase_requirements>

---

## Summary

Phase 64 adds the `webmock` gem to the `:test` group and wires in a single support file, `test/support/webmock.rb`, that calls `WebMock.disable_net_connect!(allow_localhost: true)`. This is an infrastructure-only change — no test files are rewritten in this phase.

The primary complication is that `test/support/webmock.rb` is auto-loaded by **two separate mechanisms**: (1) `test_helper.rb` via `Dir[...].class_eval` for Minitest and (2) `features/support/test_support.rb` via `World(TestSupport)` for Cucumber. Both load all files in `test/support/`. A `require` call inside a `class_eval`'d file runs at the Ruby top level (kernel), so WebMock gets required and `disable_net_connect!` fires in both suites. This is the correct behavior for Phase 64 — Cucumber already stubs HTTP via the prepend seams in `test/http_client_test_stubs.rb` (loaded by `config/environments/test.rb`), so the two mechanisms coexist without conflict until Phase 65-66 migration.

The critical distinction: `require 'webmock/minitest'` calls `WebMock.enable!` globally **and** patches `Minitest::Test#teardown` to call `WebMock.reset!` after every test. It does **not** automatically call `disable_net_connect!`. That must be a separate, explicit call.

**Primary recommendation:** Create `test/support/webmock.rb` with `require 'webmock/minitest'` followed by `WebMock.disable_net_connect!(allow_localhost: true)`. The `allow_localhost: true` flag covers `localhost`, `127.0.0.1`, and `::1` in one option. Add `webmock` to `Gemfile` group `:test` after `selenium-webdriver`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP blocking (disable net connect) | Test infrastructure | — | WebMock operates at the HTTP adapter layer, intercepting all HTTP clients uniformly |
| Localhost allowlisting | Test infrastructure | — | Capybara server + Selenium ChromeDriver communicate over localhost; blocking would crash browser tests |
| Stub reset between tests | WebMock/Minitest hook | — | `webmock/minitest` patches `Minitest::Test#teardown` automatically; no per-test code needed |
| Cucumber HTTP isolation | Existing prepend stubs (untouched) | WebMock global enable (side-effect) | Phase 64 does not migrate Cucumber; existing `XClient`/`MastodonClient` prepend stubs remain active |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| webmock | 3.26.2 | Block / stub HTTP requests in tests | De facto standard for Ruby HTTP mocking; supports all major HTTP clients (Net::HTTP, Faraday, etc.) [VERIFIED: rubygems.org, 2026-03-18] |

**Version verification:**
```bash
gem search --remote webmock
# => webmock (3.26.2)
```
[VERIFIED: rubygems.org — version 3.26.2, published 2026-03-18]

### Installation

```bash
bundle add webmock --group test
# or manually add to Gemfile then:
bundle install
```

Gemfile placement (after `selenium-webdriver`):
```ruby
group :test do
  gem 'capybara'
  # ... existing gems ...
  gem 'selenium-webdriver'
  gem 'webmock'  # <-- add here
end
```

## Architecture Patterns

### System Architecture Diagram

```
bin/rails test (Minitest)
  └─> test/test_helper.rb
        └─> Dir[test/support/*.rb].class_eval  ← auto-loads webmock.rb
              └─> test/support/webmock.rb
                    ├─> require 'webmock/minitest'
                    │     ├─> WebMock.enable!            (activates stubbing globally)
                    │     └─> Minitest::Test#teardown    (patched: calls WebMock.reset!)
                    └─> WebMock.disable_net_connect!(allow_localhost: true)
                          └─> localhost / 127.0.0.1 / ::1 ─ ALLOWED
                              all other hosts              ─ BLOCKED

bundle exec rake dad:test (Cucumber)
  └─> features/support/test_support.rb
        └─> Dir[test/support/*.rb].class_eval  ← same directory, same webmock.rb loaded
              └─> test/support/webmock.rb
                    ├─> require 'webmock/minitest'
                    │     └─> WebMock.enable!            (fires; Minitest::Test patch is a no-op if Minitest not loaded)
                    └─> WebMock.disable_net_connect!(allow_localhost: true)
  └─> features/support/hooks.rb
        └─> XClient/MastodonClient prepend stubs still active (from config/environments/test.rb)
              └─> stub_fetch_* short-circuits before any real HTTP reaches WebMock
```

### Recommended File Structure

```
test/
└── support/
    └── webmock.rb    # NEW — auto-loaded by both Minitest and Cucumber
```

### Pattern 1: webmock/minitest + explicit disable_net_connect!

**What:** Require the Minitest integration shim, then explicitly disable net connections with localhost exception.

**When to use:** Always — these are two separate calls with different responsibilities.

```ruby
# test/support/webmock.rb
# Source: https://github.com/bblimke/webmock/blob/master/README.md
require 'webmock/minitest'

# Disable all real network connections in tests.
# allow_localhost: true is required so Capybara's Puma server (127.0.0.1) and
# Selenium ChromeDriver (127.0.0.1) can communicate without WebMock interference.
# This covers: localhost, 127.0.0.1, ::1
WebMock.disable_net_connect!(allow_localhost: true)
```

**Why `allow_localhost: true` is sufficient:** The `allow_localhost: true` option is the idiomatic WebMock shorthand. Internally WebMock matches `localhost`, `127.0.0.1`, and `::1`. [VERIFIED: Context7 / webmock README]

### Pattern 2: What `webmock/minitest` does (internals matter for Cucumber coexistence)

```ruby
# What require 'webmock/minitest' does internally (abbreviated):
WebMock.enable!                          # activates HTTP stubbing globally

Minitest::Test.class_eval do
  include WebMock::API                   # makes stub_request available in tests

  alias_method :teardown_without_webmock, :teardown
  def teardown_with_webmock
    teardown_without_webmock
    WebMock.reset!                       # clears stubs after each Minitest test
  end
  alias_method :teardown, :teardown_with_webmock
end
```
[VERIFIED: raw source at github.com/bblimke/webmock/blob/master/lib/webmock/minitest.rb]

**Cucumber implication:** When this file is loaded in the Cucumber process, `Minitest::Test` is loaded (it's a dependency of other gems) and gets patched. However, Cucumber does NOT run `teardown`. WebMock stubs do **not** auto-reset between Cucumber scenarios from this hook. In Phase 64 this does not matter because the existing prepend stubs in `test/http_client_test_stubs.rb` short-circuit before any real HTTP request, so no WebMock stubs are ever set during Cucumber. Phase 66 will add explicit `WebMock.reset!` in a Cucumber `After` hook when it starts setting real WebMock stubs.

### Anti-Patterns to Avoid

- **`require 'webmock'` without `require 'webmock/minitest'`**: Enables WebMock but does NOT install the `teardown` hook that calls `WebMock.reset!` after each test. Stubs set in one test bleed into the next.
- **`require 'webmock/cucumber'` instead of `require 'webmock/minitest'`**: The Cucumber integration adds `World(WebMock::API, WebMock::Matchers)` and an `After` hook for `WebMock.reset!` — correct for Phase 66, but Phase 64 is wired through `test/support/` which must serve Minitest first.
- **Calling `WebMock.disable_net_connect!` without `allow_localhost: true`**: Blocks Capybara's embedded Puma server and Selenium Chrome driver traffic; Cucumber suite crashes immediately on first `visit`.
- **Putting the `require` outside `test/support/webmock.rb`** (e.g., directly in `test_helper.rb`): Works for Minitest but misses Cucumber's auto-load path through `test_support.rb`. Keeping it in `test/support/` means both suites get it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP interception | Custom Net::HTTP monkeypatching | webmock 3.26.2 | WebMock patches all Ruby HTTP clients (Net::HTTP, Faraday, HTTParty, etc.) uniformly; custom patches miss adapters |
| Localhost detection | Custom URI comparison logic | `allow_localhost: true` option | WebMock handles `localhost`/`127.0.0.1`/`::1` variants internally |
| Stub reset between tests | Custom teardown overrides | `require 'webmock/minitest'` | The shim installs the teardown hook correctly with aliasing to avoid clobbering existing teardown |

## Common Pitfalls

### Pitfall 1: `class_eval` + `require` execution context

**What goes wrong:** Developer sees `class_eval` in `test_helper.rb` and assumes `require` inside the file runs in `ActiveSupport::TestCase` scope, potentially scoping WebMock initialization.

**Why it happens:** `class_eval File.read(f)` evaluates the string in the class context, but `require` is a Kernel method that always runs at the top level regardless of lexical context. The file content is evaluated as if it were typed inside the class body, but `require` still loads the file globally.

**How to avoid:** Write `test/support/webmock.rb` with top-level `require` and `WebMock.disable_net_connect!` calls — they will execute correctly even inside `class_eval`.

**Warning signs:** None — this works transparently. Confirm with `ruby -e "class Foo; class_eval 'require \"json\"; p defined?(JSON)'; end"` which prints `"constant"`.

### Pitfall 2: Double-load in Cucumber

**What goes wrong:** `test/support/webmock.rb` is loaded by both `test_helper.rb` (Minitest) AND `features/support/test_support.rb` (Cucumber). If `disable_net_connect!` were called without idempotency, each run would re-disable. In practice `require` is idempotent (Ruby's `$LOADED_FEATURES` guard), so double-loading is not a problem for the `require` call. `WebMock.disable_net_connect!` is also safe to call multiple times.

**How to avoid:** No action needed — this is correctly handled.

### Pitfall 3: WebMock blocks Selenium ChromeDriver port

**What goes wrong:** Selenium WebDriver communicates to ChromeDriver over a local port (typically `127.0.0.1:9515`). Without `allow_localhost: true`, WebMock intercepts this connection and the browser cannot be driven.

**Why it happens:** WebMock intercepts at the Net::HTTP / socket level, affecting Selenium's internal HTTP communication.

**How to avoid:** Use `WebMock.disable_net_connect!(allow_localhost: true)` — never plain `WebMock.disable_net_connect!` in a project using Selenium.

**Warning signs:** Cucumber scenarios that open a browser immediately fail with `WebMock::NetConnectNotAllowedError` mentioning `127.0.0.1`.

### Pitfall 4: Phase 64 does not conflict with existing prepend stubs

**What goes wrong:** Developer worries that enabling WebMock globally will interfere with the existing `XClientTestStub` / `MastodonClientTestStub` prepend modules (loaded via `config/environments/test.rb`).

**Why it's safe:** The prepend stubs intercept at the Ruby method level — they replace `fetch_following`, `fetch_recent_tweets`, `fetch_recent_status_previews` before any HTTP client is called. WebMock intercepts at the HTTP socket level. The prepend stubs return early (before HTTP), so WebMock never sees a request to intercept. Both mechanisms coexist without conflict.

**Warning signs:** None in Phase 64. Phase 65-66 will intentionally remove the prepend stubs and rely on WebMock — at that point the ordering matters.

### Pitfall 5: `require 'webmock/minitest'` loaded in Cucumber patches Minitest teardown

**What goes wrong:** When `webmock/minitest` loads in the Cucumber process, it patches `Minitest::Test#teardown`. Cucumber does not call Minitest teardown hooks, so WebMock stubs are NOT reset between Cucumber scenarios by this mechanism.

**Why it's OK in Phase 64:** No Cucumber tests set WebMock stubs in Phase 64. The existing prepend stubs handle all Cucumber HTTP interception.

**Why it matters for Phase 66:** Phase 66 must add an explicit `After { WebMock.reset! }` hook in `features/support/hooks.rb`. This is OUT OF SCOPE for Phase 64.

## Code Examples

### Complete `test/support/webmock.rb`

```ruby
# frozen_string_literal: true
# Source: https://github.com/bblimke/webmock/blob/master/README.md

require 'webmock/minitest'

# Block all external HTTP in tests.
# allow_localhost: true permits Capybara's embedded Puma server and Selenium
# ChromeDriver (both on 127.0.0.1) so the Cucumber/browser suite is unaffected.
# This covers localhost, 127.0.0.1, and ::1.
WebMock.disable_net_connect!(allow_localhost: true)
```

### Gemfile change

```ruby
group :test do
  gem 'capybara'
  gem 'ci_reporter', require: false
  gem 'closer', require: false
  gem 'cucumber-rails', require: false
  gem 'database_cleaner', require: false
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webmock'   # <-- add here, no version pin needed for ~> 3.x
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WebMock::NetConnectNotAllowedError` used to require manual Minitest teardown registration | `require 'webmock/minitest'` auto-installs teardown hook | webmock >= 1.x (stable for years) | No per-test teardown boilerplate needed |
| `allow: ['localhost', '127.0.0.1']` explicit array | `allow_localhost: true` shorthand | webmock >= 2.x | More concise; covers all three loopback forms |

**Not deprecated:** `allow_localhost: true` is current and preferred over an explicit array.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `require` inside a `class_eval`'d file executes at the top level (Kernel), not scoped to the class | Architecture Patterns / Pitfall 1 | If wrong, `require 'webmock/minitest'` would fail or be no-op; easy to verify with `ruby -e` before implementation |

**All other claims were verified** via Context7 (webmock source), rubygems.org, and direct source inspection of `lib/webmock/minitest.rb`.

## Open Questions

1. **Does `webmock/minitest` loading in Cucumber cause any visible side effect?**
   - What we know: It patches `Minitest::Test#teardown`. Cucumber does not run Minitest teardown.
   - What's unclear: Whether `Minitest::Test` being in `$LOADED_FEATURES` causes any test reporter or ordering conflict.
   - Recommendation: Confirmed safe in Phase 64 because no Cucumber scenarios set WebMock stubs. Phase 66 will add `After { WebMock.reset! }` explicitly.

2. **Is a version pin needed for webmock in Gemfile?**
   - What we know: Current version is 3.26.2 (stable, high download count). No known breaking changes in the `3.x` series.
   - Recommendation: No pin — `gem 'webmock'` resolves to latest stable. If the project later needs a pin, add `'~> 3.0'` at that point.

## Environment Availability

Step 2.6: SKIPPED (webmock is a pure Ruby gem with no external service or CLI dependency; `bundle install` is the only prerequisite, and bundler is already in use by the project).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest ~> 5.0 (existing) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test` |
| Full suite command | `yarn run lint && bin/rails test && bundle exec rake dad:test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HTTP-01 | WebMock gem present in Gemfile.lock | smoke | `bundle exec gem list webmock` | N/A |
| HTTP-01 | `bin/rails test` boots without errors | smoke | `bin/rails test` | existing |
| HTTP-01 | Capybara/Selenium scenarios still pass | e2e | `bundle exec rake dad:test` | existing |
| HTTP-01 | Real network blocked (no external requests in any test) | runtime invariant | Enforced by `disable_net_connect!` — any escaped request raises immediately | — |

### Sampling Rate

- **Per task commit:** `bin/rails test`
- **Per wave merge:** `yarn run lint && bin/rails test && bundle exec rake dad:test`
- **Phase gate:** Full tri-suite green before declaring phase complete

### Wave 0 Gaps

- [ ] `test/support/webmock.rb` — new file to create (covers HTTP-01)

*(All other test infrastructure is pre-existing.)*

## Security Domain

This phase introduces no production code changes and no new HTTP endpoints. WebMock is a test-only gem that never runs in production. ASVS categories V2–V6 do not apply. Security impact: neutral — the phase improves test isolation, which indirectly supports reliable security testing in later phases.

## Sources

### Primary (HIGH confidence)

- `/bblimke/webmock` (Context7) — `disable_net_connect!` allowlist syntax, `webmock/minitest` integration
- `https://github.com/bblimke/webmock/blob/master/lib/webmock/minitest.rb` — verbatim source of what `require 'webmock/minitest'` does; confirmed `WebMock.enable!` + teardown patch, no automatic `disable_net_connect!`
- `https://github.com/bblimke/webmock/blob/master/README.md` — `allow_localhost: true` syntax; framework integration setup
- `https://rubygems.org/gems/webmock` — version 3.26.2, published 2026-03-18

### Secondary (MEDIUM confidence)

- `features/support/test_support.rb` (codebase) — confirmed `World(TestSupport)` with same `Dir[test/support/*.rb].class_eval` pattern, meaning `webmock.rb` loads in Cucumber too
- `features/support/hooks.rb` (codebase) — confirmed existing prepend-stub pattern; Phase 64 does not conflict
- `config/environments/test.rb` (codebase) — confirmed `http_client_test_stubs.rb` load path; Phase 64 leaves untouched

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — version confirmed on rubygems.org
- Architecture: HIGH — source of `webmock/minitest.rb` inspected directly; auto-load path confirmed in codebase
- Pitfalls: HIGH — most derived from direct source reading, not inference

**Research date:** 2026-05-14
**Valid until:** 2026-11-14 (webmock is a stable, slow-moving library)
