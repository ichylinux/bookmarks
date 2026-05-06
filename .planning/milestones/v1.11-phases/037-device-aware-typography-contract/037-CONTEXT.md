# Phase 37: Device-aware Typography Contract - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the runtime typography contract for device-aware font sizing while keeping the existing `small|medium|large` UX surface stable: medium baseline differs by device, small/large are relative to medium, and rendering remains safe for invalid values.

</domain>

<decisions>
## Implementation Decisions

### Locked Milestone Policies (carried forward)
- **D-01:** Keep the existing 3-option preference UX (`small`, `medium`, `large`) in Phase 37.
- **D-02:** Medium baseline contract is fixed at `PC=14px` and `mobile=16px`.
- **D-03:** Relative scale contract is fixed at `small=0.875x`, `medium=1.0x`, `large=1.125x`.
- **D-04:** Existing-user data migration policy (`nil/medium -> small`) is implemented in Phase 38, not this phase.

### Theme Precedence
- **D-05:** Final font-size authority is `body.font-size-*` in `common.css.scss`; theme files should follow using `inherit`/`rem` rather than redefining `body` base size.
- **D-06:** Device-specific medium baseline is defined in shared CSS variables in `common.css.scss` and switched with the existing mobile breakpoint policy.
- **D-07:** In Phase 37, only high-impact theme selectors are adjusted toward `inherit`/`rem`; full theme-wide `px -> rem` conversion is deferred.
- **D-08:** Phase 37 must include automated tests for body-class precedence and representative selectors across modern/classic/simple.

### the agent's Discretion
- Select the minimal high-impact selector set per theme for Phase 37 adjustments, as long as D-05 through D-08 remain true.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Contracts
- `.planning/ROADMAP.md` — Phase 37 goal, requirement mapping, and success criteria.
- `.planning/REQUIREMENTS.md` — `FONT-01..04`, `SAFE-01`, and traceability status.
- `.planning/PROJECT.md` — current milestone scope and active constraints.
- `.planning/STATE.md` — current focus and phase sequencing context.

### Research Inputs
- `.planning/research/SUMMARY.md` — integrated stack/feature/architecture/pitfall conclusions for v1.11.
- `.planning/research/STACK.md` — CSS-first baseline strategy and stack guardrails.
- `.planning/research/ARCHITECTURE.md` — phased integration approach and compatibility seam guidance.
- `.planning/research/PITFALLS.md` — precedence/conflict pitfalls and mitigation checklist.

### Code Contracts
- `app/helpers/welcome_helper.rb` — current `font_size_class` fallback contract.
- `app/views/layouts/application.html.erb` — body class composition (`theme + font-size class`).
- `app/views/preferences/index.html.erb` — font-size select options and default selection behavior.
- `app/models/preference.rb` — allowed font-size constants and validation scope.
- `app/assets/stylesheets/common.css.scss` — current shared font-size class definitions.
- `app/assets/stylesheets/themes/modern.css.scss` — theme typography overrides that can conflict with shared contract.
- `app/assets/stylesheets/themes/classic.css.scss` — theme typography overrides that can conflict with shared contract.
- `app/assets/stylesheets/themes/simple.css.scss` — theme typography overrides that can conflict with shared contract.

### Test Surfaces
- `test/models/preference_test.rb` — font-size value validity baseline.
- `test/controllers/preferences_controller_test.rb` — font-size save/select/body-class rendering coverage.
- `test/assets/modern_full_page_theme_contract_test.rb` — existing typography contract assertions in modern theme.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Preference::FONT_SIZES` and existing preferences form rendering provide a stable symbolic API surface to preserve.
- `WelcomeHelper#font_size_class` already centralizes body class emission and is the right seam for fallback normalization.
- Existing theme SCSS files are already separated by theme, enabling targeted high-impact selector adjustments.

### Established Patterns
- Shared styling primitives belong in `common.css.scss`; theme-specific deltas belong under `app/assets/stylesheets/themes/`.
- Body-level classes drive global behavior contracts throughout the app (`theme` and `font-size` are both attached to `<body>`).
- Rails integration tests assert rendered selectors and option values for preference behavior and i18n.

### Integration Points
- Core integration path: `Preference#font_size` -> `WelcomeHelper#font_size_class` -> `<body class=...>` -> shared/theme SCSS.
- Phase 37 code changes will touch model/helper/view/SCSS/test layers simultaneously to keep contract coherence.
- Phase 38 migration must consume the Phase 37 runtime contract without introducing temporary precedence drift.

</code_context>

<specifics>
## Specific Ideas

- Implement shared CSS variables for medium baseline in `common.css.scss`, switched by existing mobile breakpoint.
- Preserve `body.font-size-small|medium|large` contract and drive effective size via variables/multipliers.
- Add targeted selector-level contract tests per theme to guard against precedence regressions.

</specifics>

<deferred>
## Deferred Ideas

- Full theme-wide typography normalization (`px -> rem`) across all selectors.
- Per-device size preview/help UX enhancements from v2 requirements.

</deferred>

---

*Phase: 037-device-aware-typography-contract*
*Context gathered: 2026-05-06*
