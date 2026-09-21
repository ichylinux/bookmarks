# Requirements: Bookmarks v1.37.1 — フィード記事の閲覧履歴

**Defined:** 2026-09-21
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience — now in their preferred language.

## v1.37.1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Recording (REC)

- [x] **REC-01**: User can click a feed article link and have its title and URL persisted for history
- [x] **REC-02**: User can click the same feed article again and still see a single history row, with last-visited time updated

### History (HIST)

- [ ] **HIST-01**: User can open a dedicated feed article history page from navigation
- [ ] **HIST-02**: User can see titles of RSS/Atom articles they previously opened, newest first
- [ ] **HIST-03**: User can click a history title and reopen the same article (honoring `open_links_in_new_tab`)
- [ ] **HIST-04**: User can see an empty state when they have no feed article history
- [ ] **HIST-05**: User can see only their own history
- ~~**HIST-06**~~: ~~User does not see Mastodon or X visits on the history page~~ — **Superseded 2026-09-21** by quick tasks 260921-opa / 260921-ot0: X and Mastodon gadget visits now appear on the history page alongside feed articles

### Internationalization (I18N)

- [ ] **I18N-01**: User can read nav, page heading, and empty state in Japanese or English

### Test (TEST)

- [ ] **TEST-01**: Recording and history index are covered by Minitest
- [x] **TEST-02**: Cucumber covers gadget click → history shows title → reopen (feed; extended to X/Mastodon post-ship)

## Future Requirements

None added this milestone. Standing deferred items remain in STATE.md.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Which-feed-source column | User chose title + reopen only |
| Delete / manage history rows | Not requested for v1.37.1 |
| Backfill of existing URL-only `visited_links` | No title/source to reconstruct |
| ~~Mastodon / X visit history~~ | ~~Feeds-only scope~~ — extended post-ship via quick tasks 260921-opa / 260921-ot0 |
| Changes to `/feeds` CRUD | Existing settings table stays as-is |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REC-01 | Phase 131 | Complete |
| REC-02 | Phase 131 | Complete |
| HIST-01 | Phase 132 | Pending |
| HIST-02 | Phase 132 | Pending |
| HIST-03 | Phase 132 | Pending |
| HIST-04 | Phase 132 | Pending |
| HIST-05 | Phase 132 | Pending |
| HIST-06 | Phase 132 | Superseded (X/Mastodon added post-ship) |
| I18N-01 | Phase 132 | Pending |
| TEST-01 | Phase 133 | Pending |
| TEST-02 | Phase 133 | Pending |

**Coverage:**

- v1.37.1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-09-21*
*Last updated: 2026-09-21 after roadmap creation*
