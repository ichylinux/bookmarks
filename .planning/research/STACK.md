# Stack Research

**Domain:** Quick Note Gadget — note-taking CRUD feature on Rails 8.1 / Sprockets / jQuery
**Researched:** 2026-04-30
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Rails ActiveRecord | 8.1.3 (already installed) | `Note` model, migrations, user-scoped queries | Already in the app; a Note is just a persisted row with `user_id` and `body` — zero new infrastructure needed |
| Rails form helpers (`form_with`) | 8.1.3 (already installed) | Textarea + save button for creating notes | Standard Rails server-side form; no JS framework or API endpoint required for the initial save path |
| Rails ERB partials | 8.1.3 (already installed) | Note list rendering, note row partial | Consistent with every other view in the app; keeps the simple theme welcome page server-rendered |
| jQuery (XHR via `$.ajax` / `rails-ujs`) | 4.6.1 (already installed) | Optional: async note submission so page does not fully reload | Already loaded globally; the existing todo gadget demonstrates the `render partial:` → XHR → DOM swap pattern |
| SCSS (sass-rails / sassc) | 6.0.0 (already installed) | Styles for the note tab, textarea, list | Already compiled via Sprockets; a scoped `.simple .note-tab { }` block in `themes/simple.css.scss` or a new `notes.css.scss` is all that is needed |
| MySQL via ActiveRecord | mysql2 adapter (already installed) | Persist notes with `user_id`, `body`, `created_at` | No special storage requirements; a plain `notes` table works |

### Supporting Libraries

No new gems or npm packages are required.

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rails-ujs` (already in application.js) | bundled with Rails 8.1 | `data-remote="true"` on the note form enables async POST without writing custom `$.ajax` | Use if XHR-based form submission (no full page reload) is desired; already loaded, zero install cost |
| Turbo (actiontext / turbo-rails) | — | SPA-like partial updates | **DO NOT add** — Sprockets/jQuery/rails-ujs pipeline is the app's explicit constraint; adding Turbo Drive in a Sprockets app without import maps is a non-trivial migration and is out of scope per PROJECT.md |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| ESLint + Prettier (already configured) | Lint any JS added for tab switching or note form behaviour | Run `yarn run lint` before committing; conventions in `.planning/codebase/CONVENTIONS.md` |
| Minitest (already configured) | Controller + model unit tests for `NotesController`, `Note` model | Follow existing test naming convention (`test_一覧`, `test_作成`, etc.) |
| Cucumber / `bundle exec rake dad:test` (already configured) | Acceptance test for note tab and list display | Follow existing feature file patterns in `features/` |

## Installation

No new gems or npm packages are required for this milestone.

```bash
# Generate the migration — run once
bundle exec rails generate migration CreateNotes user_id:integer:index body:text
bundle exec rails db:migrate
```

No `Gemfile` changes. No `package.json` changes.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Plain `form_with` POST + redirect (or `data-remote` XHR) | Turbo Streams / Stimulus | Only if the project migrates to an import-maps or ESM pipeline; explicitly out of scope for this milestone |
| Hand-rolled tab switching with jQuery `show()`/`hide()` | jQuery UI Tabs widget | jQuery UI is already installed; however, the tab requirement is two links + two `<div>` panels — jQuery UI Tabs adds event overhead and a dependency on jQuery UI theming that conflicts with the simple theme's minimal style. Hand-rolled is simpler and already proven by the modern theme drawer. |
| CSS tab switching with `<input type="radio">` hack | Pure CSS | Would work but adds hidden radio inputs and complex `:checked` sibling selectors to a view that is otherwise straightforward ERB; harder to follow for maintainers |
| `Note` model with `body` text column | ActionText / Trix editor | ActionText is justified for rich text; for a personal note textarea a plain `text` column is sufficient and avoids adding Active Storage complexity |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Turbo Drive / turbo-rails | Would require replacing `rails-ujs` and potentially import maps; explicit out-of-scope constraint in PROJECT.md | `data-remote="true"` + `render partial:` (existing pattern from todos and calendars) |
| Action Text / Trix | Heavyweight rich-text infrastructure (Active Storage blobs, polymorphic `rich_text` table) for a plain textarea; adds migration complexity and a new JS dependency | Plain `body:text` column |
| Pagination gems (Kaminari, Pagy) | Over-engineered for a personal note list; a user is unlikely to accumulate hundreds of notes before a `limit` is warranted | `Note.where(user: current_user).order(created_at: :desc).limit(50)` in the controller |
| A separate `notes` API endpoint returning JSON | Adds a REST namespace with no benefit when the app is server-rendered and jQuery XHR can consume an HTML partial | Controller action that renders an HTML partial (same pattern as `todos#create`) |
| `belongs_to :user, optional: true` | Leaves orphaned rows possible; notes are always user-owned | `belongs_to :user` (non-optional, default in Rails 5+) + `validates :user, presence: true` |

## Stack Patterns

**Existing pattern to follow — XHR partial swap (todos gadget):**

The `TodosController#create` action renders `partial: 'todo'` rather than redirecting. The view calls the endpoint via `data-remote="true"` on the form or a jQuery `$.post`. The returned HTML fragment is inserted into the DOM. Replicate this for `NotesController#create`.

```ruby
# app/controllers/notes_controller.rb
def create
  @note = Note.new(note_params)
  @note.transaction { @note.save! }
  render partial: 'note', locals: { note: @note }
end
```

**Tab switching — jQuery show/hide (two panels only):**

Two `<div>` panels (`#tab-home`, `#tab-note`) with matching tab links. jQuery toggles `active` class on the link and `hidden` on the panels. No library needed.

```javascript
// app/assets/javascripts/welcome.js (new or extend existing)
$(document).ready(function () {
  $('.note-tab-link').on('click', function (e) {
    e.preventDefault();
    const target = $(this).data('tab');
    $('.tab-panel').addClass('hidden');
    $('.note-tab-link').removeClass('active');
    $('#' + target).removeClass('hidden');
    $(this).addClass('active');
  });
});
```

**Model — minimal, user-scoped:**

```ruby
# app/models/note.rb
class Note < ApplicationRecord
  belongs_to :user
  validates :body, presence: true
  scope :for_user, ->(user) { where(user: user).order(created_at: :desc) }
end
```

**Migration — no surprises:**

```ruby
class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
```

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Rails 8.1.3 | Ruby 3.4 | `form_with` default: `data-remote` is NOT set by default in Rails 7+ (`local: true` is the default); explicitly set `local: false` or add `data: { remote: true }` for XHR behaviour |
| rails-ujs (bundled) | jQuery 4.6.1 | `data-remote="true"` submits via XHR and fires `ajax:success` event; jQuery `.on('ajax:success')` listener works as in existing todos JS |
| sassc / sass-rails 6.0.0 | CSS custom properties for simple theme scoping | Same libsass constraint as v1.2: do not assign SCSS `$variables` directly to `--custom-properties`; use `#{$var}` or plain CSS values |

## Sources

- Rails 8.1 guides (form helpers, ActiveRecord) — HIGH confidence; standard Rails patterns used throughout the existing app
- Existing app source: `app/controllers/todos_controller.rb`, `app/assets/javascripts/todos.js`, `app/views/welcome/_todo_gadget.html.erb` — the XHR-partial pattern is already proven in this codebase
- `.planning/codebase/STACK.md` (analysed 2026-04-27) — confirmed no Turbo, no Stimulus, Sprockets + jQuery 4 + rails-ujs pipeline

---
*Stack research for: Quick Note Gadget (Rails 8.1 / Sprockets / jQuery — v1.3)*
*Researched: 2026-04-30*
