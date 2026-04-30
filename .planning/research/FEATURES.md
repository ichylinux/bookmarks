# Feature Research

**Domain:** Personal note-taking gadget (textarea + save + list) within an existing Rails personal bookmark app
**Researched:** 2026-04-30
**Confidence:** HIGH — scope is tightly constrained by the milestone definition and the existing codebase patterns are fully readable

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Textarea input for new note | Every note-taking surface starts with a place to type | LOW | Single `<textarea>` element; no rich-text needed for v1.3 |
| Save button | User needs explicit confirmation the note was captured | LOW | Standard form POST; no AJAX strictly required but consistent with existing todos pattern |
| Reverse-chronological list of saved notes | Notes are only useful if they can be reviewed; newest-first is the universal convention | LOW | `Note.where(user_id: ...).order(created_at: :desc)` |
| Per-user data isolation | This is a logged-in personal app; notes must never be visible to another user | LOW | Already enforced by `Crud::ByUser` pattern used on every other model |
| "Note" tab on the simple theme welcome page | Defined in milestone scope; without the tab the feature is unreachable | LOW | Tab links sit beside the existing "Home" link in the simple-theme nav; controlled by CSS show/hide or a query param |
| Empty-state message | When no notes exist the list area must not silently show nothing | LOW | A single line of Japanese text, e.g. "メモはまだありません" |

### Differentiators (Competitive Advantage)

Features that set this tool apart within the personal app context. Not required, but improve daily value.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Note body shown in the list (not just a title) | A quick-note gadget is most useful when you can glance at the content without clicking into a detail page | LOW | Render the full `body` column in the list row; no separate show page needed for v1.3 |
| Timestamp shown per note | Personal notes age; knowing when something was jotted is useful context | LOW | `note.created_at` formatted with `strftime` or Rails `time_ago_in_words` |
| Delete note from the list | Captured notes accumulate; users need a way to clean up | LOW | A destroy link per list item; consistent with todo delete pattern; requires confirm dialog |
| Auto-clear textarea after save | Improves capture flow — after saving, textarea is blank and ready for the next note | LOW | In AJAX path: clear `textarea.val('')` after success; in full-page path: redirect clears naturally |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Rich-text / Markdown editor | Users ask for formatting | Adds a JS dependency (Trix or similar), conflicts with keep-Sprockets constraint, disproportionate for a quick-note gadget | Plain `<textarea>` with `white-space: pre-wrap` CSS to preserve line breaks |
| Edit existing note in-place | Feels complete | Doubles implementation surface (edit form, update action, JS replace); a quick-note gadget's value is speed of capture, not document editing | Delete-and-retype is acceptable for v1.3; inline edit is a v2 consideration |
| Note categories / tags | Power-user request | Adds schema complexity (join table or serialized column), adds UI complexity, disproportionate for v1.3 | Keep notes flat; add tags only if usage data justifies it |
| Full-text search | Useful at scale | Not needed for a personal app with a short list; adds controller and query complexity | Browser Ctrl+F works fine on a short in-page list |
| Real-time auto-save (draft persistence) | Reduces risk of losing text | Requires debounce JS and a separate draft endpoint; overkill when save button is one click away | Standard form submit is sufficient |

## Feature Dependencies

```
[Note tab UI (Home/Note links on simple theme page)]
    └──requires──> [WelcomeController serves simple-theme tab state]
                       └──requires──> [Note model + notes table in DB]
                                          └──requires──> [Migration: create_notes]

[Note list (reverse-chronological)]
    └──requires──> [Note#create (save action) — list is only meaningful once save exists]

[Delete note from list]
    └──requires──> [Note list — delete action appears as a link per list row]

[Auto-clear textarea after save]
    └──requires──> [AJAX save path — only relevant if save is done without full page reload]

[Empty-state message]
    └──enhances──> [Note list — renders when list is empty]

[Timestamp per note]
    └──enhances──> [Note list — extra column in each list row]
```

### Dependency Notes

