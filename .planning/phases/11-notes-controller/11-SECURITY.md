---
phase: 11
slug: notes-controller
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-30
---

# Phase 11 — Security

> Threat register derived from `11-01-PLAN.md` `<threat_model>`; mitigations verified against `app/controllers/notes_controller.rb` and `test/controllers/notes_controller_test.rb`.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser → Rails | HTTP POST は `note[body]` が主入力; `user_id` はクライアント権威にしない | `body`（ユーザー作成テキスト、最大 4000 字） |
| Devise session → Controller | 作成時の所有は `current_user` のみ | セッションに紐づく `user_id`（認証済み主体） |
| Route surface | `create` のみ公開; delete は未ルーティング | POST `/notes` のみ |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-11-01 | Elevation of Privilege | Mass-assignment of `user_id` | mitigate | `permit(:body).merge(user_id: current_user.id)`; `test_user_id_param_cannot_override_current_user` | closed |
| T-11-02 | Spoofing | Unauthenticated note creation | mitigate | `ApplicationController` の `authenticate_user!`; `test_unauthenticated_redirects_to_sign_in` | closed |
| T-11-03 | Tampering | Creating notes for another account | mitigate | 常に `current_user.id` をマージ; 成功作成テストで `user_id` 一致を確認 | closed |
| T-11-04 | Information Disclosure | Error flash が内部情報を露呈 | accept | 検証エラーは `errors.full_messages.to_sentence`（ja ロケール）を flash に載せる — 運用許容の Rails 標準パターン（下記 Accepted Risks） | closed |

*Disposition: mitigate（実装）· accept（文書化リスク）· transfer（第三者）*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-11-01 | T-11-04 | ユーザー向けバリデーションメッセージを flash に載せると、モデル検証文言がユーザーに読める。内部スタックや秘密は含めず、プラン由来の許容パターン。 | gsd-secure-phase (Phase 11) | 2026-04-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-30 | 4 | 4 | 0 | Cursor / gsd-secure-phase |

### Evidence Summary

- **T-11-01:** `grep` `merge(user_id: current_user.id)` and `permit(:body)` in `notes_controller.rb`; injection test denies foreign `user_id`.
- **T-11-02:** Unauthenticated POST → `new_user_session_path`.
- **T-11-03:** Created row `user_id` equals signed-in `@user`; hijack POST does not assign `other_user.id`.
- **T-11-04:** Failure branch uses `full_messages.to_sentence`; accepted as product-facing UX (see AR-11-01).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-30
