---
phase: 05-theme-foundation
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - app/assets/stylesheets/themes/modern.css.scss
  - app/views/preferences/index.html.erb
  - app/assets/javascripts/menu.js
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-28
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files were reviewed: the new modern theme stylesheet, the preferences view (which received a theme selector), and the menu JS stub. No critical/security issues were found. The ERB auto-escaping on `<body class="<%= favorite_theme %>">` safely handles any arbitrary theme string stored in the database, so there is no XSS vector. The main issues are a form builder variable shadow that silently masks the outer builder inside the nested block, a dead `create` action caused by a routing mismatch, CSS custom properties that are defined but never consumed, and a stub JS file with a phase-reference comment that should not be committed as-is.

---

## Warnings

### WR-01: Form Builder Variable Shadowing Masks Outer Builder

**File:** `app/views/preferences/index.html.erb:10`

**Issue:** The outer `form_with` block uses `|f|` and the inner `fields_for` block also reuses `|f|` as its block variable. Inside lines 10–30, any reference to `f` silently resolves to the inner (preference) form builder rather than the user form builder. The submit button on line 47 is outside the block and happens to use the correct outer `f`, but this is accidental. Any future field added inside the `fields_for` block that calls the outer builder (e.g., `f.text_field :name`) will silently submit against the wrong model.

**Fix:** Rename the inner block variable to a distinct name:
```erb
<%= f.fields_for :preference_attributes, @user.preference do |pref_f| %>
  <tr>
    <th><%= pref_f.label :theme %></th>
    <td>
      <%= pref_f.hidden_field :id %>
      <%= pref_f.select :theme, {'シンプル' => 'simple', 'モダン' => 'modern'}, include_blank: 'デフォルト' %>
    </td>
  </tr>
  ...
<% end %>
```

---

### WR-02: `PreferencesController#create` Is Unreachable Dead Code

**File:** `app/views/preferences/index.html.erb:1` / `app/controllers/preferences_controller.rb:8`

**Issue:** `form_with model: @user, url: preference_path(@user)` always generates a `PATCH` request because `@user` is a persisted `User` record (fetched via `current_user.id`). This routes every form submission to `preferences#update`, regardless of whether the user already has a preference. The `preferences#create` action can never be reached from this form. This is not a crash — `update` handles the first-save case correctly via `accepts_nested_attributes_for` with a blank `id` — but the `create` action is dead code that adds maintenance confusion.

**Fix:** Remove `PreferencesController#create` and remove `'create'` from the routes declaration, since all saves go through `update`. Alternatively, change the form URL to always point to `preferences_path` with `method: :post` and consolidate the logic into `create`. Either direction eliminates the dead action.

---

### WR-03: Modern Theme CSS Custom Properties Are Defined but Never Consumed

**File:** `app/assets/stylesheets/themes/modern.css.scss:2-6`

**Issue:** The `.modern` rule block declares four custom properties (`--modern-color-primary`, `--modern-bg`, `--modern-text`, `--modern-header-bg`) but no rule anywhere in the codebase references them via `var(--modern-*)`. The properties have no effect on rendered output. A browser applies CSS custom properties only when they are referenced with `var()`; mere declaration inside a selector does nothing on its own.

**Fix:** Either add `var()` usages for each property in `.modern`-scoped rules within this file, or remove the declarations until they are needed. Leaving unused custom properties gives a false impression that the theme is styled when it is not.

```scss
.modern {
  --modern-color-primary: #3b82f6;
  --modern-bg:            #ffffff;
  --modern-text:          #1a1a1a;
  --modern-header-bg:     #1e40af;

  // Consume the variables here:
  background-color: var(--modern-bg);
  color: var(--modern-text);

  #header {
    background-color: var(--modern-header-bg);
  }
}
```

---

### WR-04: `setup_link` Text Is Misleading When 2FA Is Already Enabled

**File:** `app/views/preferences/index.html.erb:43`

**Issue:** The link to `users_two_factor_setup_path` always renders the text `t('two_factor.setup_link')` which translates to "二段階認証の設定" (2FA setup). When 2FA is already enabled (line 34–35 shows the enabled status), the link text still says "setup" rather than "manage" or "change". The linked page (`two_factor_setup#show`) shows the enabled state with a disable button, but the entry-point text on the preferences page does not reflect this distinction.

**Fix:** Conditionally render different link text based on `current_user.two_factor_enabled?`:

```erb
<td>
  <% link_text = current_user.two_factor_enabled? ? t('two_factor.manage_link') : t('two_factor.setup_link') %>
  <%= link_to link_text, users_two_factor_setup_path %>
</td>
```

Add a `manage_link` key to `config/locales/ja.yml` (e.g., `manage_link: 二段階認証の管理`).

---

## Info

### IN-01: `menu.js` Contains a Stub with a Future-Phase Comment

**File:** `app/assets/javascripts/menu.js:3`

**Issue:** The file contains only a guard clause (`if (!$('body').hasClass('modern')) return;`) and a comment referencing "Phase 8" as the location where real logic will be added. There is no drawable behavior. Committing a stub with a cross-phase implementation comment is a TODO marker in production code.

**Fix:** Either add the minimal behavior that this phase actually delivers, or defer the file to the phase where it will be implemented. If deferring, do not commit the stub — it adds a file to the asset pipeline (via `require_tree .`) that executes on every page load for `modern` users.

---

### IN-02: `build_preference` Call in Controller Index Is Unreachable

**File:** `app/controllers/preferences_controller.rb:5`

**Issue:** `@user.build_preference unless @user.preference.present?` is never executed. `User#preference` is overridden (line 49–51 of `user.rb`) to return `Preference.default_preference(self)` when `super` returns nil. `default_preference` returns a new (unsaved) `Preference` instance, which is truthy (`present?` returns true for any non-nil AR object). As a result, `@user.preference.present?` is always `true` and `build_preference` is never called.

**Fix:** Remove the dead guard:

```ruby
def index
  @user = User.find(current_user.id)
end
```

The `User#preference` override already guarantees a preference object is available for the view.

---

_Reviewed: 2026-04-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
