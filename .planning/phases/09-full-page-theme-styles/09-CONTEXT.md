# Phase 9: Full-Page Theme Styles — Context

**Gathered:** 2026-04-29  
**Status:** Ready for planning (synthesized from ROADMAP + REQUIREMENTS — no separate discuss-phase run)

## Phase boundary

Deliver STYLE-01–STYLE-04 under `body.modern`: replace legacy gray header, modern typography, table polish, action links and form controls — strictly in `themes/modern.css.scss` (plus tests). No new gems; libsass-safe custom properties only.

---

## Decisions

### Theme tokens & layout

- **D-01:** Reuse and extend existing CSS variables in `.modern` (`--modern-color-primary`, `--modern-bg`, `--modern-text`, `--modern-header-bg`). New tokens only as plain hex/rgba (no `$variable` dereference inside custom property values).

- **D-02:** Header bar overrides MUST use `.modern #header .head-box` (ID specificity) to beat `common.css.scss` `#header .head-box { background: #AAA; }`.

- **D-03:** Secondary header strip (old dropdown nav) MUST use `.modern .header` (and descendants) so it is visibly modern; coordinate with drawer token colours.

- **D-04:** Body copy: `font-size: 16px`, system font stack (`-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, `Roboto`, `sans-serif`), `line-height` ≥ 1.5 on `body`-level scope inside `.modern`.

- **D-05:** Tables: padding on `th`/`td`, header row distinct from body, zebra or hover (existing legacy has hover — enhance under `.modern`).

- **D-06:** `.modern .actions a` (Edit/Delete style links): use token border/background; `:hover` and `:focus-visible` distinct from legacy gray.

- **D-07:** Form controls: `input[type=text]`, `input[type=email]`, `input[type=password]`, `input[type=url]`, `input[type=number]`, `textarea`, `select` — border, padding, radius, `:focus` ring using `--modern-color-primary`.

- **D-08:** Contract test (`*_contract_test.rb`) asserts presence of key selector blocks / token usage strings so CI guards regressions (same pattern as Phase 7).

### Out of scope

- Auth/Devise view redesign (see REQUIREMENTS Future / out of scope).
- Changing HTML structure (Phase 6/7 markup stays).

---

## Canonical references

- `app/assets/stylesheets/common.css.scss` — legacy `#AAA`, tables, `.actions`, `.header`
- `app/assets/stylesheets/themes/modern.css.scss` — existing tokens + drawer
- `.planning/ROADMAP.md` — Phase 9 success criteria
- `.planning/REQUIREMENTS.md` — STYLE-01–STYLE-04
- `test/assets/modern_drawer_css_contract_test.rb` — SCSS contract pattern

---

## Deferred

- Mobile breakpoint fine-tuning (explicitly out of milestone scope in REQUIREMENTS).
- `aria-expanded` on hamburger (future NAV-F01).

---

*Phase: 09-full-page-theme-styles*
