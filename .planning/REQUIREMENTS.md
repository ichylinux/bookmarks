# Requirements: Bookmarks v1.4 Internationalization

**Defined:** 2026-05-01
**Core Value:** Users can quickly capture, find, and manage their own bookmarks and related gadgets in one place, with a stable and familiar server-rendered experience.

## v1.4 Requirements

### Locale Infrastructure

- [ ] **I18N-01**: User can have a persisted `locale` value on their account limited to supported locales (`ja` / `en`).
- [ ] **I18N-02**: User sees every request rendered with locale resolved in this order: saved account locale, valid `Accept-Language` match, then default Japanese.
- [ ] **I18N-03**: User cannot force an unsupported locale through headers, params, or stored data.
- [ ] **I18N-04**: Assistive technologies receive the correct page language via the rendered `<html lang>` attribute.

### Language Preference

- [ ] **PREF-01**: User can choose Japanese or English from the existing `/preferences` page.
- [ ] **PREF-02**: User's language choice persists across sign-out, sign-in, browser refresh, and future sessions.
- [ ] **PREF-03**: User sees the preferences page itself translated after changing language.

### Translation Coverage

- [ ] **TRN-01**: User can navigate the app shell in Japanese or English, including layout, menu, drawer navigation, shared buttons, breadcrumbs, ARIA labels, titles, and placeholders.
- [ ] **TRN-02**: User can use bookmarks screens in Japanese or English without hardcoded UI strings.
- [ ] **TRN-03**: User can use notes, todos, feeds, and calendar gadget surfaces in Japanese or English without hardcoded UI strings.
- [ ] **TRN-04**: User sees flash messages, controller alerts, and validation-facing labels in the active locale.
- [ ] **TRN-05**: User sees JavaScript-visible messages in the active locale without introducing a JavaScript i18n build pipeline.

### Authentication and Account Flows

- [ ] **AUTHI18N-01**: User sees Devise authentication pages and Devise flash/failure messages in the active locale.
- [ ] **AUTHI18N-02**: User sees custom two-factor authentication and setup pages in Japanese or English.
- [ ] **AUTHI18N-03**: User sees the first failed sign-in message in English when their request resolves to English.

### Verification and Safety

- [ ] **VERI18N-01**: User-facing tests cover saved user locale, Accept-Language fallback, invalid locale fallback/rejection, and default Japanese behavior.
- [ ] **VERI18N-02**: User-facing tests cover representative Japanese and English UI paths for layout, preferences, core gadgets, and auth/2FA surfaces.
- [ ] **VERI18N-03**: User-visible Japanese literals remaining in views, helpers, controllers, and JavaScript are either translated or explicitly documented as intentional user content.
- [ ] **VERI18N-04**: User-visible translation keys are present in both `ja.yml` and `en.yml` for every extracted string.

## Future Requirements

Deferred to future milestones unless v1.4 implementation proves they are necessary.

### Tooling

- **I18NTOOL-01**: User can rely on automated static translation-key auditing through an `i18n-tasks` workflow.
- **I18NTOOL-02**: User can rely on a robust `Accept-Language` parser gem if manual parsing proves insufficient for real browser headers.
- **I18NTOOL-03**: User can translate JavaScript-rendered strings through an explicit JavaScript i18n pipeline if future UI work adds enough client-rendered copy to justify it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| URL-based locale routes such as `/en/bookmarks` | Adds routing and link complexity without clear value for this personal authenticated app. |
| Translating user-created content | v1.4 translates UI chrome and system messages only; bookmark titles, notes, todos, and feed content remain user/content data. |
| Replacing Sprockets, adding a SPA framework, or introducing a new JavaScript bundler | Unrelated to the i18n goal and conflicts with the existing stable server-rendered architecture. |
| Configuring `i18n-js` for this milestone | Disproportionate for the current server-rendered UI; isolated JavaScript messages can be supplied via translated `data-*` attributes. |
| Publishing/customizing all Devise views by default | `devise-i18n` already provides default translations; custom view publication should happen only if implementation requires it. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| I18N-01 | Pending | Pending |
| I18N-02 | Pending | Pending |
| I18N-03 | Pending | Pending |
| I18N-04 | Pending | Pending |
| PREF-01 | Pending | Pending |
| PREF-02 | Pending | Pending |
| PREF-03 | Pending | Pending |
| TRN-01 | Pending | Pending |
| TRN-02 | Pending | Pending |
| TRN-03 | Pending | Pending |
| TRN-04 | Pending | Pending |
| TRN-05 | Pending | Pending |
| AUTHI18N-01 | Pending | Pending |
| AUTHI18N-02 | Pending | Pending |
| AUTHI18N-03 | Pending | Pending |
| VERI18N-01 | Pending | Pending |
| VERI18N-02 | Pending | Pending |
| VERI18N-03 | Pending | Pending |
| VERI18N-04 | Pending | Pending |

**Coverage:**
- v1.4 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19

---
*Requirements defined: 2026-05-01*
*Last updated: 2026-05-01 after v1.4 requirements definition*
