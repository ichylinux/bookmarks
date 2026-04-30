---
phase: 12
phase_name: Tab UI
created: 2026-04-30
purpose: Pattern mapping — files, roles, data flow, codebase analogs
---

# Phase 12 — Pattern Mapping (Tab UI)

Synthesized from `12-CONTEXT.md`, `12-UI-SPEC.md`, and `12-RESEARCH.md`, with verified analogs under `app/` and `test/`.

---

## 1. Files to create / modify

| Path | Action | Phase source |
|------|--------|----------------|
| `app/views/welcome/index.html.erb` | Modify | CONTEXT canonical_refs, UI-SPEC layout, RESEARCH §Files |
| `app/assets/stylesheets/welcome.css.scss` | Modify | CONTEXT (tabs under `.simple` only), UI-SPEC style location |
| `app/assets/javascripts/notes_tabs.js` (name discretionary — e.g. `notes.js` also OK) | Create | CONTEXT (`notes.js or inline`), UI-SPEC §実装場所, RESEARCH |
| `app/views/welcome/_simple_tabs.html.erb` | Optional create | RESEARCH organizer partial |
| `test/controllers/welcome_controller/welcome_controller_test.rb` or new focused test file | Extend | RESEARCH TAB-01/03 strategy |
| `test/controllers/welcome_controller/layout_structure_test.rb` | Optional extend | RESEARCH SC4 — assert absence on modern/classic |

**Explicitly unchanged in normal plan (already correct or out of phase scope):**

- `app/controllers/notes_controller.rb` — already `redirect_to root_path(tab: 'notes')` (TAB-03 server side).
- `app/controllers/welcome_controller.rb` — only if planner adds optional `@initial_tab` / SSR first paint for `params[:tab]` (RESEARCH assumption A1).
- `app/views/layouts/application.html.erb`, `app/views/common/_menu.html.erb`, `app/assets/stylesheets/common.css.scss`, `app/assets/stylesheets/themes/simple.css.scss`, `app/assets/javascripts/application.js` — behave as **analog references** or minimal touch (`application.js`: `require_tree .` already includes new sibling JS).

---

## 2. Per-file classification

### `app/views/welcome/index.html.erb`

| Dimension | Classification |
|-----------|------------------|
| **Role** | Server-rendered welcome view; SSR structure for tab strip + dual panels |
| **Tier** | ERB / presentation |
| **Data flow in** | `favorite_theme` (helper), `params[:tab]` (optional SSR hints), `@portal`, `current_user`-derived gadgets (`render gadget`) |
| **Data flow out** | Static HTML/DOM hooks for Phase 13 (`id`/`class` on notes panel); unchanged `collect_portal_layout_params` POST to `save_state` |

**Analog (same surface):** current file is the insertion point — wrap `div.portal` in home panel without breaking `#column_*` / `.gadgets` selectors used by embedded sortable script.

### `app/assets/javascripts/notes_tabs.js` (new)

| Dimension | Classification |
|-----------|------------------|
| **Role** | Client-side tab switching; bootstrap from query string once per load |
| **Tier** | Browser / jQuery |
| **Data flow in** | `window.location.search` (`URLSearchParams`), DOM from ERB (`button`, panel containers) |
| **Data flow out** | `show()` / `hide()` (or equivalent) on panels; optional class toggles for active styling; **no** `history.pushState` / `replaceState`, **no** full navigation |

**Analog:** inverse of drawer behavior in `menu.js` — tabs run only when `body` matches simple theme.

### `app/assets/stylesheets/welcome.css.scss`

| Dimension | Classification |
|-----------|------------------|
| **Role** | Simple-theme-only tab strip and panel visuals |
| **Tier** | SCSS scoped to `.simple` |
| **Data flow** | None (pure styling) |

**Constraint:** Tab rules live **only** here under `.simple { … }`; do **not** add tab rules to `common.css.scss` (CONTEXT / STATE / UI-SPEC).

### Optional `app/views/welcome/_simple_tabs.html.erb`

| Dimension | Classification |
|-----------|------------------|
| **Role** | Extract tab strip + panel wrappers from `index` for readability |

**Analog:** `app/views/common/_menu.html.erb` — theme-specific chrome injected from layout/welcome branch.

---

## 3. Reference-only analogs (closest existing patterns)

### Body theme class + simple menu gate — `application.html.erb`

```16:31:app/views/layouts/application.html.erb
  <body class="<%= favorite_theme %>">
    <div id="header">
      <div class="head-box">
        <img src="/icon.svg" alt="Bookmarks" class="header-icon" />
        <%= link_to 'Bookmarks', root_path, class: 'head-title' %>
        <% if user_signed_in? && favorite_theme != 'simple' %>
          <span class="head-user-email"><%= current_user.display_name %></span>
          <button class="hamburger-btn" aria-label="メニュー"></button>
        <% end %>
      </div>
    </div>

    <div class="wrapper">
      <%= render 'common/menu' if user_signed_in? && favorite_theme == 'simple' %>
      <%= yield %>
```

