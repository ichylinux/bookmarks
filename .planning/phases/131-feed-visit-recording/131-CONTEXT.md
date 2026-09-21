# Phase 131: Feed Visit Recording - Context

**Gathered:** 2026-09-21
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

Feed article clicks persist title + URL on the existing `visited_links` store, and a second click updates last-visited time without a duplicate row. Mastodon/X visits remain URL-only (no title, no `source='feed'`).

</domain>

<decisions>
## Implementation Decisions

### Data model
- Extend existing `visited_links` table with nullable `title` (string) and `source` (string, nullable)
- Feed visits set `source='feed'` and persist article title from the clicked link text
- Mastodon/X and other gadget clicks continue URL-only recording — do not set title or feed source
- Use existing unique index on `(user_id, url)` — upsert updates `visited_at`, and for feed visits also updates `title`
- No backfill of existing URL-only rows

### API / controller
- Extend `POST /visited_links` to accept optional `title` and `source` params
- Only persist title/source when `source='feed'` (ignore title for non-feed requests)
- Keep `head :no_content` response — fire-and-forget from JS unchanged

### JavaScript
- Extend `visited_links.js` to detect feed gadget clicks and POST `{ url, title, source: 'feed' }`
- Feed gadget selector: `#feed_gadget` or feed-specific class — must NOT send title for Mastodon/X gadgets
- Title from link text (`$(this).text().trim()` or `this.textContent`)
- Keep optimistic `.link--visited` and fire-and-forget pattern from v1.26

### Claude's Discretion
- Exact migration column types/limits matching existing conventions
- Feed gadget DOM selector strategy (id vs data attribute)
- Whether to extend `VisitedLink.record!` signature or add `record_feed!` — prefer minimal change to existing call sites

</decisions>

<code_context>
## Existing Code Insights

### Reusable assets
- `app/models/visited_link.rb` — `record!`, `normalize_url`, upsert on `(user_id, url)`
- `app/controllers/visited_links_controller.rb` — single `create` action
- `app/assets/javascripts/visited_links.js` — delegated click on `.gadget:not(#bookmark_gadget):not(#todo) ol li a[href]`
- `app/views/feeds/show.html.erb` — feed entries with `link_to e.title, e.url`
- `test/controllers/visited_links_controller_test.rb` — idempotent upsert tests

### Established patterns
- Sprockets + jQuery, CSRF via jquery_ujs prefiler
- Unique index `index_visited_links_on_user_id_and_url` already enforces one row per URL per user
- v1.26 visited styling via `visited_link_class` helper — must not break

### Integration points
- Migration → model → controller → JS (feed-only title/source wiring)
- Existing Mastodon/X show views use same visited_links.js handler — must remain URL-only

</code_context>

<specifics>
## Specific Ideas

- STATE.md decisions: extend `visited_links` with nullable `title` + `source='feed'`; no new table
- Requirements REC-01/REC-02 map directly to this phase
- Tests deferred to Phase 133 — Phase 131 may add minimal model/controller tests if plan includes them

</specifics>

<deferred>
## Deferred Ideas

- History page UI (Phase 132)
- Full Minitest/Cucumber gate (Phase 133)
- History delete, feed-source column, backfill

</deferred>
