# Phase 17: Feature Surface Translation - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 17 translates the app's feature surfaces for bookmarks, notes, todos, feeds, calendars, and JavaScript-visible UI so users can operate the core app in Japanese or English. It builds on the locale resolution, language preference, and shared shell/message translation completed in Phases 14-16.

This phase includes feature view labels, action links, form buttons, placeholders, empty states, loading/error text, fixed gadget names, app-defined enum labels, and JavaScript-visible messages supplied through server-rendered translated values. It does not translate user-created or external content, and it does not introduce `i18n-js` or a new JavaScript i18n pipeline.

Devise authentication pages, two-factor authentication pages, and milestone-wide translation verification remain Phase 18 scope.

</domain>

<decisions>
## Implementation Decisions

### Translated vs User/External Content Boundary

- **D-01:** Translate only fixed gadget names. `BookmarkGadget#title` and `TodoGadget#title` are app-defined UI labels and should render according to the active locale. Feed and calendar gadget titles come from user-created records and remain unchanged.
- **D-02:** Translate Todo priority labels (`高 / 中 / 低`) as app-defined UI choices while preserving the existing numeric stored values. Existing Todo data must not be migrated just to change display text.
- **D-03:** Translate calendar month/year formatting and weekday labels, but leave `holiday_jp` holiday names in Japanese. Holiday names are treated as external regional data for this phase and should be explicitly documented as intentionally untranslated.
- **D-04:** Treat bookmark titles/URLs, folder names, note bodies, Todo titles, feed site names, feed entries, calendar user-created titles, and Japanese holiday names as user or external content. Translate UI labels, actions, placeholders, empty states, loading messages, and error messages only.

### Claude's Discretion

The user chose to finalize context after discussing only the translation boundary. The planner and researcher should decide the remaining implementation details, with these biases:

- Prefer a namespace strategy consistent with Phase 16 (`nav.*`, `flash.*`, `messages.*`) while avoiding over-abstracting one-off feature strings.
- Keep JavaScript-visible strings server-rendered, such as `data-*` attributes or ERB-rendered values consumed by existing jQuery, without adding `i18n-js`.
- Use concise, conventional English UI wording for actions and states unless existing product language suggests otherwise.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements

- `.planning/ROADMAP.md` — Phase 17 goal, success criteria, and boundary with Phase 18.
- `.planning/REQUIREMENTS.md` — TRN-02, TRN-03, TRN-05, plus Out of Scope entries for user-created content and `i18n-js`.
- `.planning/PROJECT.md` — v1.4 milestone goal, constraints, and cumulative project decisions.
- `.planning/STATE.md` — current v1.4 progress, carry-forward pitfalls, and completed Phase 14-16 artifacts.

### Prior Phase Alignment

- `.planning/phases/14-locale-infrastructure/14-CONTEXT.md` — locale resolution contract, supported locales, `<html lang>`, and no URL locale param.
- `.planning/phases/15-language-preference/15-CONTEXT.md` — native-label rule, lazy lookup path pitfall, `/preferences` i18n precedent.
- `.planning/phases/16-core-shell-and-shared-messages-translation/16-CONTEXT.md` — shared flash namespace, user-content interpolation rule, Phase 16/17 boundary, and no `devise-i18n` activation until Phase 18.

### Existing Locale and Feature Surface Code

