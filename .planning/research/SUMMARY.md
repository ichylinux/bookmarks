# Project Research Summary

**Project:** Bookmarks  
**Domain:** Device-aware font-size baseline for PC/mobile  
**Researched:** 2026-05-06  
**Confidence:** MEDIUM-HIGH

## Executive Summary

This milestone is a typography-behavior update, not a stack rewrite. The strongest path is to keep the existing Rails/Sprockets/preference model contract and implement device-aware sizing in CSS, while preserving the existing `small|medium|large` symbolic preference API for users and controllers.

**Agreed policy (explicit):** **Medium baseline differs by device (PC vs mobile), Small/Large are relative scaling from that Medium baseline, and one-time migration policy is `nil/medium -> small`.** This gives deterministic behavior across devices without storing per-device pixel values.

The key risks are semantic drift (fallbacks still acting like old medium), migration ordering errors, and theme CSS precedence conflicts. Mitigation is phased delivery: canonical mapping first, CSS contract second, data migration/UI alignment third, then cleanup and strictness.

## Key Findings

### Stack additions

- **No new runtime stack**: keep Rails 8.1, ActiveRecord, Sprockets, existing `preferences.font_size`.
- **Core implementation layer**: `common.css.scss` with device baseline tokens + relative scaling multipliers.
- **Model/helper seam**: add canonical mapping (`effective_font_size`) so fallback logic is centralized.
- **Version/contract guardrail**: keep `<body class="font-size-*">` contract stable during transition.

### Feature table stakes

- Keep exactly **3 options** (Small / Medium / Large), same label/order.
- Store **symbolic preference** only (`small|medium|large`), not per-device px.
- Enforce deterministic ordering on each device: `small < medium < large`.
- Apply one-time migration safely and idempotently: **`nil/medium -> small`**.
- Preserve explicit user choice post-release (if user picks medium later, do not auto-downgrade again).
- Safe fallback for invalid values (render predictable class, no exception).

### Architecture approach

Major components:
1. **Preference model mapping** — single canonical value mapper for runtime compatibility.
2. **Helper/layout integration** — delegate class selection to mapper; keep body-class contract.
3. **CSS baseline contract** — device-aware Medium baseline (`pc/mobile`) + relative small/large multipliers.
4. **Data migration** — backfill legacy rows (`NULL` and `medium`) to `small`, idempotent.

### Watch-outs (top pitfalls)

1. **Semantic drift** (old medium fallback still present) — remove duplicated fallback literals and centralize mapping.
2. **Wrong sequencing** (remove medium before DB backfill) — migrate first, tighten validation/options later.
3. **Theme precedence conflicts** (`px` rules override root scaling) — define precedence and add cross-theme regression checks.
4. **UI/i18n mismatch** (labels/options lag semantic change) — update form options + locale semantics + tests together.
5. **Insufficient rollout checks** — add helper-level tests and post-deploy SQL verification for legacy rows.

## Implications for Roadmap

### Phase 1: Semantics contract seam
**Rationale:** Prevent regressions before behavior change.  
**Delivers:** Canonical mapper + helper delegation; tests for `nil/medium -> small`.  
**Addresses:** fallback consistency and deterministic rendering.  
**Avoids:** Pitfall 1 (semantic drift).

### Phase 2: Device-aware baseline CSS
**Rationale:** Core value delivery with minimal data risk.  
**Delivers:** PC/mobile Medium baseline + relative Small/Large scaling in shared CSS contract.  
**Addresses:** device-aware typography requirement.  
**Avoids:** Pitfall 3 (theme/CSS conflict) via precedence checks.

### Phase 3: Migration + UI alignment
**Rationale:** Persisted data must match live semantics.  
**Delivers:** Idempotent migration (`nil/medium -> small`), default selection updates, acceptance tests.  
**Addresses:** stable behavior for existing users.  
**Avoids:** Pitfall 2 and 4 (ordering and UI lag).

### Phase 4: Cleanup and hardening
**Rationale:** Tighten contracts only after production stability.  
**Delivers:** Optional removal/deprecation of medium path, optional DB constraints, rollout checks.  
**Addresses:** long-term maintainability.  
**Avoids:** rollout regressions from premature strictness.

### Research Flags

Needs deeper research during planning:
- **Phase 2:** theme-specific `px -> rem` conversion scope and priority (readability impact by theme/device).
- **Phase 4:** safe timing for removing medium support entirely (requires post-migration production validation).

Standard patterns (can skip extra research-phase):
- **Phase 1:** model/helper fallback centralization.
- **Phase 3:** idempotent ActiveRecord data migration and regression-test updates.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong repo-grounded consensus: CSS-first, no new runtime dependencies. |
| Features | HIGH | Clear table-stakes and migration policy captured; explicit acceptance candidates present. |
| Architecture | MEDIUM-HIGH | Good phased design; one open decision on medium-option end-state timing. |
| Pitfalls | HIGH | Concrete warnings tied to current helper/view/CSS realities. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- Final PC/mobile Medium baseline pixel targets must be confirmed with design/product.
- Decide whether medium remains visible long-term or is only compatibility-time alias.
- Define minimum required theme rem-conversion scope for this milestone vs follow-up phase.

## Sources

### Primary
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `app/models/preference.rb`, `app/helpers/welcome_helper.rb`
- `app/views/preferences/index.html.erb`, `app/views/layouts/application.html.erb`
- `app/assets/stylesheets/common.css.scss`, `app/assets/stylesheets/themes/*.css.scss`
- `test/controllers/preferences_controller_test.rb`, `test/models/preference_test.rb`, `db/schema.rb`

### External references cited in research inputs
- MDN Pointer Events, MDN Web Storage API, jQuery API (legacy references present in STACK.md source set)

---
*Research completed: 2026-05-06*  
*Ready for roadmap: yes*

## Requirement Candidate Checklist

- [ ] Canonical mapping rule implemented and tested: `nil/medium -> small`.
- [ ] Medium baseline defined separately for PC and mobile in shared CSS contract.
- [ ] Small/Large implemented as relative multipliers from Medium on both device classes.
- [ ] One-time migration is idempotent and excludes already `small/large` users.
- [ ] Preferences UI retains exactly 3 options and preserves explicit post-release user choices.
- [ ] Cross-theme verification confirms no major readability regressions after baseline change.
