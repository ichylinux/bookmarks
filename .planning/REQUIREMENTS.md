# Requirements: v1.16 Mastodon Account Following

**Status:** Active
**Milestone:** v1.16
**Last updated:** 2026-05-12

---

## Milestone Goal

Users can follow public Mastodon accounts as live gadgets — register by profile URL, see a one-line preview of recent toots (with links) on the welcome page dashboard.

---

## v1.16 Requirements

### MAST — Mastodon Account Management

- [ ] **MAST-01**: User can add a Mastodon account to follow by entering a profile URL (e.g. `https://ruby.social/@FastRuby`)
- [ ] **MAST-02**: User can view a list of their followed Mastodon accounts
- [ ] **MAST-03**: User can edit a followed Mastodon account (profile URL, display count)
- [ ] **MAST-04**: User can delete a followed Mastodon account from the list

### MAST — API Integration

- [ ] **MAST-05**: App parses the profile URL before save to extract instance host and username; normalized values are stored on the record
- [ ] **MAST-06**: App fetches up to `display_count` recent toots from the public Mastodon REST API (no OAuth) using a `MastodonClient` service class with explicit HTTP timeouts
- [ ] **MAST-07**: Toot HTML content is stripped to plain text and truncated to a one-line preview (~100 chars)

### MAST — Welcome Page Gadget

- [ ] **MAST-08**: Each followed Mastodon account appears as a collapsible AJAX-loaded gadget panel on the welcome page (same pattern as RSS feed gadgets)
- [ ] **MAST-09**: Each toot preview in the gadget links to the original toot URL on the Mastodon instance

### MAST — Locale

- [ ] **MAST-10**: All Mastodon UI chrome (headings, labels, empty-state messages, error messages) is available in Japanese and English

### MAST — Test Coverage

- [ ] **MAST-11**: `MastodonAccount` model and `MastodonAccountsController` are covered by Minitest with stubbed API calls
- [ ] **MAST-12**: A Cucumber E2E scenario verifies the Mastodon gadget appears and loads toots on the welcome page

---

## Future Requirements (Deferred)

- Store the resolved Mastodon numeric account ID in the DB to skip the `/lookup` call on every page load
- Exclude reblogs toggle per account (`exclude_reblogs` parameter on `/statuses`)
- User-defined display label per account
- Response caching (e.g., 5-minute Rails cache) to reduce API calls on repeated page loads

---

## Out of Scope

- OAuth / authenticated Mastodon access — public API is sufficient for read-only following
- Posting, replying, boosting — this is a read-only gadget
- Notifications or streaming — no background jobs or WebSocket in this milestone
- Following private/locked accounts — public API only
- Background job for fetching toots — live on-page-load is the established pattern

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| MAST-01 | Phase 53 | pending |
| MAST-02 | Phase 53 | pending |
| MAST-03 | Phase 53 | pending |
| MAST-04 | Phase 53 | pending |
| MAST-05 | Phase 52 | pending |
| MAST-06 | Phase 54 | pending |
| MAST-07 | Phase 54 | pending |
| MAST-08 | Phase 55 | pending |
| MAST-09 | Phase 54 | pending |
| MAST-10 | Phase 53 | pending |
| MAST-11 | Phase 56 | pending |
| MAST-12 | Phase 56 | pending |
