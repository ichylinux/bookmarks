# Pitfalls Research

**Domain:** Adding a note-taking tab + tab UI to an existing Rails 8.1 app (Sprockets + jQuery + SCSS + multi-theme)
**Researched:** 2026-04-30
**Confidence:** HIGH — based on direct inspection of all affected source files in this repo

---

## Critical Pitfalls

### Pitfall 1: Tab UI Leaks Into Non-Simple Themes

**What goes wrong:**
Tab markup and tab CSS added directly to `welcome/index.html.erb` or `welcome.css.scss` renders for all users regardless of their active theme. The `welcome/index.html.erb` view is shared by simple, modern, and classic themes — there is no per-theme view branching. If tab styles use bare selectors (`.tab`, `.tab-content`) without a `.simple` scope guard, those selectors activate for modern and classic theme users too, breaking their portal layout.

**Why it happens:**
The layout template switches themes via `<body class="<%= favorite_theme %>">`, but the view itself has no awareness of the active theme. Developers adding a new feature to the welcome page tend to write generic CSS, not realising it affects all body class variants.

**How to avoid:**
- Add all tab HTML inside a conditional: `<% if favorite_theme == 'simple' %>` in the view. The portal div (existing code) is rendered in an `else` branch or remains outside the condition for non-simple themes.
- Scope all tab CSS under `.simple` in `welcome.css.scss` (matching the pattern already used in `themes/simple.css.scss` which scopes rules as `.simple { ... }`).
- Do not add tab styles to `common.css.scss` — that file applies to all themes.

**Warning signs:**
- Modern or classic theme users see tab-like elements on the welcome page.
- `welcome.css.scss` contains `.tab { ... }` without a `.simple` wrapper.

**Phase to address:** Tab UI scaffolding — the very first phase, before writing any CSS.

---

### Pitfall 2: Note Ownership Not Enforced — Users Can Read Other Users' Notes

**What goes wrong:**
A `NotesController#index` that queries `Note.all` or `Note.where(...)` without scoping to `current_user` returns all notes from all users. Because this is a personal app with a single shared database, every user's notes are exposed to every other user. This is the same category of bug seen in the early versions of the existing `bookmarks_controller.rb` (before `readable_by?` was added).

**Why it happens:**
When adding a simple CRUD controller quickly, developers often write `@notes = Note.all` or `Note.where(id: params[:id])` for the first passing test, intending to scope later. "Later" becomes never.

The existing controllers (`bookmarks_controller.rb`, `todos_controller.rb`) all follow the pattern:
```ruby
@records = Model.where(user_id: current_user.id)
```
and include a `readable_by?(current_user)` guard on lookups. A new `NotesController` must do the same from the first line of code.

**How to avoid:**
- Scope every query: `Note.where(user_id: current_user.id)`.
- For `create`, merge `user_id: current_user.id` into strong params (same as `bookmark_params` and `todo_params`): do not permit `user_id` from the request.
- There is no show/edit/destroy on notes for v1.3 (just create and index), so no `readable_by?` guard is needed for individual record access — but add it preemptively if destroy is added.

**Warning signs:**
- `@notes = Note.all` or `Note.where(id: ...)` without `user_id: current_user.id`.
- `permit(:content, :user_id)` — `user_id` must never appear in the permitted params list.

**Phase to address:** Note model + controller phase. Security must be in the first working version, not added later.

---

### Pitfall 3: Mass Assignment — `user_id` Accepted from Request Params

