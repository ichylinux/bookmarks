---
status: complete
phase: 89-static-policy-pages
source: 89-01-SUMMARY.md, 89-02-SUMMARY.md
started: 2026-05-19T00:00:00Z
updated: 2026-05-19T00:01:00Z
---

## Current Test

[testing complete]

## Tests

### 1. /privacy accessible without login
expected: Open /privacy in a browser while logged out (or in a private/incognito window). The page loads with HTTP 200 — no redirect to the login page.
result: pass

### 2. /terms accessible without login
expected: Open /terms in a browser while logged out. The page loads with HTTP 200 — no redirect to the login page.
result: pass

### 3. Privacy page content — Japanese
expected: /privacy shows a page title (h1) and 5 clearly-separated sections in Japanese: data_collected (収集するデータ), x_login (Xログイン), email_handling (メール), data_retention (データ保持), contact (お問い合わせ). Each section has a heading and paragraph text.
result: pass

### 4. Privacy page — language switcher
expected: On /privacy, a language switcher (EN / JA or similar) is visible. Clicking the EN link reloads the page in English — the heading and all 5 sections render in English.
result: pass

### 5. Terms page content — Japanese
expected: /terms shows a page title (h1) and 3 sections in Japanese: acceptable_use (利用規約), availability (可用性), termination (退会). Each section has a heading and paragraph text.
result: pass

### 6. Terms page — language switcher
expected: On /terms, clicking the EN link switches to English — title and all 3 sections render in English.
result: pass

### 7. Back link on policy pages
expected: Both /privacy and /terms show a back link (e.g., "← ホーム" or "← Back") that navigates away from the policy page.
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
