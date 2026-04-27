# Phase 1: Automatic Title Scrape for New Bookmark — Context

**Gathered:** 2026-04-27
**Status:** Ready for planning
**Source:** Inline questioning

<domain>
## Phase Boundary

When a user creates a new bookmark, the title field should be auto-filled from the page's `<title>` tag when the user blurs the URL field. The title remains editable. This phase adds a server-side proxy endpoint and client-side JS — no background jobs.

</domain>

<decisions>
## Implementation Decisions

### Trigger
- Auto-fill happens **client-side on URL field blur** (not on save)
- JS fires an AJAX GET to a Rails proxy endpoint when the user leaves the URL field

### Server endpoint
- Route: `GET /bookmarks/fetch_title?url=<url>` (collection action)
- Controller: `BookmarksController#fetch_title`
- Uses **Faraday** (already in Gemfile) to fetch the URL, **Nokogiri** (already in Gemfile) to parse `<title>`
- Returns the title as `render plain:`
- On any error (network, timeout, non-HTML, missing title): return `head :ok` (empty body)
- Authentication: must be behind `before_action :authenticate_user!` (same as all other actions)

### Client-side behaviour
- JS lives in `app/assets/javascripts/bookmarks.js` (new file, following `feeds.js` pattern)
- On `blur` of `#bookmark_url`: if URL non-empty, send AJAX GET to fetch_title endpoint
- On success: if returned title is non-empty AND `#bookmark_title` is currently empty, fill it
- If title already filled by user, **do not overwrite** (locked-unless-blank rule)
- On error or empty response: silent — leave title blank

### Error handling
- Server: rescue all exceptions, return `head :ok`
- Client: jQuery `.fail()` handler does nothing (silent)

### Claude's Discretion
- HTTP timeout value for the Faraday fetch (suggest 5s)
- Whether to strip/clean the title string (suggest `.strip`)
- Route placement (collection vs member — use collection)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing patterns to follow
- `app/controllers/feeds_controller.rb` — `get_feed_title` action: server-side title proxy pattern
- `app/assets/javascripts/feeds.js` — `feeds.get_feed_title`: jQuery AJAX → fill input pattern
- `app/views/bookmarks/_form.html.erb` — bookmark form field IDs (`bookmark_url`, `bookmark_title`)
- `config/routes.rb` — route conventions (resources with collection actions)
- `Gemfile` — Faraday and Nokogiri already present, no new gems needed

</canonical_refs>

<specifics>
## Specific Ideas

- Follow `feeds.js` / `FeedsController#get_feed_title` as the direct analog
- Field IDs in form: `bookmark_url` (URL input), `bookmark_title` (title input)
- The `get_feed_title` endpoint uses POST + form serialization; for bookmarks use GET + query param since it's read-only and simpler
- Nokogiri parse: `Nokogiri::HTML(response.body).at('title')&.text&.strip`

</specifics>

<deferred>
## Deferred Ideas

- Server-side fallback on save (not requested)
- Background job / async title fetch (not requested)
- Title scraping for edit form (not requested — new bookmark only)

</deferred>

---

*Phase: 01-automatic-title-scrape*
*Context gathered: 2026-04-27*
