# Phase 17: Feature Surface Translation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 17-Feature Surface Translation
**Areas discussed:** Translated vs user/external content boundary

---

## Fixed Gadget Titles

| Option | Description | Selected |
|--------|-------------|----------|
| Translate fixed gadget names only | `Bookmark` / `Todo` are UI labels; Feed / Calendar record titles are user-created content. | Yes |
| Leave all gadget headings as-is | Treat `Bookmark` / `Todo` as short brand-like labels and translate only surrounding operations/forms. | |
| Make all gadget headings translatable | Revisit Feed / Calendar title behavior too, including defaults and user-created titles. | |

**User's choice:** Translate fixed gadget names only.
**Notes:** This keeps app-defined class labels translatable while preserving user-created record titles.

---

## Todo Priority Labels

| Option | Description | Selected |
|--------|-------------|----------|
| Translate as UI choices | Render `高 / 中 / 低` according to locale while keeping numeric stored values unchanged. | Yes |
| Leave Japanese labels as-is | Treat the labels as compact existing symbols outside Phase 17's scope. | |
| Use a different English priority vocabulary | Pick a specific English mapping such as `Important / Normal / Low` or `High / Medium / Low`. | |

**User's choice:** Translate as UI choices.
**Notes:** Todo priority is app-defined metadata, not user-created content.

---

## Calendar Display Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Translate weekdays/month-year only; leave holiday names in Japanese | Month/year and weekday labels are UI; `holiday_jp` holiday names are external regional data. | Yes |
| Translate weekdays/month-year and holiday names | Add English mappings for Japanese holiday names too. | |
| Translate only calendar operation text | Keep calendar body formatting as-is and translate only actions such as edit/delete. | |

**User's choice:** Translate weekdays/month-year only; leave holiday names in Japanese.
**Notes:** Holiday names should be explicitly documented as intentionally untranslated for Phase 17.

---

## User and External Content

| Option | Description | Selected |
|--------|-------------|----------|
| All listed items are user/external content and remain untranslated | Bookmark title/url, folder names, note bodies, Todo titles, Feed site/entry content, Calendar user titles, and holiday names remain unchanged. | Yes |
| Some listed items should be treated as UI | Move selected borderline fields into translation scope. | |
| Let implementation decide ambiguous cases | Planner decides remaining borderline cases during implementation. | |

**User's choice:** All listed items are user/external content and remain untranslated.
**Notes:** This matches `.planning/REQUIREMENTS.md` Out of Scope: user-created content is not translated.

---

## Claude's Discretion

The user chose to generate `CONTEXT.md` after this area only. Remaining areas are left to research/planning:

- Translation key namespace placement.
- JavaScript-visible message delivery.
- English UI wording tone.

## Deferred Ideas

None.
