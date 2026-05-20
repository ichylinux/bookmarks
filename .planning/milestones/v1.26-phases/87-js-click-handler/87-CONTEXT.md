# Phase 87: JS Click Handler - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Create `visited_links.js` — a pure IIFE delegated click handler on `.gadget ol li a[href]`. On click: strip fragment from `this.href`, fire-and-forget `$.post` to `/visited_links`, and optimistically add `.link--visited` to the clicked element. Completing the end-to-end v1.26 feature.

</domain>

<decisions>
## Implementation Decisions

### JS Architecture
- Pure IIFE — no `window.visitedLinks` export needed; handler is fire-and-forget with no public API
- File: `app/assets/javascripts/visited_links.js`
- Handler: `$(document).on('click.visitedLinks', '.gadget ol li a[href]', function() { ... })`
- CSRF token supplied automatically by `jquery_ujs.js` `$.ajaxPrefilter` — no manual CSRF plumbing

### Fragment Stripping
- `url.replace(/#.*$/, '')` — mirrors Ruby `normalize_url` regex exactly for consistency
- Applied to `this.href` (DOM-resolved absolute URL, not the raw `href` attribute)

### Error Handling
- Fire-and-forget: no `.fail()` handler, no revert on failure
- Optimistic `$(this).addClass('link--visited')` fires before `$.post`
- Rationale: visited state is best-effort; next full page load corrects from server state

### Tests
- Ruby contract test: assert `visited_links.js` file contains `click.visitedLinks` string
- Cucumber scenario: E2E click-to-class flow — user clicks a gadget link, `.link--visited` class appears on the element
- Contract test location: `test/contract/visited_links_js_test.rb` (or append to existing contract test file if present)

### the agent's Discretion
- Exact Cucumber feature file and scenario wording (Japanese, per project conventions)
- Whether to add Cucumber scenario to existing feature file or a new one

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/assets/javascripts/flash_messages.js` — simple IIFE pattern (no namespace export)
- `app/assets/javascripts/portal_lazy.js` — window namespace pattern (not needed here)
- `jquery_ujs.js` — provides `$.ajaxPrefilter` CSRF token injection automatically
- `visited_links_path` route helper → `/visited_links` (POST, from Phase 84)

### Established Patterns
- All gadget JS files are loaded via `require_tree .` in `application.js` — new file is auto-included
- ESLint flat config enforces `function` callbacks when `this` is DOM element — the click handler `function()` is correct; arrow functions would lose `this` binding
- Cucumber features are in Japanese (`# language: ja`)

### Integration Points
- `app/assets/javascripts/visited_links.js` — new file, auto-included by Sprockets
- `test/contract/` — contract test for JS file content
- `features/` — Cucumber E2E scenario

</code_context>

<specifics>
## Specific Ideas

- The handler must NOT call `e.preventDefault()` — the link should navigate normally; the POST is side-effect only
- `$(this)` is the `<a>` element — `this.href` is the browser-resolved absolute URL (includes protocol, host, path)
- JS fragment strip: `var url = this.href.replace(/#.*$/, '')`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