**Pattern:** `favorite_theme` on `<body>` + `user_signed_in? && favorite_theme == 'simple'` for simple-only chrome. Tabs should use the **same simple predicate** for markup (CONTEXT D-05, RESEARCH).

### Simple top nav — `_menu.html.erb` (`ul.navigation`, inline layout)

```33:46:app/views/common/_menu.html.erb
  <div>
    <ul class="navigation">
      <li><%= link_to 'Home', root_path %></li>
      <li class="email">
        <a href="#"><%= current_user.display_name %><span style="font-size: 0.8em;"> ▼</span></a>
        <div class="menu hidden">
          <div><%= link_to '設定', preferences_path %></div>
          <div><%= link_to 'ブックマーク', bookmarks_path %></div>
          <div><%= link_to 'タスク', todos_path %></div>
          <div><%= link_to 'カレンダー', calendars_path %></div>
          <div><%= link_to 'フィード', feeds_path %></div>
          <div><%= link_to 'ログアウト', destroy_user_session_path, method: 'delete' %></div>
        </div>
      </li>
    </ul>
  </div>
```

**Pattern:** Tabs are **`button type="button"`** (D-08), but **visual** alignment targets this list: horizontal strip, nav-adjacent hierarchy (UI-SPEC, CONTEXT D-06/D-08).

### Theme-guarded JS — `menu.js`

```1:32:app/assets/javascripts/menu.js
$(function() {
  if (!$('body').hasClass('modern') && !$('body').hasClass('classic')) return;

  const $body = $('body');

  const closeDrawer = function() {
    $body.removeClass('drawer-open');
  };

  const toggleDrawer = function() {
    $body.toggleClass('drawer-open');
  };

  $('.hamburger-btn').on('click', function(e) {
    e.stopPropagation();
    toggleDrawer();
  });

  $('.drawer-overlay').on('click', function() {
    closeDrawer();
  });

  $(document).on('keydown.phase8Drawer', function(e) {
    if (e.key === 'Escape' && $body.hasClass('drawer-open')) {
      closeDrawer();
    }
  });

  $('.drawer nav').on('click', 'a', function() {
    closeDrawer();
  });
});
```

**Pattern:** Early return unless body matches intended theme(s). Phase 12: **`if (!$('body').hasClass('simple')) return;`** at top (UI-SPEC, RESEARCH inverse symmetry).

### Sprockets includes all sibling JS — `application.js`

```13:17:app/assets/javascripts/application.js
//= require rails-ujs
//= require activestorage
//= require jquery
//= require jquery-ui
//= require_tree .
```

**Pattern:** New `notes_tabs.js` under `app/assets/javascripts/` is picked up without editing the manifest unless load-order demands an explicit `//= require` (RESEARCH).

### Header/nav typography & spacing baseline — `common.css.scss`

```273:303:app/assets/stylesheets/common.css.scss
.header {
  margin: 4px 10px 0 10px;
  height: 20px;
  line-height: 20px;
  
  ul.navigation {
    padding: 0;

    li {
      list-style: none;
      display: inline-block;
      margin: 0 10px;
    }

    .email {
      float: right;
    }
  }

  .menu {
    position: absolute;
    border: solid 1px #595757;
    background: #EEEEEE;
```

**Pattern:** 20px line box, horizontal `inline-block` list, 10px horizontal rhythm (UI-SPEC aligns tab strip with `.header` / `.wrapper` 10px lateral line).

### Simple theme shell — `themes/simple.css.scss`

```1:11:app/assets/stylesheets/themes/simple.css.scss
.simple {
  #header {
    display: none;
  }
}

.simple {
  .wrapper {
    padding: 0 10px 10px 10px;
  }
}
```

**Pattern:** Global simple-theme adjustments stay here; tab-specific visuals still go into `welcome.css.scss` under `.simple` per phase contract — do not relocate tab styling into this file unless project convention changes.

### Portal + sortable DOM contract — `welcome/index.html.erb` (preserve)

```1:44:app/views/welcome/index.html.erb
<script>
  function collect_portal_layout_params() {
    <% @portal.portal_column_count.times.each do |i| %>
      var column_<%= i %> = new Array();
      $('#column_<%= i %> > div').each(function() {
        column_<%= i %>.push($(this).attr('id'));
      });
    <% end %>

    return {
      'authenticity_token': '<%= form_authenticity_token %>',
      <% @portal.portal_column_count.times.each do |i| %>
        'portal[column_<%= i %>]': column_<%= i %>,
      <% end %>
    };
  }

  $(document).ready(function() {
    $('.gadgets').sortable({
      connectWith: '.gadgets',
      handle: 'div.title',
      start: function() {
        $(this).addClass('dragging')
      },
      stop: function() {
        $(this).removeClass('dragging')
      },
      update: function(event, ui) {
        var params = collect_portal_layout_params();
        $.post('<%= url_for action: 'save_state' %>', params);
      }
    });
  });
</script>

<div class="portal">
  <% @portal.portal_columns.each_with_index do |gadgets, i| %>
    <div id="column_<%= i %>" class="gadgets">
```

