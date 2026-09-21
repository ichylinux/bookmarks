# Phase 133: Test Coverage & Tri-Suite Gate - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

Full test coverage for v1.37.1 feed visit recording and history flows. Minitest for recording + history index edge cases; Cucumber E2E for feed click → history page → reopen. Tri-suite gate: yarn lint + scoped Minitest + related Cucumber green.

</domain>

<decisions>
## Implementation Decisions

### Minitest scope
- Extend visited_link model tests and feed_article_histories controller tests if gaps remain from Phases 131–132 smoke tests
- Cover: feed-only source filter, per-user isolation, newest-first ordering, empty state, open_links_in_new_tab link target

### Cucumber
- New or extended feature file in Japanese (`# language: ja`) per project convention
- Scenario: user opens feed article from gadget → visits history page → sees title → clicks to reopen
- Use browser-driven flow; WebMock/stubs as needed for feed gadget content

### Gate
- `yarn run lint` (full)
- Scoped Minitest: test/models/visited_link_test.rb, test/controllers/visited_links_controller_test.rb, test/controllers/feed_article_histories_controller_test.rb, test/assets/visited_links_js_contract_test.rb
- Scoped Cucumber: new/related feature path only — not full dad:test suite

### Claude's Discretion
- Feature file naming and step definition placement
- Whether to extend features/08.訪問済みリンク.feature or create new feed history feature

</decisions>

<code_context>
## Existing Code Insights

- Phase 131: visited_links recording with title/source
- Phase 132: feed_article_histories index + nav
- features/08.訪問済みリンク.feature — existing visited link E2E patterns
- test/controllers/feed_article_histories_controller_test.rb — smoke tests from Phase 132

</code_context>

<specifics>
## Specific Ideas

- TEST-01, TEST-02 requirements
- Do not run full bin/rails test or full dad:test — scoped only per CLAUDE.md

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>