- `config/locales/ja.yml` — current ja locale catalog and existing `messages.confirm_delete`, `nav.*`, `flash.errors.generic`, `activerecord.attributes.*` keys.
- `config/locales/en.yml` — current en locale catalog that must stay key-symmetric with ja for newly extracted strings.
- `app/models/bookmark_gadget.rb` — fixed `Bookmark` gadget title that should become locale-aware.
- `app/models/todo_gadget.rb` — fixed `Todo` gadget title that should become locale-aware.
- `app/models/todo.rb` — priority constants currently displayed as Japanese labels and should be localized at display time.
- `app/models/calendar.rb` — weekday labels and `holiday_jp` holiday accessors; weekdays/month formatting are translatable, holidays remain external data.
- `app/views/bookmarks/index.html.erb` and `app/views/bookmarks/_form.html.erb` — bookmark labels, actions, breadcrumb strings, placeholders, and folder helper text.
- `app/views/welcome/_bookmark_gadget.html.erb`, `app/views/welcome/_note_gadget.html.erb`, `app/views/welcome/_todo_gadget.html.erb`, `app/views/welcome/_feed.html.erb`, `app/views/welcome/_calendar.html.erb` — dashboard gadget surfaces and loading/error copy.
- `app/views/todos/_actions.html.erb`, `app/views/todos/_form.html.erb`, `app/views/todos/_todo.html.erb` — Todo gadget controls, submit labels, and priority display.
- `app/views/feeds/_form.html.erb` and `app/assets/javascripts/feeds.js` — feed title-fetch action and JS alert messages.
- `app/views/calendars/get_gadget.html.erb` and `app/views/calendars/_form.html.erb` — calendar month/weekday labels and action/form strings.

### Coding and Verification Conventions

- `.planning/codebase/CONVENTIONS.md` — Rails view conventions, I18n use, JS Sprockets style, test naming conventions.
- `.planning/codebase/STRUCTURE.md` — feature surface file locations and integration points.
- `.planning/codebase/STACK.md` — Rails/Sprockets/jQuery stack and i18n-related gems.
- `CLAUDE.md` — required phase verification gate: `yarn run lint`, `bin/rails test`, and `bundle exec rake dad:test`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Bookmark.human_attribute_name`, `Feed.human_attribute_name`, `Calendar.human_attribute_name`, and existing `activerecord.attributes.*` keys already cover several model field labels.
- `messages.confirm_delete` is an existing shared, interpolated confirmation key and should remain the pattern for delete confirmations that include user content.
- Phase 16 added `nav.*` and `flash.errors.generic`, establishing absolute shared keys for cross-surface strings.

### Established Patterns

- Rails server-rendered ERB is the primary UI surface. Feature forms use classic Rails helpers (`form_for`, `form_with`) and should use `t(...)` or model attribute translations rather than client-side i18n.
- Existing JavaScript is Sprockets + jQuery. Phase 17 should keep JS message localization server-fed and avoid new bundling or translation dependencies.
- User-entered values are interpolated into translated UI safely as content, not translated themselves.
- Lazy lookup is acceptable only when the YAML path exactly matches the template path; Phase 15 recorded this as a pitfall.

### Integration Points

- Locale keys will be added to both `config/locales/ja.yml` and `config/locales/en.yml`.
- Feature views under `app/views/bookmarks/`, `app/views/todos/`, `app/views/feeds/`, `app/views/calendars/`, and `app/views/welcome/` are primary translation targets.
- JavaScript-visible strings appear in `app/assets/javascripts/feeds.js` and inline ERB script blocks in welcome gadget partials.
- Calendar weekday/month rendering currently lives in `Calendar#day_of_week` and `app/views/calendars/get_gadget.html.erb`; holiday names come from `holiday_jp` and remain untranslated.

</code_context>

<specifics>
## Specific Ideas

- Fixed gadget titles are UI labels: `Bookmark` and `Todo` should follow active locale.
- Feed and Calendar record titles are user-created labels and must remain exactly as stored.
- Todo priority display should localize labels without touching stored numeric priorities.
- Calendar English display should make weekday/month UI understandable, but Japanese public holiday names may remain Japanese intentionally.

</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)

- `Gate drawer + drawer-overlay on theme for symmetry` — drawer DOM/theme cleanup is not part of Phase 17 feature surface translation.
- `Extract drawer_ui? helper if condition grows to 4th case` — layout helper cleanup is already noted from earlier phases and does not fit this phase's translation scope.

No new future feature ideas were raised during this discussion.

</deferred>

---

*Phase: 17-feature-surface-translation*
*Context gathered: 2026-05-01*
