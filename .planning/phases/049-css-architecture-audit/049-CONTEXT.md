# Phase 49: CSS Architecture Audit & Migration - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit all non-theme SCSS files (`app/assets/stylesheets/*.css.scss`) for misplaced `.modern`, `.classic`, or `.simple` prefixed selectors. Migrate any violations found to the correct theme file. Document findings.

**Codebase scout result:** 0 violations found across all 9 non-theme files. Prior quick tasks Q-07 and the preferences.css.scss refactor today already completed the migration. Phase 49 execution is: run the audit, document 0-violation result, write verification evidence, and advance.

</domain>

<decisions>
## Implementation Decisions

### Audit Documentation
- Record findings inline in CONTEXT.md and SUMMARY.md — no separate artifact needed
- No CI grep check or rake task — enforce by convention and code review
- Commit audit findings as part of the phase summary

### Completeness
- Zero violations is a passing result — declare Phase 49 complete with audit evidence
- No ERB template audit (inline `style=` is a separate concern not in scope)
- No Minitest enforcement of CSS architecture (CSS files not loaded by test suite; enforce by convention)

### Claude's Discretion
- Plan format: single plan (049-01) documenting the audit run and verification
- Verification: ARCH-01/02/03 all pass (audit run, 0 violations, base styles confirmed intact)

</decisions>

<code_context>
## Existing Code Insights

### Files Audited (all clean)
- `bookmarks.css.scss` — 0 theme selectors
- `calendars.css.scss` — 0 theme selectors
- `common.css.scss` — 0 theme selectors
- `devise.css.scss` — 0 theme selectors
- `feeds.css.scss` — 0 theme selectors
- `landing.css.scss` — 0 theme selectors
- `preferences.css.scss` — 0 theme selectors (cleaned today: submit button styles moved to theme files)
- `todos.css.scss` — 0 theme selectors
- `welcome.css.scss` — 0 theme selectors (Q-07: simple-theme welcome CSS previously moved to simple.css.scss)

### Theme Files (correct home for theme selectors)
- `themes/modern.css.scss` — modern-specific styles
- `themes/classic.css.scss` — classic-specific styles
- `themes/simple.css.scss` — simple-specific styles
- `themes/_drawer_shared.scss` — shared drawer mixin
- `themes/_notes_shared.scss` — shared notes mixin

### Established Patterns
- Un-prefixed base styles stay in source file (e.g., `.preferences-form input[type="submit"]` base in preferences.css.scss)
- Theme-prefixed rules (`.modern .x`, `.classic .x`, `.simple .x`) belong in their respective theme file

</code_context>

<specifics>
## Specific Ideas

No specific implementation work needed — audit found 0 violations. Phase executes as: run audit command, document result, write ARCH-01/02/03 verification evidence.

</specifics>

<deferred>
## Deferred Ideas

- ERB inline style audit — out of scope for this phase
- Minitest CSS architecture enforcement — out of scope; enforce by convention
- CI grep check for future violations — deferred, can be added as quick task later if violations recur

</deferred>
