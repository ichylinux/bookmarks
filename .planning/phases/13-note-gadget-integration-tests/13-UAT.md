---
status: complete
phase: 13-note-gadget-integration-tests
source:
  - 13-01-SUMMARY.md
  - 13-02-SUMMARY.md
  - 13-03-SUMMARY.md
  - 13-04-SUMMARY.md
started: 2026-04-30T12:55:00Z
updated: 2026-04-30T13:20:00Z
---

## Current Test

[testing complete]

## Tests

### 1. シンプルテーマでノートタブにガジェットが表示される
expected: Note タブで「ノート」「メモ」ラベル、textarea、入力欄への「保存」が見える
result: pass

### 2. メモが無いとき空状態になる
expected: 自分のメモが無い状態で Note タブを開くと、文言「メモはまだありません」だけが載り、一覧ブロックが出ない（見た目で空状態と分かる）
result: pass

### 3. メモ保存後も Note タブで先頭に表示される
expected: メモ本文を入力して保存すると、ページが再度読み込まれ URL に tab=notes が付いたままで、一覧の一番上にさきほど入力した本文が表示される（他ユーザーの操作は確認不要でもよい）
result: pass

### 4. 複数メモの並びとタイムスタンプ
expected: メモが2件以上あるとき、上ほど新しい内容で、各行に yyyy-mm-dd HH:MM 形式に見えるタイムスタンプがある
result: pass

### 5. テーマによるドロワー／メニューの出し分け
expected: シンプルテーマではハンバーガー・ドロワーオーバーレイがなく、画面上部タブがある。モダン（またはクラシック）ではハンバーガーとドロワーが使える
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