**Pattern:** `#column_*` and `.gadgets` must remain intact inside **home panel** after tab refactor (RESEARCH pitfall — sortable + `collect_portal_layout_params`).

### Welcome CSS extension point — `welcome.css.scss`

```1:26:app/assets/stylesheets/welcome.css.scss
div.portal {
  margin-top: 2px;
}

div.gadgets {
  float: left;
  width: 33.33%;
  padding-bottom: 100px;
  
  div.gadget {
    div {
      margin: 4px;
      overflow: hidden;

      div.title {
        margin: 0;
        padding: 4px;
        font-weight: bold;
        background: rgba(0, 0, 0, .20);
      }
```

**Pattern:** Add **new** `.simple { … tab strip / panels … }` block here; retains gadget title styling lineage for Accent/Secondary cues (UI-SPEC color table).

### Post-save redirect with `tab` — `notes_controller.rb`

```1:10:app/controllers/notes_controller.rb
class NotesController < ApplicationController
  def create
    @note = Note.new(note_params)

    if @note.save
      redirect_to root_path(tab: 'notes')
    else
      redirect_to root_path(tab: 'notes'), alert: @note.errors.full_messages.to_sentence.presence || 'エラーが発生しました'
    end
  end
```

**Pattern:** TAB-03 is satisfied when welcome + JS honor `?tab=notes` on full load after redirect.

### Existing redirect assertion — `notes_controller_test.rb`

```9:21:test/controllers/notes_controller_test.rb
  def test_successful_create
    sign_in @user

    assert_difference('Note.count', 1) do
      post notes_path, params: { note: { body: '新しいメモ' } }
    end

    assert_response :redirect
    assert_redirected_to root_path(tab: 'notes')

    note = Note.order(id: :desc).first
    assert_equal '新しいメモ', note.body
    assert_equal @user.id, note.user_id
  end
```

**Pattern:** Phase 12 adds **welcome-level** asserts (Japanese labels `ホーム` / `ノート`, optional panel marker, `get root_path(tab: 'notes')`), per RESEARCH — do not assert English TAB copy from REQUIREMENTS traceability IDs.

### Theme integration test analog — `layout_structure_test.rb`

```5:11:test/controllers/welcome_controller/layout_structure_test.rb
  def test_モダンテーマでハンバーガーボタンが表示される
    user.preference.update!(theme: 'modern')
    sign_in user
    get root_path
    assert_response :success
    assert_select 'button.hamburger-btn[aria-label=?]', 'メニュー', count: 1
  end
```

**Pattern:** `user.preference.update!(theme: ...)` + `sign_in` + `get root_path` + `assert_select` — mirror for simple vs modern/classic tab DOM presence/absence (RESEARCH TAB-01, SC4).

### `favorite_theme` helper — `welcome_helper.rb`

```1:8:app/helpers/welcome_helper.rb
module WelcomeHelper

  def favorite_theme
    return 'modern' unless user_signed_in?
    return 'modern' unless current_user.preference.present?
    return current_user.preference.theme.presence || 'modern'
  end
end
```

**Pattern:** ERB compares `favorite_theme == 'simple'` consistently with `<body class="...">`.

---

## 4. Data flow summary (architecture)

```mermaid
flowchart LR
  subgraph load [Full page load]
    A["GET /?tab=optional"] --> B["ERB: favorite_theme simple?"]
    B -->|"no"| C["Portal DOM only"]
    B -->|"yes"| D["Tab strip + home + notes shell"]
    D --> E["notes_tabs.js: URLSearchParams"]
    E --> F["Correct panel visible"]
  end
  subgraph click [Tab button click]
    G["type=button"] --> H["jQuery show/hide"]
    H --> I["URL unchanged"]
  end
  subgraph save [Note POST]
    J["POST /notes"] --> K["Redirect /?tab=notes"]
    K --> load
  end
```

---

## 5. Implementation checklist (from contracts)

| Contract | Enforcement |
|---------|--------------|
| Simple-only DOM | `favorite_theme == 'simple'` in ERB around tabs + notes panel |
| Japanese labels | `ホーム`, `ノート` (CONTEXT D-01) |
| Triggers | `button type="button"` (CONTEXT D-08) |
| No URL on click | No `pushState` / `replaceState` (CONTEXT D-07) |
| Load bootstrap | `tab=notes` → notes panel; otherwise home (unknown → home per UI-SPEC) |
| JS guard | Immediate return unless `body.simple` |
| CSS scope | Tab rules under `.simple` in `welcome.css.scss` only |
| Phase 13 hooks | Stable `id`/`class` on notes panel container |

---

## PATTERN MAPPING COMPLETE
