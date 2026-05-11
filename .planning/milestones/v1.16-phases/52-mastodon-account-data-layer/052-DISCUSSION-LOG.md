---
phase: 52
name: MastodonAccount Data Layer
date: 2026-05-12
mode: autonomous (auto-answered)
---

# Discussion Log: Phase 52

## Mode

Self-discuss — no human present. Claude reasoned through gray areas autonomously.

## Areas Discussed

### 1. URL Parsing Callback Timing

**Options considered:**
- `before_validation` — parses before Rails validations fire
- `before_save` — parses after validation, too late for presence checks

**Decision:** `before_validation`

**Reasoning:** The model validates `instance` and `username` for presence. If parsing runs in `before_save`, those fields are blank during validation and the model always rejects valid records with a confusing error. `before_validation` ensures derived fields exist when validations run. Precedent: Note uses `before_validation :strip_body` for the same structural reason.

---

### 2. Validation Strategy for Invalid URLs

**Options considered:**
- Custom validator that tests profile_url format with regex
- Validate derived fields (instance, username) for presence after callback

**Decision:** Validate derived fields (presence: true on instance and username)

**Reasoning:** The callback either populates both or leaves both blank. A presence check on both fields cleanly covers the "URL present but unparseable" case without duplicating the regex in two places. Simpler than a custom validator; consistent with how Note validates :body (single presence check, not format).

---

### 3. Supported URL Formats

**Options considered:**
- Strict: `https://instance/@username` only
- Lenient: also accept `/users/username` path style and `http://` scheme

**Decision:** Accept both `/@username` and `/users/username` path styles; accept both `https://` and `http://` schemes. Reject `@user@instance` handle notation.

**Reasoning:** Both path styles are emitted by real Mastodon instances (/@user is most common; /users/user appears on some). Both are valid profile URLs a user might copy from their browser. The handle format `@user@instance` is a Mastodon-specific notation that is not a URL and shouldn't appear in a browser address bar — rejecting it is correct and can be communicated via form placeholder.

---

### 4. display_count Defaulting

**Options considered:**
- DB-level default only (integer default: 5 in migration, no callback)
- Feed pattern: MastodonConst::DEFAULT_DISPLAY_COUNT = 5, `before_save :set_display_count`

**Decision:** Follow Feed pattern

**Reasoning:** Consistent with Feed, which uses the same column for the same purpose. The constant name documents the intent. DB default handles raw inserts; callback handles app-level zero/nil cases.

---

### 5. User Association Scope

**Options considered:**
- `has_many :mastodon_accounts` (no scope)
- `has_many :mastodon_accounts, -> { where(deleted: false) }` (scoped)

**Decision:** Scoped association

**Reasoning:** Matches `has_many :portals, -> { where(deleted: false) }` in User. The association should never surface soft-deleted records through standard Rails helpers. Direct queries can use `.not_deleted` or `.with_deleted` if needed.

---

## Claude's Discretion Items

- `instance` and `username` have DB-level default `''` (empty string) to satisfy `NOT NULL` at DB level while still being caught by `validates :instance, presence: true`. This avoids a NOT NULL constraint violation during ActiveRecord callbacks before the before_validation callback has run.
- Added `add_index :mastodon_accounts, [:user_id, :created_at]` — same as Note migration, appropriate for queries scoped by user.

## Deferred Ideas

- Store resolved Mastodon numeric account ID in DB (named in REQUIREMENTS.md Future Requirements section). Not in scope for Phase 52.
