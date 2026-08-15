---
status: complete
---

# Quick Task 260816-s7k Summary

## Problem

`SECURITY.md` was GitHub's unedited starter template (added in `c325fa9`): the
support table listed fictional 4.0.x/5.0.x/5.1.x versions this project has never
had, and the reporting section still read "Use this section to tell people how to
report a vulnerability." It gave a reporter no actual channel and gave operators
misleading version guarantees.

## Fix

Rewrote `SECURITY.md` around what the repo actually is — a self-hosted,
source-only Rails app with no release channel:

- **Supported Versions** — only latest `master`; milestone tags are snapshots,
  not patched lines. Remedy for any report is "pull `master`".
- **Reporting** — GitHub private vulnerability reporting (preferred) with an
  `[SECURITY]`-subject email fallback; explicit list of details to include
  (repro, commit SHA, Ruby/Rails/MySQL/OS, proxy-TLS topology).
- **Expectations table** — ack 7d, triage 14d, updates every 14d, fix within 30d
  where practical; stated as best-effort for a single maintainer. Accepted
  reports get a GitHub Security Advisory plus credit unless declined.
- **Scope** — in: Devise/TOTP/OmniAuth auth, cross-user authorization, injection
  incl. SSRF through feed and page-title fetching, encrypted `otp_secret`
  exposure, RCE, reachable dependency flaws. Out: operator misconfiguration,
  dev/test weak defaults, unreachable dependency advisories, impact-free header
  findings, DoS, scanner dumps.
- **Hardening** — grounded in real config rather than generic advice: the
  `ACTIVE_RECORD_ENCRYPTION_*` vars falling back to `dev_dummy_key`
  (`config/application.rb:39-41`), `config.force_ssl = true`
  (`config/environments/production.rb:31`), `SECRET_KEY_BASE`, `.env` hygiene and
  rotation, MySQL exposure, enabling 2FA, pulling `master`.
- Cross-links to `CONTRIBUTING.md`, `docs/CONFIGURATION.md`,
  `docs/GETTING-STARTED.md`; English to match README/CONTRIBUTING.

Contact published: `ichylinux@gmail.com` — already public in every commit's
author field, so no new disclosure.

## Verification

- `yarn run lint` ✓
- `bin/rails test` ✓ (703 runs, 3146 assertions, 0 failures)
- `bundle exec rake dad:test` — **not run**; docs-only change with no code,
  asset, or locale surface touched.
- Every factual claim traced to a repo file; all linked paths confirmed present.

## Commits

Single commit: `SECURITY.md` + this quick task's PLAN/SUMMARY + STATE.md row.
