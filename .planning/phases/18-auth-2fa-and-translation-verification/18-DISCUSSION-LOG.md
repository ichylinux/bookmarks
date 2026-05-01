# Phase 18: Auth, 2FA & Translation Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 18-auth-2fa-and-translation-verification
**Areas discussed:** Translation audit approach

---

## Gray area selection

| Area | Selected |
|------|----------|
| Devise sign-in page | |
| Verification test scope | |
| Translation audit approach | ✓ |

---

## Translation audit approach

### Audit scope (VERI18N-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Translate all, document exceptions | Find every hardcoded Japanese literal. Translate the UI ones; document user/external content (like holiday_jp names) as intentionally untranslated. Zero unexplained literals at phase end. | ✓ |
| Auth/2FA scope only | Only audit surfaces Phase 18 touches; trust Phase 17 for the rest. | |
| Grep + list, no translation required | Run a grep scan and produce a documented list; no translation required. | |

**User's choice:** Translate all, document exceptions
**Notes:** Carry forward the Phase 17 holiday_jp exception as a documented case.

---

### Key symmetry enforcement (VERI18N-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Minitest test | Persistent test that loads both YML files and asserts identical key sets. Runs on every `bin/rails test`. | ✓ |
| Rake task / one-time script | Manual diff tool, not enforced in CI. | |
| Manual diff only | One-time check, no ongoing enforcement. | |

**User's choice:** Minitest test
**Notes:** Enforced on every `bin/rails test` run going forward.

---

## Claude's Discretion

- **Devise sign-in page activation**: Which activation approach (engine vs. generate), which Devise pages to cover.
- **Failed sign-in flash key**: Whether `devise.sessions.invalid` needs to be added to locale files or if the Devise fallback to `devise.failure.invalid` is sufficient for AUTHI18N-03.
- **VERI18N-02 test type**: Minitest integration vs. Cucumber for representative locale path coverage; which specific paths count as "representative".

## Deferred Ideas

None raised during discussion.
