# Requirements: Bookmarks — Milestone v1.19

**Defined:** 2026-05-14  
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1 Requirements

Milestone **v1.19 — HTTP test stubs → WebMock**: replace test-only prepend stub seams with WebMock (and retain Faraday `:test` adapter where `connection:` injection already covers the case).

### Test infrastructure (WebMock)

- [ ] **HTTP-01**: `webmock` is declared in the Gemfile `:test` group (and lockfile updated); Minitest loads WebMock configuration from `test/test_helper.rb` or `test/support/` with `WebMock.disable_net_connect!` (or equivalent) and explicit allowances for localhost / Capybara / Selenium as required so the suite does not flake on legitimate local traffic.
- [ ] **HTTP-02**: All Minitest examples that previously relied on `XClient.stub_fetch_*` / `MastodonClient.stub_fetch_result` (or equivalent prepend accessors) are rewritten to use **either** injected Faraday `:test` connections **or** WebMock stubs matching `api.twitter.com` / Mastodon host traffic; `test/http_client_test_stubs.rb` is no longer required for Minitest.
- [ ] **HTTP-03**: Cucumber `features/support/hooks.rb` (and any tag-specific hooks) no longer assign stub accessors on `XClient` / `MastodonClient`; external HTTP for `@mastodon_gadget`, `@x_gadget`, and the global `Before` hook is satisfied via WebMock request stubs that are installed and reset deterministically per scenario (no cross-scenario stub leakage beyond existing preference-reset policy in `CLAUDE.md`).
- [ ] **HTTP-04**: `config/environments/test.rb` does not `require` the prepend stub file; `test/http_client_test_stubs.rb` is **deleted** from the repository; tri-suite gate is green: `yarn run lint`, `bin/rails test`, `bundle exec rake dad:test` (Cucumber flake rerun policy per `CLAUDE.md` unchanged).
- [ ] **HTTP-05**: `.planning/PROJECT.md` **Key Decisions** (and `CLAUDE.md` test guidance if present) document the new contract: prefer Faraday `:test` when the client accepts `connection:`; otherwise WebMock at the HTTP layer — no prepend/class-level stub accessors for these services.

## v2 Requirements

Deferred.

### OAuth / client refactors

- **HTTP-FUT-01**: Optional follow-up: extract small helper modules for repeated WebMock JSON fixtures for X v2 and Mastodon public API to reduce duplication (only if duplication hurts maintenance after HTTP-02/03).

## Out of Scope

| Item | Reason |
|------|--------|
| Production code behavior change for `XClient` / `MastodonClient` beyond what tests force you to touch | Milestone is test-isolation only unless a minimal seam is required |
| Replacing all Faraday `:test` usages with WebMock | Keep `:test` where it already gives clearer unit coverage |
| VCR cassette library | WebMock-only scope unless team expands later |
| `XAUTH-FUT-01` (`from_omniauth` lookup by `uid`) | Tracked separately in PROJECT Active list; not required for WebMock milestone closure |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HTTP-01 | Phase 64 | Pending |
| HTTP-02 | Phase 65 | Pending |
| HTTP-03 | Phase 66 | Pending |
| HTTP-04 | Phase 66 | Pending |
| HTTP-05 | Phase 66 | Pending |

**Coverage:**  
- v1 requirements: 5 total  
- Mapped to phases: 5  
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-14*  
*Last updated: 2026-05-14 after `/gsd-new-milestone`*
