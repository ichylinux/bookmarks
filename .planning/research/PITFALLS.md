# Domain Pitfalls - Guest Redirect Milestone

**Domain:** Root entry routing changes in authenticated Rails app  
**Researched:** 2026-05-08

## Critical Pitfalls

### 1) Breaking signed-in root behavior
**Risk:** Root redirect logic also affects authenticated users.  
**Prevention:** Guard redirect by auth state only; keep dashboard controller path unchanged.  
**Detection:** Signed-in root test fails or dashboard selectors disappear.

### 2) Redirect loop between auth pages and root
**Risk:** Misconfigured route/controller redirects loop through `/` and `/landing` or sign-in.  
**Prevention:** Keep one-way guest redirect `/ -> /landing`; keep `/landing` public.  
**Detection:** Integration test sees repeated 30x chain.

### 3) Locale regression on entry route
**Risk:** Redirect/render loses ja/en expectations.  
**Prevention:** Keep existing locale resolution pipeline untouched; add locale-aware tests.  
**Detection:** `html[lang]` or localized copy assertions fail.

## Moderate Pitfalls

### 4) CTA contract drift
**Risk:** Landing CTA classes/links change during redirect refactor.  
**Prevention:** Keep CTA selector contracts and assert links in tests.  
**Detection:** Landing CTA tests fail.

### 5) Coverage gap between Minitest and Cucumber
**Risk:** Only one suite validates entry behavior.  
**Prevention:** Cover at least integration tests; add E2E assertion if route behavior is user-visible.  
**Detection:** Regression appears in one suite only.