**What goes wrong:**
If the `NotesController` permits `user_id` in strong params, an attacker can POST `note[user_id]=2` and create a note attributed to another user (or claim another user's data on update/destroy). The existing controllers prevent this by explicitly building `user_id: current_user.id` outside the params hash.

**Why it happens:**
A scaffold-generated controller (`rails generate scaffold Note content:text user:references`) adds `user_id` to the permitted params by default. Developers accept the scaffold output without reviewing security implications.

**How to avoid:**
- Never include `user_id` in `permit(...)`.
- Pattern from `todos_controller.rb` (verified in codebase):
  ```ruby
  def note_params
    ret = params.require(:note).permit(:content)
    ret = ret.merge(user_id: current_user.id) if current_user
    ret
  end
  ```

**Warning signs:**
- `params.require(:note).permit(:content, :user_id)` in the controller.
- Rails scaffold output not reviewed before commit.

**Phase to address:** Note model + controller phase (same phase as ownership scoping).

---

### Pitfall 4: N+1 Query When Listing Notes

**What goes wrong:**
For v1.3, notes display as a flat list under the form (no associations). However, if `user` association is accessed in the view (even accidentally, e.g., `note.user.email` in a debug line left in), each note triggers a separate `SELECT` for its user. With a personal app the scale is small, but the habit matters — and if tags, folders, or related models are added later, this becomes a real problem.

The more immediate N+1 risk: if notes ever render nested partials that call back to models (e.g., `render partial: 'note', collection: @notes` where the partial calls `note.some_association`), Rails will issue one query per note per association.

**Why it happens:**
`Note.where(user_id: current_user.id).order(created_at: :desc)` is a single query and safe. The N+1 appears when the view or partial navigates an association that was not eager-loaded.

**How to avoid:**
- For v1.3 (flat list, no associations on Note): use `Note.where(user_id: current_user.id).order(created_at: :desc)` — no eager loading needed.
- Add `bullet` gem (or check with `rack-mini-profiler`) in development if associations are added later.
- Do not call `note.user` anywhere in the note list partial.

**Warning signs:**
- Development log shows repeated `SELECT * FROM users WHERE id = ?` for each note in the list.
- Any `note.user.xxx` call in the view layer.

**Phase to address:** Note controller + list view phase.

---

### Pitfall 5: CSRF Token Missing or Broken on the Note Form

**What goes wrong:**
The note-create form uses `form_tag` or `form_with` to POST to `NotesController#create`. If the CSRF token is not included (or is included incorrectly), the controller raises `ActionController::InvalidAuthenticityToken`. This often surfaces as a redirect loop or a 422 when submitting the form after a session refresh.

A secondary risk: if the form submission is handled via jQuery AJAX (rather than a standard HTML form POST), the AJAX call must include `X-CSRF-Token` from the meta tag. The existing `welcome/index.html.erb` already does inline `$.post(...)` for portal state saving and manually passes `authenticity_token` in the params hash — a non-standard approach compared to Rails UJS. Copying that pattern for note submission is error-prone.

**Why it happens:**
- Using `form_tag` with `authenticity_token: false` or manually building the form `<form action=... method=post>` without `<%= csrf_meta_tags %>`.
- Copying the inline `$.post` pattern from `welcome/index.html.erb` without including `Rails.csrfToken()` or the meta tag token.

**How to avoid:**
- Use `form_with(url: notes_path, local: true)` for a standard synchronous form POST. Rails UJS handles CSRF automatically for `form_with`-generated forms.
- If using AJAX submission, use `$.ajax` with `headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }`, or use `Rails.ajax` from rails-ujs which handles this automatically.
- Do not copy the `authenticity_token: form_authenticity_token` inline pattern from `collect_portal_layout_params()` — that is a legacy pattern, not the standard Rails UJS approach.

**Warning signs:**
- 422 Unprocessable Entity on form submission in production (CSRF validation fails).
- `protect_from_forgery with: :exception` in `ApplicationController` (confirmed present) — this will raise, not silently ignore, so a broken CSRF setup will be visible immediately in development.

**Phase to address:** Note form + controller phase. Test form submission before calling it done.

---

### Pitfall 6: Tab State Lost on Page Reload

**What goes wrong:**
Tab switching implemented with jQuery `.show()` / `.hide()` holds state only in DOM memory. On page reload (after saving a note via a full-form POST), the browser returns the default tab (Home), so users who just saved a note on the Note tab are redirected to the Home tab. This creates a confusing "where did my note go?" moment.

**Why it happens:**
A redirect-after-POST (`redirect_to root_path`) re-renders `welcome#index` without any tab state. The JavaScript that showed the Note tab is gone.

**How to avoid:**
- Option A (simplest): After a successful note save, redirect to `root_path(tab: 'note')` and read that query param in JavaScript to activate the correct tab on load.
- Option B: Use `session[:active_tab]` on the server and pass it to the view as an instance variable.
- Option C: Use `localStorage` to persist the active tab key client-side and restore on `$(document).ready`.

Option A (URL param) is the recommended approach for this app — it is compatible with full-page renders, does not require session writes, and is testable.

**Warning signs:**
- After saving a note, the page returns to the Home tab.
- No query param, session, or localStorage logic for tab state persistence.

**Phase to address:** Tab switching JavaScript phase (combine tab JS implementation with the persistence decision from the start).

---

### Pitfall 7: Note Form Renders in Non-Simple Themes Due to Route/Controller Coupling

**What goes wrong:**
`NotesController` is a new resource route accessible at `/notes`. If navigation links (drawer nav in `application.html.erb`) inadvertently link to `/notes`, or if the Note model's `belongs_to :user` triggers callbacks in the user model that affect other themes, the note feature bleeds into the app broadly. More concretely: if `notes#create` redirects to `root_path` and `root_path` loads the portal view, modern/classic theme users who somehow POST to `/notes` get a confusing portal page with no note tab visible.

**Why it happens:**
Adding a new resource to `routes.rb` opens endpoints available to all authenticated users. The tab UI is scoped to the simple theme view, but the controller is theme-agnostic. If a user on the modern theme manually POSTs to `/notes`, they create a note but see no note list on their theme.

**How to avoid:**
- This is acceptable behavior for v1.3 — notes are explicitly a simple-theme feature. Document it.
- Do not add "Note" to the drawer nav in `application.html.erb` for v1.3.
- Keep the note form only inside the `<% if favorite_theme == 'simple' %>` block in the view.
- In `NotesController`, after create, redirect to `root_path` regardless of theme — this is safe since the note list is only visible on the simple theme.

**Warning signs:**
- A "Note" link appears in the drawer nav in `application.html.erb`.
- Modern/classic theme users see a note-related UI element.

**Phase to address:** Route + controller setup phase. Explicitly out-of-scope for non-simple themes; document the decision.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inline `<script>` for tab switching inside `welcome/index.html.erb` | No new file needed | Mixes JS logic with portal JS already in the view; adds to the already-complex inline block; hard to test | Only if tab JS is truly trivial (< 10 lines); otherwise move to `notes.js` |
| Skip tab state persistence (always land on Home tab) | Zero extra code | Every note save snaps users back to Home tab — jarring UX | Acceptable for v1.3 only if a fast follow-up adds persistence |
| No pagination on note list | Simple query | Note list grows unbounded; slow query and long page for heavy users | Acceptable for v1.3 (personal app, limited notes expected); add `limit` from the start: `.order(created_at: :desc).limit(50)` |
| `Note.all` scoped later | First test passes immediately | Security hole if deployed without the scope | Never — scope on first write |
| Copy `authenticity_token: form_authenticity_token` AJAX pattern from portal save | Consistent with existing code | Non-standard; bypasses Rails UJS CSRF handling; breaks if the meta tag approach is ever adopted | Never for new code |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `welcome/index.html.erb` + tab HTML | Adding tab HTML unconditionally, affecting all themes | Wrap in `<% if favorite_theme == 'simple' %>` — only the simple theme gets tabs |
| `welcome.css.scss` + tab styles | Adding `.tab { ... }` at root level | Wrap all tab styles under `.simple { .tab { ... } }` |
| `NotesController` + user scoping | `Note.where(...)` without `user_id: current_user.id` | Always scope to `current_user.id` from the first line of code |
| `form_with` + CSRF | Using `form_tag` with `authenticity_token: false` or manual AJAX without token | Use `form_with(local: true)` or include `X-CSRF-Token` header in AJAX |
| Tab state + redirect_to after POST | `redirect_to root_path` loses active tab | `redirect_to root_path(tab: 'note')` and read param in JS on load |
| Sprockets `require_tree .` + new `notes.js` | File is automatically included everywhere (all pages, all themes) | Acceptable — keep tab/note JS guarded by checking for `$('.note-tab')` existence before binding handlers |
| `favorite_theme` helper in `welcome_helper.rb` | Calling `favorite_theme` outside WelcomeHelper scope (e.g., in a NotesController redirect) | `favorite_theme` is a view helper — do not call from controller; use `current_user.preference.theme` in controller logic |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded note list query | Page slow to load as notes accumulate | Add `.limit(50)` to the note index query from day one | Not a real risk for a personal app with one user; preventive habit only |
| N+1 if note associations added | Slow page load with many notes | Do not call `note.user` in view; eager-load with `.includes(:user)` only if needed | Would break at ~100 notes with an association in the partial |
| Tab switching with many DOM elements | jQuery `.show()` / `.hide()` on a large note list is instant | Not a concern at this scale | Not a real risk |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `user_id` in permitted params | Attacker creates notes as another user | Never permit `user_id`; set it from `current_user.id` in the controller |
| No `user_id` scope on index query | All users' notes returned | `Note.where(user_id: current_user.id)` always |
| CSRF disabled on note form | CSRF forgery attack creates notes on behalf of logged-in user | Use `form_with` or verify `X-CSRF-Token` is present in AJAX headers |
| Note content not sanitized in view | XSS if note content is rendered with `html_safe` | Use `<%= note.content %>` (default ERB escaping) — never `<%= note.content.html_safe %>` |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No feedback after saving a note | User unsure if the note was saved | Flash message (`flash[:notice] = "メモを保存しました"`) shown on redirect; or redirect to Note tab to show the new note in the list |
| Textarea not cleared after save | User sees their old note content still in the form after redirect | Standard redirect-after-POST (PRG pattern) clears the form automatically since the page reloads; no extra JS needed |
| Note list shows all notes (no limit indicator) | User does not know older notes are truncated | Show count or "最新50件" label if limiting the list |
| Tab links look like navigation links | User navigates away from the page when clicking a tab | Implement tab switching with JavaScript (no `href` navigation); use `<button>` or `<a href="#note">` with `e.preventDefault()` |
| Active tab style missing or too subtle | User cannot tell which tab is active | Add a clear `.active` class with visible styling scoped under `.simple` |

---

## "Looks Done But Isn't" Checklist

- [ ] **Theme isolation:** Switch to modern theme — zero tab UI elements visible on the welcome page.
- [ ] **Note ownership:** Log in as user B; confirm user A's notes do not appear in user B's note list.
- [ ] **Mass assignment guard:** POST `note[user_id]=99` to `/notes` — confirm the note is created with `current_user.id`, not `99`.
- [ ] **CSRF:** Disable JavaScript and submit the note form — verify it works (standard form POST with token). Enable JS and submit via AJAX — verify token is sent.
- [ ] **Tab state after save:** Save a note on the Note tab — confirm the page returns to the Note tab, not the Home tab.
- [ ] **Empty note:** Submit the form with blank content — confirm it does not create an empty note (model validation present).
- [ ] **Notes JS guard:** Confirm no JS errors on pages other than welcome (e.g., bookmarks index) — the `notes.js` handlers must check for element existence before binding.
- [ ] **N+1 check:** Verify development log shows a single `SELECT` for the note list, not one per note.
- [ ] **XSS check:** Save a note with content `<script>alert(1)</script>` — confirm it renders as escaped text, not executed script.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Tab UI visible in non-simple themes | LOW | Add `<% if favorite_theme == 'simple' %>` wrapper to view; move CSS under `.simple { }` in `welcome.css.scss` |
| Note ownership not scoped | LOW (before production) / HIGH (after users have data) | Add `where(user_id: current_user.id)` to all queries; audit whether any cross-user notes were created; delete or reassign as appropriate |
| Mass assignment `user_id` accepted | LOW | Remove `user_id` from `permit(...)`; verify no notes have wrong `user_id` in DB |
| Tab state lost after save | LOW | Add `tab` query param to redirect; add JS to read and activate on load |
| CSRF broken | LOW | Switch to `form_with(local: true)`; verify 200 response on submit |
| N+1 on note list | LOW | Add `.includes(:user)` or remove `note.user` from view |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Tab UI leaks into non-simple themes | Tab UI scaffolding (first phase) | Switch to modern theme; confirm zero tab UI present |
| Note ownership not enforced | Note model + controller setup | Sign in as a second user; confirm note list is empty |
| Mass assignment `user_id` | Note model + controller setup | POST with `note[user_id]=99`; verify record has `current_user.id` |
| N+1 query on note list | Note controller + view phase | Check development log for single query |
| CSRF token missing | Note form phase | Submit form; check for 422 errors; verify token in request |
| Tab state lost on page reload | Tab switching JS phase | Save note; confirm Note tab is active on return |
| Note form renders in non-simple themes | Route/controller + view phase | Modern theme: no form element visible |
| XSS via note content | Note list view phase | Render `<script>alert(1)</script>` as content; verify escaped |

---

## Sources

- Direct inspection: `app/views/welcome/index.html.erb`, `app/controllers/welcome_controller.rb`, `app/controllers/bookmarks_controller.rb`, `app/controllers/todos_controller.rb`, `app/helpers/welcome_helper.rb`, `app/assets/stylesheets/welcome.css.scss`, `app/assets/stylesheets/themes/simple.css.scss`, `app/views/layouts/application.html.erb`, `config/routes.rb`, `db/schema.rb`
- Existing security patterns: `bookmark_params` and `todo_params` in respective controllers (user_id merge pattern)
- Theme scoping pattern: `.simple { }` wrapper in `themes/simple.css.scss`; `favorite_theme` helper in `welcome_helper.rb`
- CSRF: `protect_from_forgery with: :exception` confirmed in `application_controller.rb`
- PRG pattern (Post/Redirect/Get): standard Rails redirect after create

---
*Pitfalls research for: v1.3 Quick Note Gadget — note-taking tab + tab UI on Rails 8.1 + Sprockets + jQuery + multi-theme*
*Researched: 2026-04-30*
