# Requirements: v1.26 Visited Link Tracking

**Milestone:** v1.26
**Status:** Active
**Created:** 2026-05-18

## Milestone Goal

Users can have their clicked content links in feed, Mastodon, and X gadgets recorded server-side so that visited links render with a distinct visual style on all their devices.

---

## v1.26 Requirements

### Data Layer

- [ ] **DAT-01**: User's visited content links are persisted in a `visited_links` table (`user_id`, `url varchar(2083)`, `visited_at`) with a unique index on `(user_id, url(768))` to prevent duplicates
- [ ] **DAT-02**: `VisitedLink` model exposes `record!(user, url)` using `upsert` (atomic insert-or-ignore) and `urls_for(user)` returning a `Set` of normalized visited URLs for the given user
- [ ] **DAT-03**: URL normalization (`VisitedLink.normalize_url`) strips URL fragments (`#...`) and is applied identically on write (`record!`) and on read (`urls_for`)
- [ ] **DAT-04**: `POST /visited_links` endpoint accepts a `url` parameter, records a visit for `current_user` (CSRF-aware, upsert-or-ignore, 204 on success, 401 if unauthenticated)

### Visual Layer

- [ ] **VIS-01**: `.link--visited` CSS class defined in `common.css.scss` with specificity high enough to override existing theme `:visited` rules; applies a visually distinct style (e.g., dimmed color) to visited content links across all three themes
- [ ] **VIS-02**: `ApplicationHelper#visited_link_class(visited_set, url)` returns `"link--visited"` when the normalized URL is in the visited set, empty string otherwise

### Gadget Wiring

- [ ] **GAD-01**: Feed gadget AJAX show partial renders feed item links with `class: visited_link_class(...)` when the URL is in the user's visited set
- [ ] **GAD-02**: Mastodon gadget AJAX show partial renders toot links with `class: visited_link_class(...)` when the URL is in the user's visited set
- [ ] **GAD-03**: X/Twitter gadget AJAX show partial renders tweet links with `class: visited_link_class(...)` when the URL is in the user's visited set
- [ ] **GAD-04**: `@visited_urls` Set is assigned once per gadget show action via a single `VisitedLink.urls_for(current_user)` query (not per-link, no N+1)

### Client-side

- [ ] **JS-01**: `visited_links.js` IIFE registers a namespaced delegated click handler (`$(document).on('click.visitedLinks', '.gadget ol li a[href]', fn)`) that fires a fire-and-forget `$.post` to the visit endpoint and optimistically adds `.link--visited` to the clicked link
- [ ] **JS-02**: JS URL normalization strips the fragment from `this.href` (DOM-resolved absolute URL) before sending to the server, consistent with `VisitedLink.normalize_url`

---

## Future Requirements (deferred)

- Per-gadget visited/unread badge counts — low value at personal-app scale (5–10 items per gadget)
- Bulk mark-all-read action — deferred; item volume doesn't warrant it
- Visit expiry / cleanup job — `visited_links` table will not grow to problematic size for single-user
- Mark-as-unvisited (undo visit) — deferred; not in original scope
- Visited links history page — deferred; welcome-page visual distinction covers the need
- Real-time cross-tab / push sync — page reload is sufficient for cross-device sync
- Cucumber test isolation (`VisitedLink.delete_all` in `Before` hook) — recommended before adding Cucumber E2E scenarios in Phase 87; can be added as a quick fix if `dad:test` shows order-dependent failures

---

## Out of Scope

- Tracking navigation link clicks (gadget headers, profile links) — only content item links (`ol li a`) are tracked; header links are structural navigation
- URL normalization beyond fragment stripping — query-string normalization (e.g., removing UTM params) deliberately excluded; same URL with different query strings is a different visited entry
- Visited state for bookmarks list or other non-gadget surfaces — scope is welcome-page gadgets only
- SHA256 digest column — MySQL 8.0+ with utf8mb4 supports `varchar(768)` prefix index; using raw URL with length prefix is simpler and sufficient

---

## Traceability

| Requirement | Phase | Plan |
|-------------|-------|------|
| DAT-01, DAT-02, DAT-03 | Phase 84 | TBD |
| DAT-04 | Phase 84 | TBD |
| VIS-01, VIS-02 | Phase 85 | TBD |
| GAD-01, GAD-02, GAD-03, GAD-04 | Phase 86 | TBD |
| JS-01, JS-02 | Phase 87 | TBD |
