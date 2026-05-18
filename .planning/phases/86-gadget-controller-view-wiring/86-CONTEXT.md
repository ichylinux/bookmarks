# Phase 86: Gadget Controller + View Wiring - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire `@visited_urls` into the three gadget show actions (FeedsController, MastodonAccountsController, XAccountsController) and add `class: visited_link_class(...)` to item content links in the three show partials. No JS yet — server renders the class based on state at request time.

</domain>

<decisions>
## Implementation Decisions

### Controller Assignment
- Use `before_action :assign_visited_urls, only: [:show]` with a shared private method in each controller — DRY, matches existing before_action patterns
- `assign_visited_urls` sets `@visited_urls = VisitedLink.urls_for(current_user)` — single query per request
- `@visited_urls` is NOT assigned in WelcomeController#index (AJAX-only, per Phase 84 decisions)

### View Wiring
- Add `class: visited_link_class(@visited_urls, url)` to item content links only — the `<li>` loop links (`e.url` in feeds, `item[:url]` in mastodon/x)
- Title/profile links are excluded — they link to account pages, not tracked content
- Matches Phase 87 JS selector `.gadget ol li a[href]` (consistent DOM targeting)

### Keyword Merge
- Use `link_to text, url, **link_opts, class: visited_link_class(@visited_urls, url)` — keyword merge
- `link_opts` confirmed to contain no `class:` key (no conflict)

### Nil Guard
- `visited_link_class(nil, url)` returns `""` — helper guards with `visited_set&.include?` to handle unauthenticated or edge cases
- Note: controllers only reach show when `authenticate_user!` is satisfied, so @visited_urls should never be nil in practice

### the agent's Discretion
- Exact placement of before_action in each controller file (after existing before_actions)
- Private method naming: `assign_visited_urls`

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VisitedLink.urls_for(current_user)` — returns Ruby Set (Phase 84)
- `ApplicationHelper#visited_link_class(visited_set, url)` — returns "link--visited" or "" (Phase 85)
- `link_opts` helper in gadget views — existing hash passed to all link_to calls

### Established Patterns
- before_action pattern: existing controllers use `before_action :preload_feed, only: [:show, :update, :destroy]` — same style
- FeedsController#show, MastodonAccountsController#show, XAccountsController#show already exist with item-list rendering

### Integration Points
- `app/controllers/feeds_controller.rb` — add before_action + private method
- `app/controllers/mastodon_accounts_controller.rb` — add before_action + private method
- `app/controllers/x_accounts_controller.rb` — add before_action + private method
- `app/views/feeds/show.html.erb` — add `class:` to feed item link_to
- `app/views/mastodon_accounts/show.html.erb` — add `class:` to toot link_to
- `app/views/x_accounts/show.html.erb` — add `class:` to tweet link_to
- `test/controllers/` — controller tests for class presence/absence and N+1 guard

</code_context>

<specifics>
## Specific Ideas

- Phase 84 decision: `@visited_urls` assigned once per gadget show action — verified by assert_queries(1) or SQL query count in tests
- Unvisited links must carry NO visited class — test for absence as well as presence

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
