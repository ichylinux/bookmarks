# Phase 91: Policy Wording — 90-Day Retention - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Update **locale YAML text only** for the existing public policy pages (`/privacy`, `/terms`). No route, controller, view structure, or CSS changes unless a test requires a new assertion string.

**Must satisfy:** POLICY-01, POLICY-02 — two-stage deletion (immediate deactivation; permanent erasure within **90 days**); remove v1.27 wording that implies instantaneous deletion of all bookmarks/feeds at button press.

**Sections to edit:**
- `pages.privacy.sections.data_retention` (ja + en)
- `pages.terms.sections.termination` (ja + en)

</domain>

<decisions>
## Implementation Decisions

### Retention model (from milestone — not re-discussed)
- **D-01:** Fixed retention window: **90 calendar days** after account deletion request before permanent erasure (background purge job is ACCT-FUT-01, out of this phase)
- **D-02:** On deletion request: access stops immediately; user cannot sign in or restore account during retention
- **D-03:** Transactional rows remain in DB until purge job; policy text describes **erasure within 90 days**, not instant row deletion

### Data inventory wording (discussed — Area 2)
- **D-04:** Privacy `data_retention` uses **general collective phrasing only** — do **not** enumerate bookmarks, feeds, notes, todos, etc. by name
  - **ja:** 「アカウントに紐づくすべてのデータ」
  - **en:** **"all data associated with your account"**
- **D-05:** Terms `termination` uses the **same general collective phrasing** as privacy (aligned ja/en)
- **D-06:** Add **one separate sentence** explicitly mentioning account information and authentication tokens (OAuth), e.g. ja: 「アカウント情報および認証に用いるトークンを含みます」/ en equivalent — without listing each gadget table

### Page structure & delivery (from Phase 89 — unchanged)
- **D-07:** Content stays in `config/locales/ja.yml` and `config/locales/en.yml`; views keep looping existing section keys
- **D-08:** No footer/nav links to policy pages in this phase

### Claude's Discretion
- Exact prose for 90-day timing ("within 90 days" vs "no later than 90 days"), immediate-deactivation sentences, and operator-initiated termination paragraph (keep existing violation clause; separate from user self-delete if clearer)
- Whether privacy or terms gets one extra sentence on "not used for service provision during retention" — align with POLICY-01 requirement unless user adds more context in plan-phase

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — POLICY-01, POLICY-02 (90-day, access stop, no service use during retention)
- `.planning/ROADMAP.md` — Phase 91 success criteria
- `.planning/PROJECT.md` — v1.28 milestone goal (two-stage deletion)

### Prior phase pattern
- `.planning/phases/89-static-policy-pages/89-CONTEXT.md` — locale YAML + `PagesController` pattern
- `config/locales/ja.yml` — `pages.privacy.sections.data_retention`, `pages.terms.sections.termination`
- `config/locales/en.yml` — same keys
- `app/views/pages/privacy.html.erb` — section loop `%w[data_collected x_login email_handling data_retention contact]`
- `app/views/pages/terms.html.erb` — section loop `%w[acceptable_use availability termination]`

### Tests (update assertions if body text changes materially)
- `test/controllers/privacy_controller_test.rb` (if present)
- `test/controllers/terms_controller_test.rb` (if present)
- Any i18n key parity / policy content tests from Phase 89

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 89 policy pages: `PagesController`, `pages.css.scss`, `policy-content` / `simple_format` rendering
- Locale switcher partial: `app/views/welcome/_landing_lang_switcher.html.erb`

### Established Patterns
- Policy copy lives in YAML `body` multiline strings; headings in `heading` keys
- ja/en key structure must remain identical for parity checks

### Integration Points
- Only `config/locales/ja.yml` and `config/locales/en.yml` under `pages.privacy.sections.data_retention` and `pages.terms.sections.termination`

</code_context>

<specifics>
## Specific Ideas

**ja `data_retention` / `termination` should convey:**
1. Delete from settings → account deactivated immediately, no access
2. All data associated with the account (総称) erased within 90 days, not recoverable after purge
3. One line: includes account info + auth/OAuth tokens
4. Operator may still suspend/delete for ToS violations (retain existing clause; don't contradict user self-delete)

**Do not:** Long bullet list of bookmark, feed, note, todo, Mastodon, X, visited_links table names.

</specifics>

<deferred>
## Deferred Ideas

- Explicit per-data-type enumeration in policy — user chose general phrasing (Area 2)
- Gray areas not discussed in this session (planner defaults): retention period phrasing nuance, during-retention purpose detail, tone legal vs plain, cross-page split of detail — use POLICY-01/02 and D-01–D-03 unless plan-phase flags ambiguity

</deferred>

---

*Phase: 91-Policy Wording — 90-Day Retention*
*Context gathered: 2026-05-20*
