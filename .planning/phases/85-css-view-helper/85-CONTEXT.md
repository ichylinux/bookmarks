# Phase 85: CSS + View Helper - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the visual vocabulary for visited links: a `.link--visited` CSS class in `common.css.scss` and an `ApplicationHelper#visited_link_class` helper. No gadget wiring yet — this phase only makes the building blocks available and verifiable.

</domain>

<decisions>
## Implementation Decisions

### Visual Style
- Use `opacity: 0.55` to dim visited links — device-agnostic, works across all three themes without color knowledge
- Class applies on the `<a>` tag itself (Phase 86/87 will add `class:` to anchor elements)
- No CSS transition — instant visual feedback, simpler CSS
- Scope selector to `.gadget a.link--visited` to limit to gadget content links only

### CSS Specificity
- Use `.gadget a.link--visited` (specificity 0,2,1) to beat existing theme `:visited` rules without `!important`
- Defined in `common.css.scss` — single definition covers all three themes (classic, modern, simple)

### Test Design
- Contract test: file-content grep asserting `common.css.scss` contains `.link--visited` selector string — fast, no compilation needed
- Helper tests in `test/helpers/application_helper_test.rb` (new file, Rails convention)
- Helper unit tests cover both truthy branch (URL in set → "link--visited") and falsy branch (URL not in set → "")

### the agent's Discretion
- Exact indentation/comment style in common.css.scss follows the file's existing conventions
- Test class naming follows existing Rails helper test conventions

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/helpers/application_helper.rb` — existing module with `changelog_entries`; `visited_link_class` goes here
- `app/models/visited_link.rb` — `normalize_url` class method; helper must call `VisitedLink.normalize_url(url)` before set lookup

### Established Patterns
- CSS: `common.css.scss` uses plain selectors without `!important`; specificity via selector depth (e.g., `.preferences-table > tbody > tr > th` at 0,1,3)
- Helpers: module methods in `ApplicationHelper`; tested in `test/helpers/`
- Theme `:visited` overrides: `.modern div.gadgets div.gadget div div.title a:visited` is the highest-specificity existing rule — our `.gadget a.link--visited` at (0,2,1) beats it
- Existing muted color: `#999` and `#595757` used for secondary text — opacity approach avoids needing to know theme colors

### Integration Points
- `app/helpers/application_helper.rb` — add `visited_link_class(visited_set, url)` alongside `changelog_entries`
- `app/assets/stylesheets/common.css.scss` — add `.link--visited` rule block near end of file (after existing gadget/link rules)
- `test/helpers/application_helper_test.rb` — new file; requires `ApplicationHelper` include
- `test/contract/` or `test/helpers/` — contract test for CSS selector presence

</code_context>

<specifics>
## Specific Ideas

- The helper must normalize the URL via `VisitedLink.normalize_url(url)` before checking the set (fragment-stripping must be consistent with how records are stored)
- `visited_set` is a Ruby `Set` — use `Set#include?` for O(1) lookup

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>
