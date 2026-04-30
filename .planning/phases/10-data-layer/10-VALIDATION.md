---
phase: 10
slug: data-layer
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-30
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest 5.x (Rails 8.1 default) |
| **Config file** | `test/test_helper.rb` (standard Rails) |
| **Quick run command** | `bin/rails test test/models/note_test.rb` (Wave 0 — file created in this phase if model test is included) |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~30 seconds (full suite, depending on existing test count) |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/models/note_test.rb` (when present) and/or `bin/rails routes | grep notes`
- **After every plan wave:** Run `bin/rails test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green; `bin/rails db:migrate` exits clean; `db/schema.rb` reflects new `notes` table
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | NOTE-03 / SC#1 | — | Migration creates `notes` table with composite index | smoke | `bin/rails db:migrate` (exit 0) + grep `db/schema.rb` for `notes` | ✅ Rails built-in | ⬜ pending |
| 10-01-02 | 01 | 1 | SC#1 | — | Schema reflects table | grep | `grep -q 'create_table "notes"' db/schema.rb` | ✅ written by migrate | ⬜ pending |
| 10-02-01 | 02 | 2 | NOTE-03 / SC#2 | — | `Note` enforces ownership + validations | unit | `bin/rails test test/models/note_test.rb` | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 2 | SC#3 | — | `User.has_many :notes, dependent: :destroy` | grep / unit | `grep -q 'has_many :notes' app/models/user.rb` | ✅ existing file | ⬜ pending |
| 10-04-01 | 04 | 2 | SC#4 | — | Routes registered | rake | `bin/rails routes \| grep notes` shows `POST /notes` and `DELETE /notes/:id` | ✅ Rails built-in | ⬜ pending |
| 10-05-01 | 05 | 1 | downstream support | — | Empty fixture stub exists | grep | `test -f test/fixtures/notes.yml` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/fixtures/notes.yml` — empty stub (REQUIRED — downstream phases load fixtures)
- [ ] `test/models/note_test.rb` — model unit test covering presence, max length, whitespace stripping, `Crud::ByUser` ownership predicates (RECOMMENDED — locks the validation contract)

*If model test is deferred to Phase 11, mark this section "deferred" rather than removing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `db/schema.rb` regenerated correctly after migrate | SC#1, SC#5 | One-time confirmation; downstream tasks rely on schema being committed | Run `bin/rails db:migrate`, inspect `db/schema.rb` diff, ensure `create_table "notes"` block matches expected columns + index |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`notes.yml`, optionally `note_test.rb`)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (planner sets after plan task list is final)

**Approval:** pending
