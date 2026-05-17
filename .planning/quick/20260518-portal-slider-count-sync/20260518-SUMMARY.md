---
quick_id: "20260518"
slug: portal-slider-count-sync
status: complete
date: 2026-05-18
commit: 35c7c75
---

# Quick Task 20260518: ポータル列数変更時のスライダー数連動修正

## What was done

`_portal_column_widths.html.erb` の `<template data-portal-width-row-template>` が `data-portal-column-widths-root` の外側にあったため、`rebuildControls()` 内の `root.querySelector('[data-portal-width-row-template]')` が `null` を返し、列数変更時にスライダーが再構築されなかった。

テンプレート要素をルート div の内側に移動することで修正。

## Root cause

```html
</div>  ← root 閉じタグ
<template data-portal-width-row-template>  ← rootの外 (バグ)
```

→

```html
  <template data-portal-width-row-template>  ← rootの内側 (修正)
  </template>
</div>  ← root 閉じタグ
```

## Verification

- `yarn run lint` ✓
- `bin/rails test` — 416 runs, 0 failures ✓
- `bundle exec rake dad:test` — 25/25 passed ✓
