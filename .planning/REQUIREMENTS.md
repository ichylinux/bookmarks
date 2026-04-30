# Requirements — v1.3 Quick Note Gadget

**Milestone:** v1.3
**Status:** Shipped (2026-04-30)
**Last updated:** 2026-04-30

## Milestone v1.3 Requirements

### Tab Navigation (simple theme only)

- [x] **TAB-01**: User sees "Home" and "Note" tab links on the simple theme welcome page
- [x] **TAB-02**: User can click "Note" to view the note tab panel; clicking "Home" returns to the portal grid
- [x] **TAB-03**: After saving a note, the page redirects back to the Note tab (not the Home tab)

### Note Gadget

- [x] **NOTE-01**: User can type text in a textarea and click Save to persist a new note
- [x] **NOTE-02**: User sees a reverse-chronological list of their previously saved notes below the form
- [x] **NOTE-03**: Notes are isolated per user — no user can read another user's notes

## Future Requirements

- Delete individual notes — deferred until core capture flow is confirmed
- Note gadget on modern and classic themes — deferred until simple theme proves out

## Out of Scope

- **Rich text / markdown editor** — conflicts with no-new-JS-deps constraint; plain textarea is the right call for a quick-capture tool
- **Inline editing of saved notes** — doubles the surface; out of scope for a capture-focused gadget
- **Real-time autosave** — overkill; explicit save is the correct UX for a deliberate capture action
- **Pagination of note list** — not needed at personal-app scale for v1.3

## Traceability

| REQ-ID | Phase | Plan |
|--------|-------|------|
| TAB-01 | Phase 12 | — |
| TAB-02 | Phase 12 | — |
| TAB-03 | Phase 12 | — |
| NOTE-01 | Phase 11 | — |
| NOTE-02 | Phase 13 | — |
| NOTE-03 | Phase 10 | — |

---
*Requirements defined: 2026-04-30 — v1.3 milestone*
*Traceability filled: 2026-04-30 — roadmap created*
