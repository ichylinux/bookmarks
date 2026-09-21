# Phase 132: History Page, Navigation & i18n - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

Dedicated feed-article history page at `/feed_article_histories`, linked from primary nav. Shows current user's feed-opened titles newest first; click reopens article honoring `open_links_in_new_tab`. Localized nav label, page heading, empty state (ja/en). Mastodon/X URL-only visits excluded.

</domain>

<decisions>
## Implementation Decisions

### Routing & controller
- New GET route: `/feed_article_histories` → `FeedArticleHistoriesController#index` (collection resource name avoids collision with `resources :feeds` `:id`)
- Scope query: `VisitedLink.where(user_id: current_user.id, source: 'feed').order(visited_at: :desc)`
- Require authentication (same as other nav pages via ApplicationController)
- No delete/edit actions — read-only index

### View
- Server-rendered index: heading + ordered list of title links
- Link target: honor `current_user.preference.open_links_in_new_tab?` (same pattern as `feeds/show.html.erb`)
- Empty state message when no feed history rows
- Simple list/table — match existing index page conventions (bookmarks/todos style), no new JS framework

### Navigation
- Add nav item in `common/_nav_sections.html.erb` primary section (after feeds or near feeds)
- New locale keys: `nav.feed_article_histories`, page title/heading, empty state — ja/en parity

### Claude's Discretion
- Icon choice for nav_item (reuse existing icon set or :feed variant)
- Exact HTML structure (ol vs table) following closest existing list page
- Whether to add scope on VisitedLink model (`feed_history_for(user)`)

</decisions>

<code_context>
## Existing Code Insights

### Reusable assets
- `VisitedLink` with `source='feed'` and `title` from Phase 131
- `common/_nav_sections.html.erb`, `common/_nav_item.html.erb` — nav wiring pattern
- `feeds/show.html.erb` — `open_links_in_new_tab` link_opts pattern
- `config/locales/ja.yml` / `en.yml` — nav.* keys

### Established patterns
- Controllers inherit ApplicationController, user-scoped queries
- Nav items use `t('nav.*')` keys
- i18n parity enforced by existing tests

### Integration points
- `config/routes.rb` — add route before or after feeds
- New controller + view under `feed_article_histories/`
- Nav partial update

</code_context>

<specifics>
## Specific Ideas

- HIST-01 through HIST-06 and I18N-01 map to this phase
- Tests deferred to Phase 133 unless minimal controller test aids development
- `/feeds` CRUD must remain unchanged

</specifics>

<deferred>
## Deferred Ideas

- History delete/manage (out of scope)
- Which-feed-source column (out of scope)
- Full tri-suite gate (Phase 133)

</deferred>
