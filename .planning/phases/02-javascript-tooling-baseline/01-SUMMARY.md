---
phase: 02-javascript-tooling-baseline
plan: "01"
subsystem: testing
tags: [eslint, prettier, babel, sprockets]

requires: []
provides:
  - yarn run lint / lint:fix / format scripts
  - eslint.config.mjs targeting app/assets/javascripts
affects: [02-plan-02]

tech-stack:
  added: [eslint@9, prettier@3, @babel/eslint-parser, @babel/preset-env, eslint-config-prettier, globals]
  patterns: [ESLint flat config with Babel parser aligned to babel.config.js]

key-files:
  created: [.prettierrc.json, .prettierignore, eslint.config.mjs, babel.config.js]
  modified: [package.json, yarn.lock, app/assets/javascripts/bookmark_gadget.js, app/assets/javascripts/bookmarks.js, app/assets/javascripts/todos.js]

key-decisions:
  - "Added minimal babel.config.js (preset-env only) because the repo had no Babel file; required for @babel/eslint-parser with configFile."
  - "Declared ActionCable and App globals for cable.js alongside browser and jQuery."

patterns-established:
  - "Lint: eslint \"app/assets/javascripts/**/*.js\" with Babel parser and eslint-config-prettier last."

requirements-completed: [TOOL-01]

duration: 25min
completed: 2026-04-27
---

# Phase 2: Plan 01 Summary

**ESLint 9 flat config and Prettier are wired to `app/assets/javascripts` with `yarn run lint` exiting clean.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 5
- **Files modified:** 10+

## Accomplishments

- Dev dependencies and scripts: `lint`, `lint:fix`, `format`.
- Minimal `babel.config.js` so `@babel/eslint-parser` resolves plugins without pulling the full legacy Babel plugin tree.
- Removed dead code / adjusted globals so `yarn run lint` is exit 0 with no behavior change to user-facing features.

## Task Commits

1. **Tooling** — `0ab9a01` feat(02-01): add ESLint 9 flat config, Prettier, and minimal babel.config.js
2. **JS fixes** — `26da1d1` fix(02-01): resolve ESLint issues in Sprockets JavaScript assets

## Self-Check: PASSED

- `yarn run lint` exit 0
- `node -e "import('./eslint.config.mjs')"` succeeds
