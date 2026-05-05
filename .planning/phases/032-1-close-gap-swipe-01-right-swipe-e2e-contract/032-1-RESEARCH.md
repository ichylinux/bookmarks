# Phase 32.1 Research: SWIPE-01 / TEST-02 Gap Closure

## Objective

Close the remaining strict-audit inconsistencies by adding explicit automated contracts for:

1. Non-boundary right-swipe adjacent transition (SWIPE-01)
2. Explicit tab-click regression depth (TEST-02)

## Sources Reviewed

- `.planning/v1.8-MILESTONE-AUDIT.md`
- `features/03.モダンテーマ.feature`
- `features/step_definitions/modern_theme.rb`
- `test/assets/portal_mobile_tabs_js_contract_test.rb`
- `.planning/ROADMAP.md`

## Findings

### 1) Cucumber currently covers left swipe and boundary-right, but not non-boundary right swipe

- Existing scenarios include:
  - left swipe from column 1 to column 2
  - right swipe at boundary (column 1) stays unchanged
- Missing explicit path:
  - right swipe from a non-boundary column (e.g., column 2) should move to adjacent previous column (column 1)

### 2) Existing step definitions already support required assertions

- `2列目のポータル列がアクティブです。`
- `1列目のポータル列がアクティブのままです。`
- Swipe JS helpers can be extended with a new step for right swipe on active column 2.

### 3) JS contract test is currently persistence-focused

- `portal_mobile_tabs_js_contract_test.rb` checks persistence/restore and mobile-viewport guard.
- It does not include explicit static contract assertions tying swipe and tab interactions to the same activation path depth for regression evidence.

## Recommended Implementation

1. Add one Cucumber scenario in `features/03.モダンテーマ.feature`:
   - open root
   - click tab for column 2
   - swipe right on portal
   - assert column 1 active

2. Add one step definition in `features/step_definitions/modern_theme.rb`:
   - right swipe gesture helper for "currently active column" context (non-boundary use)

3. Extend `test/assets/portal_mobile_tabs_js_contract_test.rb` with explicit regression contracts:
   - assert tab click and swipe both call shared activation flow symbols
   - keep contract textual to avoid runtime browser coupling

4. Re-run tri-suite and feed results back into milestone audit / phase 32 verification.

## Risks and Guardrails

- Avoid changing production swipe logic unless tests expose real defects.
- Keep feature text and step naming consistent with existing Japanese convention.
- Maintain known `dad:test` flake policy in verification notes.
