<!-- generated-by: gsd-doc-writer -->
# Security Policy

Bookmarks is a self-hosted personal bookmarks, feed reader, to-do, and calendar
application. It is not distributed as a package or a hosted service — each
operator runs their own instance from source. The security model below reflects
that: there is one supported line of code, and each deployment is responsible
for its own environment.

## Supported Versions

Only the latest `master` is supported. There are no maintained release branches
and no backported security patches; fixes land on `master` and operators are
expected to pull.

| Version | Supported |
| ------- | ------------------ |
| `master` (latest commit) | :white_check_mark: |
| Tagged milestones (v1.x) | :x: — snapshots only, not patched |
| Any older checkout | :x: |

If you run a pinned commit, treat updating to current `master` as the remedy for
any reported vulnerability.

## Reporting a Vulnerability

**Do not open a public GitHub issue for a security problem.**

Report privately through either channel:

1. **GitHub private vulnerability reporting** (preferred) — the *Security* tab of
   [ichylinux/bookmarks](https://github.com/ichylinux/bookmarks) → *Report a
   vulnerability*.
2. **Email** — ichylinux@gmail.com, with `[SECURITY]` in the subject.

Please include:

- A description of the issue and the impact you believe it has
- Steps to reproduce, ideally a minimal proof of concept
- Affected commit SHA or branch
- Environment details: Ruby version, Rails version, MySQL version, OS, and
  whether the instance runs behind a reverse proxy or TLS terminator

### What to expect

This project is maintained by a single person as a side project, so timelines
are best-effort rather than contractual:

| Stage | Target |
| ----- | ------ |
| Acknowledgement of your report | within 7 days |
| Initial assessment (accepted / declined / need more info) | within 14 days |
| Progress update while work is ongoing | every 14 days |
| Fix on `master` for accepted high-impact issues | within 30 days where practical |

If a report is **accepted**, the fix is committed to `master` and, where the
issue affects existing deployments, a GitHub Security Advisory is published so
operators are notified. Credit is given in the advisory unless you ask to remain
anonymous.

If a report is **declined**, you will get the reasoning — commonly that the
behavior is out of scope (see below), that it requires a misconfiguration the
project does not recommend, or that it is not reachable in the shipped code.

Please give a reasonable window to ship a fix before publishing details.

## Scope

### In scope

- Authentication and session handling — Devise, two-factor authentication
  (TOTP), and OmniAuth sign-in (Google, X, Facebook, Mastodon)
- Authorization gaps that let one user read or modify another user's bookmarks,
  feeds, to-dos, calendar entries, visited links, or preferences
- Injection flaws: SQL injection, XSS, CSRF, open redirect, SSRF via feed and
  page-title fetching
- Exposure of secrets or encrypted attributes (for example the TOTP
  `otp_secret`, encrypted via ActiveRecord Encryption)
- Remote code execution or arbitrary file read/write
- Vulnerabilities in pinned dependencies that are demonstrably reachable from
  this application's code

### Out of scope

- Misconfiguration of an operator's own deployment — running without TLS,
  exposing MySQL publicly, committing a real `.env`, or leaving the default
  development encryption keys in place (see *Hardening* below)
- Findings against the development or test environments, which intentionally use
  weak, hardcoded defaults
- Dependency advisories with no demonstrated exploit path in this application
- Missing security headers, cookie flags, or rate limiting with no concrete
  impact shown
- Denial of service that requires an already-authenticated account, resource
  exhaustion through ordinary usage, or volumetric attacks
- Social engineering, physical access, and attacks on third-party OAuth
  providers themselves
- Automated scanner output submitted without validation

## Hardening your deployment

Because every instance is self-hosted, most real-world risk lives in the
deployment rather than the code. At minimum:

- **Set the encryption keys.** `config/application.rb` falls back to a hardcoded
  `dev_dummy_key` when the environment variables are absent. In production always
  set `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`,
  `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, and
  `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` to unique random values, and
  never reuse the development defaults.
- **Set a unique `SECRET_KEY_BASE`** and keep it out of version control.
- **Serve over HTTPS.** `config.force_ssl = true` is enabled in
  `config/environments/production.rb`; terminate TLS in front of the app and do
  not disable this.
- **Keep `.env` and OAuth credentials out of git**, and rotate any secret that
  has ever been committed.
- **Do not expose MySQL** beyond the application host.
- **Enable two-factor authentication** from the preferences page for every
  account.
- **Pull `master` regularly** — that is the only channel through which security
  fixes reach you.

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for the full list of
environment variables and [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) for
deployment prerequisites.

## Security-relevant contributions

Fixes for security bugs follow the normal [contribution
process](CONTRIBUTING.md), including the three-suite gate
(`yarn run lint && bin/rails test && bundle exec rake dad:test`) — but if the
fix would disclose an unreported vulnerability, contact the maintainer privately
first rather than opening a public pull request.
