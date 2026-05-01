---
status: passed
phase: 17-feature-surface-translation
requirements:
  - TRN-02
  - TRN-03
  - TRN-05
verified_at: 2026-05-01
full_gate:
  lint: passed
  minitest: passed
  dad_test: passed
must_haves:
  total: 19
  passed: 19
  failed: 0
---

# Phase 17 Verification

## Verdict

Phase 17 achieved the ROADMAP goal: users can use the app's core bookmark, note, todo, feed, calendar, and JavaScript-visible UI in Japanese or English.

All 19 must-have truths from the five Phase 17 plans are satisfied. The evidence combines direct implementation inspection, representative bilingual controller/model tests, locale parity coverage, code review, and the final full gate after the post-review fix.

## Requirement Traceability

- **TRN-02: Bookmark screens can be used in Japanese or English without hardcoded UI strings.** Passed. Bookmark index, form, show, and edit views now render fixed chrome through `bookmarks.*`, `actions.*`, `messages.confirm_delete`, and ActiveRecord attribute translations. Representative tests cover Japanese and English form labels, breadcrumb/action labels, submit labels, show/edit actions, translated delete confirmations, and unchanged bookmark/folder content.

- **TRN-03: Notes, todos, feeds, and calendar gadget surfaces can be used in Japanese or English without hardcoded UI strings.** Passed. Note gadget copy resolves through `welcome.note_gadget.*`; Todo actions/forms and preference default priority consume `Todo.priority_options`; Todo display uses runtime-localized `Todo#priority_name`; feed index/form/loading/error copy resolves through `feeds.*` and `welcome.feed.*`; calendar loading, month caption, weekday names, form labels, glyph accessibility labels, and actions resolve through Rails I18n. Tests cover ja/en note, Todo, feed, and calendar surfaces.

- **TRN-05: JavaScript-visible messages render in the active locale without introducing a JavaScript i18n build pipeline.** Passed. Feed JavaScript reads server-rendered `data-feed-url-required-message`, `data-feed-fetch-failed-message`, and `data-fetch-failed-message` attributes. No `i18n-js`, `window.I18n`, JavaScript translation registry, imports, bundler, or new dependency was introduced.

## Success Criteria

1. **Bookmark screens can be used in Japanese or English without hardcoded UI strings.** Satisfied by localized bookmark views and controller tests for ja/en labels, helpers, submit buttons, action links, and delete confirmation copy.

2. **Notes, todos, feeds, and calendar gadget surfaces can be used in Japanese or English without hardcoded UI strings.** Satisfied by localized note/Todo/feed/calendar views, runtime gadget titles, runtime Todo priority helpers, Rails date localization, and representative ja/en tests across the affected controllers and models.

3. **JavaScript-visible messages render in the active locale through server-rendered translated values without adding `i18n-js` or a JavaScript i18n build pipeline.** Satisfied by feed form and feed gadget `data-*` attributes consumed by `feeds.js`, plus tests asserting exact ja/en data attribute values and a code search for forbidden JS i18n mechanisms.

4. **User-created content such as bookmark titles, note bodies, todos, and feed content remains unchanged and is not treated as translatable UI chrome.** Satisfied by implementation boundaries and tests asserting unchanged bookmark/folder names and URLs, note bodies, Todo titles, feed record/external content, calendar record titles, and `holiday_jp` holiday names.

## Automated Checks

Final full gate after post-review fix:

- `yarn run lint`: PASS
- `bin/rails test`: PASS, 181 runs, 1043 assertions, 0 failures, 0 errors, 0 skips
- `bundle exec rake dad:test`: PASS, 9 scenarios, 28 steps, 0 failed, seed 11772

Additional representative validation recorded in `17-05-SUMMARY.md`:

- Targeted Phase 17 representative Minitest: PASS, 104 runs, 700 assertions, 0 failures, 0 errors, 0 skips

## Code Review

`.planning/phases/17-feature-surface-translation/17-REVIEW.md` is clean: 0 critical, 0 warning, 0 info, 0 total findings.

The only review warning was fixed in `309965e` (`fix(17-04): localize feed form wrapper navigation`): `app/views/feeds/new.html.erb` and `app/views/feeds/edit.html.erb` now use `t('actions.back_to_list')`, with feed controller coverage for English `Back to list` and Japanese `一覧に戻る`.

## Content Boundary

User-created and external content intentionally remains untranslated. This includes bookmark titles, bookmark URLs, folder names, parent folder names, note bodies, Todo titles, feed site names, feed URLs, feed titles, feed entry titles/URLs, calendar record titles, and `holiday_jp` holiday names such as `元日`.

Calendar glyph text `<<` and `>>` also remains unchanged by design; localized `aria-label` and `title` attributes provide the translated accessible labels.

## Residual Risk

No open gaps were found. Phase 17 uses representative bilingual assertions plus locale key parity rather than an exhaustive static scan of every rendered string. That is appropriate for this phase because Phase 18 owns the broader remaining literal/key verification requirements (`VERI18N-02`, `VERI18N-03`, `VERI18N-04`), while Phase 17's goal-level surfaces and JavaScript-visible message path are covered and green.
