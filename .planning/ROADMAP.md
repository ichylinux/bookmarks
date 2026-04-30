# Roadmap: Bookmarks

## Milestones

- ✅ **v1.1 — Modern JavaScript** — Phases 2–4 (shipped 2026-04-27) — [archived](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 — Modern Theme** — Phases 5–9 (shipped 2026-04-29) — [archived](milestones/v1.2-ROADMAP.md)
- 🚧 **v1.3 — Quick Note Gadget** — Phases 10–13 (in progress)

## Phases

<details>
<summary>✅ v1.2 — Modern Theme (Phases 5–9) — SHIPPED 2026-04-29</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).

- [x] **Phase 5: Theme Foundation** (2/2 plans) — completed 2026-04-28
- [x] **Phase 6: HTML Structure** (1/1 plan) — completed 2026-04-29
- [x] **Phase 7: Drawer CSS + Animation** (1/1 plan) — completed 2026-04-29
- [x] **Phase 8: Drawer JS Interaction** (1/1 plan) — completed 2026-04-29
- [x] **Phase 9: Full-Page Theme Styles** (1/1 plan) — completed 2026-04-29

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 5. Theme Foundation | v1.2 | 2/2 | Complete | 2026-04-28 |
| 6. HTML Structure | v1.2 | 1/1 | Complete | 2026-04-29 |
| 7. Drawer CSS + Animation | v1.2 | 1/1 | Complete | 2026-04-29 |
| 8. Drawer JS Interaction | v1.2 | 1/1 | Complete | 2026-04-29 |
| 9. Full-Page Theme Styles | v1.2 | 1/1 | Complete | 2026-04-29 |

</details>

<details>
<summary>✅ v1.1 — Modern JavaScript (Phases 2–4) — SHIPPED 2026-04-27</summary>

