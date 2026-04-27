# Plan 04-02 Summary: Manual smoke and documentation close-out

## Smoke Test Results (VERI-02)

Manual smoke session — run the Rails server (`bin/rails server`) and test each flow
in a browser. Check each box when confirmed working; add a note if anything fails.

- [x] **Bookmark title auto-fill** — Create a new bookmark; enter a URL with a known
      `<title>` tag; blur the URL field. Verify the Title field is auto-populated.
      No JS console errors. (`bookmarks.js` + `BookmarksController#fetch_title`)

- [x] **Todo create** — Create a new todo from the todo list or portal gadget.
      Verify the item appears in the list without a full page reload (UJS `.js.erb`).
      No JS console errors. (`todos.js`, `app/views/todos/create.js.erb`)

- [x] **Todo update** — Edit an existing todo (title or status). Verify the update
      is reflected inline. No JS console errors. (`todos.js`, `app/views/todos/update.js.erb`)

- [x] **Feed gadget** — Visit the portal page. Verify the feed gadget renders entries.
      Expand/collapse or interact per gadget's expected behaviour. No JS console errors.
      (`feeds.js`, `bookmark_gadget.js` on portal, `app/views/welcome/index.html.erb`)

- [x] **Portal page — multi-gadget** — Visit `/welcome` (portal). Verify:
      bookmark_gadget, feed gadget, todo_gadget, and calendar gadget all render.
      No JS console errors. No double-click errors or frozen widgets.
      (`bookmark_gadget.js`, `feeds.js`, `todos.js`, `calendars.js`)

## CONVENTIONS.md Review

Item 7 of the D-06 cross-check (ESLint config pointer / how to run lint) was **MISSING** from the JavaScript section. **Added 1 item(s):** bullet under `## JavaScript (Sprockets 第一者スクリプト)` documenting `eslint.config.mjs`, `no-var`, and `yarn run lint`. Items 1–6 were already **COVERED** in the existing text.

## Verdict

5/5 smoke flows passed. No JS-attributable regressions observed. **VERI-02** is satisfied. Per D-05, no separate UAT document was required because all flows passed.

## DOCS-01 Status

**DOCS-01 satisfied.** One bullet was added to `CONVENTIONS.md` (ESLint `eslint.config.mjs` / `no-var` / `yarn run lint`); the JavaScript section is otherwise complete per the D-06 cross-check in Task 1.

## Milestone v1.1 Status: All four Phase 4 requirements satisfied. Milestone v1.1 complete.