- **Note list requires Note#create:** There is nothing to list until save exists. Create and list must be built together, or create-first then list immediately after.
- **Delete requires list:** Delete is a per-row action and cannot exist before the list renders rows.
- **Auto-clear requires AJAX path:** If save is a standard form submit (full page reload) the textarea clears naturally via redirect; auto-clear JS is only needed when using AJAX. The existing todos gadget uses AJAX for create; notes can follow the same pattern or use full-page submit — decide in implementation.
- **Tab UI requires WelcomeController change:** The simple theme welcome page currently renders the portal grid unconditionally. The tab mechanism (switching between Home and Note views) must be wired into `WelcomeController#index` before any note-specific content is visible. This is the first thing to build.

## MVP Definition

### Launch With (v1.3)

Minimum viable product for the Quick Note Gadget milestone.

- [ ] Migration: `notes` table with `user_id`, `body` (text, not null), `created_at`, `updated_at`, `deleted` (boolean, consistent with other models)
- [ ] `Note` model with `belongs_to :user`, `Crud::ByUser`, soft-delete consistent with existing models
- [ ] `NotesController` with `create` and `destroy` actions (index not needed — list rendered via WelcomeController)
- [ ] "Home" and "Note" tab links on the simple theme welcome page
- [ ] Note tab view: `<textarea>` + Save button form
- [ ] Note tab view: reverse-chronological list of saved notes showing body text and timestamp
- [ ] Empty-state message when no notes exist
- [ ] Per-user data isolation enforced (scoped query + `deletable_by?` guard on destroy)

### Add After Validation (v1.x)

Features to add once core is confirmed working.

- [ ] Delete note from list — low complexity, high user value; add when list is confirmed working
- [ ] Auto-clear textarea after save (AJAX path) — add when UX feedback indicates the page reload feels slow

### Future Consideration (v2+)

Features to defer until a later milestone explicitly opens them.

- [ ] Inline edit of existing notes — only if users request it; doubles action surface
- [ ] Note categories or tags — only if note volume grows to the point where filtering is needed
- [ ] Note search — not needed while the list is short enough to scan visually

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Migration + Note model | HIGH | LOW | P1 |
| Tab links (Home / Note) | HIGH | LOW | P1 |
| Textarea + Save button | HIGH | LOW | P1 |
| Reverse-chronological list | HIGH | LOW | P1 |
| Per-user isolation | HIGH | LOW | P1 — non-negotiable |
| Empty-state message | MEDIUM | LOW | P1 |
| Timestamp per note | MEDIUM | LOW | P1 — include in initial list render; near-zero extra cost |
| Delete note | HIGH | LOW | P2 |
| Auto-clear textarea (AJAX) | MEDIUM | LOW | P2 |
| Inline edit | MEDIUM | MEDIUM | P3 |
| Categories / tags | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

This is a personal, single-user note-taking gadget embedded inside a larger personal app, not a standalone product competing in the note-taking market. The reference point is the internal consistency of this app's existing gadgets.

| Feature | Todos gadget (existing) | Bookmarks gadget (existing) | Notes gadget (proposed v1.3) |
|---------|------------------------|----------------------------|------------------------------|
| Create item | AJAX form inline, no page reload | Full-page form | Full-page form (simplest); AJAX can be added in P2 |
| List items | Inline in gadget panel | Separate index page | Inline in Note tab panel |
| Delete item | AJAX, soft-delete, per-row | Full-page, soft-delete | Link per row, soft-delete (P2) |
| Per-user scope | `Crud::ByUser` | `Crud::ByUser` | `Crud::ByUser` |
| Edit item | Inline double-click | Separate edit page | Deferred to v2 |

Using the todos gadget as the closest implementation reference keeps code patterns consistent and introduces no new conventions.

## Sources

- Codebase review: `/home/ichy/workspace/bookmarks/app/` (controllers, models, views, JS assets)
- Schema: `/home/ichy/workspace/bookmarks/db/schema.rb`
- Milestone definition: `/home/ichy/workspace/bookmarks/.planning/PROJECT.md`
- Pattern reference: `app/models/concerns/gadget.rb`, `app/models/crud/by_user.rb`, `app/controllers/todos_controller.rb`, `app/assets/javascripts/todos.js`, `app/views/welcome/_todo_gadget.html.erb`

---
*Feature research for: Quick Note Gadget (v1.3) — simple theme, personal bookmark app*
*Researched: 2026-04-30*