The full phase details, success criteria, and plan list live in [`.planning/milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).

- [x] **Phase 2: JavaScript tooling baseline** (2/2 plans) — completed 2026-04-27
- [x] **Phase 3: Modernize application scripts** (2/2 plans) — completed 2026-04-27
- [x] **Phase 4: Verify and document** (2/2 plans) — completed 2026-04-27

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 2. JavaScript tooling | v1.1 | 2/2 | Complete | 2026-04-27 |
| 3. Modernize scripts | v1.1 | 2/2 | Complete | 2026-04-27 |
| 4. Verify and document | v1.1 | 2/2 | Complete | 2026-04-27 |

</details>

---

### 🚧 v1.3 Quick Note Gadget (In Progress)

**Milestone Goal:** Add a note-taking tab to the simple theme's welcome page so users can jot and review personal notes without leaving the app.

- [x] **Phase 10: Data Layer** - Migration, Note model, and user ownership foundation — completed 2026-04-30
- [x] **Phase 11: Notes Controller** - Create action, auth guard, per-user scoping, and backend tests (completed 2026-04-30)
- [ ] **Phase 12: Tab UI** - Tab nav links, panel switching, theme isolation, and post-save redirect (human verification pending)
- [ ] **Phase 13: Note Gadget + Integration Tests** - Note form partial, reverse-chronological list, and full-cycle integration tests

## Phase Details

### Phase 10: Data Layer
**Goal**: The `notes` table exists with correct schema, the `Note` model enforces ownership and validation, and the foundation for per-user data isolation is in place before any controller or view code is written.
**Depends on**: Phase 9 (existing app baseline)
**Requirements**: NOTE-03
**Success Criteria** (what must be TRUE):
  1. `db/schema.rb` contains a `notes` table with `user_id`, `body` (text, not null), `created_at`, `updated_at`, and a composite index on `(user_id, created_at)`
  2. `Note` model has `belongs_to :user`, `validates :body, presence: true`, and uses the `Crud::ByUser` concern
  3. `User` model has `has_many :notes` (no `dependent: :destroy` — account disable is normal; unbounded synchronous cascade on user destroy is avoided)
  4. `resources :notes, only: [:create, :destroy]` is present in `config/routes.rb`
  5. Running `rails db:migrate` completes without error and the schema reflects the new table
**Plans**: 3 plans
- [x] 10-01-PLAN.md — Migration: create notes table with composite index, run db:migrate
- [x] 10-02-PLAN.md — Note model + notes.yml fixture stub + model unit tests
- [x] 10-03-PLAN.md — User has_many :notes association + routes :notes resource

### Phase 11: Notes Controller
**Goal**: Users can POST a new note and have it persisted to their account — the controller enforces authentication, scopes all queries to `current_user`, and rejects invalid input — verified entirely by Minitest before any view is touched.
**Depends on**: Phase 10
**Requirements**: NOTE-01
**Success Criteria** (what must be TRUE):
  1. An authenticated POST to `/notes` with valid body params creates a `Note` record owned by `current_user` and redirects to `root_path(tab: 'notes')`
  2. A POST with a blank body does not create a record and returns a response the caller can handle (redirect with flash or unprocessable entity)
  3. An unauthenticated POST to `/notes` is redirected to the sign-in page (Devise auth guard active)
  4. `user_id` is never accepted via strong params — it is always merged from `current_user.id` server-side
  5. `NotesController` tests pass: auth, scoping, validation failure, and redirect all covered in `notes_controller_test.rb`
**Plans**: 1 plan
- [x] 11-01-PLAN.md — Routes create-only, `NotesController#create`, `notes_controller_test.rb`
**UI hint**: no

### Phase 12: Tab UI
**Goal**: The simple theme welcome page shows "ホーム" and "ノート" tab links; clicking between them switches the visible panel; after saving a note the page returns to the Note tab — and none of this appears on the modern or classic themes.
**Depends on**: Phase 11
**Requirements**: TAB-01, TAB-02, TAB-03
**Success Criteria** (what must be TRUE):
  1. Visiting the simple theme welcome page shows two tab links ("ホーム" and "ノート") and the home panel is active by default
  2. Clicking "ノート" hides the home panel and shows the notes panel; clicking "ホーム" reverses this — no page reload required
  3. After a successful note save, the redirect lands on the welcome page with the Note tab active (not the Home tab)
  4. Switching to the modern or classic theme and visiting the welcome page shows no tab links and no tab panels
  5. All tab-related CSS lives under `.simple { }` in `welcome.css.scss`; no tab styles appear in `common.css.scss`
**Plans**: 2 plans
- [x] 12-01-PLAN.md — ERB 二パネル + `welcome.css.scss` の `.simple` タブスタイル + `notes_tabs.js`
- [x] 12-02-PLAN.md — Welcome 統合テスト（TAB-01/03/SC4）+ TAB-02 手動 UAT チェックポイント
**UI hint**: yes

### Phase 13: Note Gadget + Integration Tests
**Goal**: The Note tab panel contains a working textarea form and a reverse-chronological list of the user's saved notes — and the complete request cycle (load page, save note, return to tab, see note) is verified by integration tests.
**Depends on**: Phase 12
**Requirements**: NOTE-02
**Success Criteria** (what must be TRUE):
  1. The Note tab panel shows a textarea and a Save button rendered via `_note_gadget.html.erb`
  2. Submitting the form saves the note and the new note appears at the top of the list on the redirected page
  3. Notes are displayed in reverse-chronological order with body text and a readable timestamp per note
  4. When the user has no notes, an empty-state message ("メモはまだありません") is shown instead of an empty list
  5. Integration tests cover: load note tab, submit note form, verify note appears in list, verify another user's notes are not visible
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 10. Data Layer | v1.3 | 3/3 | Complete | 2026-04-30 |
| 11. Notes Controller | v1.3 | 1/1 | Complete    | 2026-04-30 |
| 12. Tab UI | v1.3 | 2/2 | Human UAT |  |
| 13. Note Gadget + Integration Tests | v1.3 | 0/? | Not started | - |

---
*Last updated: 2026-04-30 — Phase 11 planned (11-01); ready for execute*
