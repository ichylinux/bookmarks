---
phase: quick
plan: 260501-nyc
type: execute
wave: 1
depends_on: []
files_modified:
  - app/assets/stylesheets/themes/modern.css.scss
autonomous: true
requirements:
  - NYC-01
must_haves:
  truths:
    - "Gadget title bars render with modern-blue background (#3b82f6) when theme is 'modern'"
    - "Gadget title bars render with white text when theme is 'modern'"
    - "Classic theme gadget title bars are unchanged (rgba(0,0,0,.20))"
  artifacts:
    - path: "app/assets/stylesheets/themes/modern.css.scss"
      provides: "Gadget title bar override for modern theme"
      contains: ".modern .gadget div.title"
  key_links:
    - from: "app/assets/stylesheets/welcome.css.scss"
      to: "app/assets/stylesheets/themes/modern.css.scss"
      via: "CSS specificity override"
      pattern: "\\.modern .gadget div\\.title"
---

<objective>
Fix gadget title bar colors when using the 'modern' theme.

Problem: `welcome.css.scss` sets `div.gadgets div.gadget div div.title { background: rgba(0,0,0,.20) }` globally. `modern.css.scss` has no override for this selector, so gadget title bars show the same semi-transparent dark grey in both classic and modern themes.

Fix: Add `.modern .gadget div.title` rule in `modern.css.scss` using the modern CSS variables (`--modern-color-primary` for background, white for text).

Output: Gadget title bars in modern theme use the primary blue (#3b82f6) background with white text.
</objective>

<execution_context>
@~/.copilot/get-shit-done/workflows/execute-plan.md
@~/.copilot/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<!-- Gadget title bar HTML structure (from _bookmark_gadget.html.erb, _todo_gadget.html.erb):
  <div id="..." class="gadget">
    <div>
      <div class="title">TITLE TEXT</div>
      ...
    </div>
  </div>
  Selector path: div.gadgets > div.gadget > div > div.title
-->

<!-- Current global rule in welcome.css.scss (lines 11-20):
  div.gadgets {
    div.gadget {
      div {
        div.title {
          margin: 0;
          padding: 4px;
          font-weight: bold;
          background: rgba(0, 0, 0, .20);
        }
      }
    }
  }
-->

<!-- modern.css.scss CSS variables (lines 2-9):
  --modern-color-primary: #3b82f6;
  --modern-bg:            #ffffff;
  --modern-text:          #1a1a1a;
  --modern-header-bg:     #1e40af;
  --modern-header-fg:     #ffffff;
  --modern-border:        #d1d5db;
  --modern-surface-alt:   #f3f4f6;
  --modern-danger:        #dc2626;
-->
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add modern gadget title bar CSS override</name>
  <files>app/assets/stylesheets/themes/modern.css.scss</files>
  <action>
Append the following CSS block to the end of `app/assets/stylesheets/themes/modern.css.scss`:

```scss
// STYLE-05: Gadget title bars — override welcome.css.scss rgba(0,0,0,.20) with modern primary color
.modern .gadget div.title {
  background: var(--modern-color-primary);
  color: #ffffff;
}
```

Place it after the last existing rule (`.modern select:focus-visible { ... }` block, line 319).

Do NOT modify `welcome.css.scss` — the global rule stays as-is for classic theme. The modern override wins via CSS specificity (`.modern .gadget div.title` vs the nested `div.gadgets div.gadget div div.title` in welcome.css.scss — both have similar specificity but the modern rule loads after in the cascade since `modern.css.scss` is included separately, and the `.modern` class scope ensures it only applies when modern theme is active).

Verify specificity is sufficient: if the welcome.css.scss rule beats it in practice (same specificity, same or later load order), increase specificity to `.modern div.gadgets .gadget div.title` instead.
  </action>
  <verify>
    <automated>bundle exec rails assets:precompile 2>&1 | tail -5; echo "exit: $?"</automated>
  </verify>
  <done>
- `modern.css.scss` contains `.modern .gadget div.title` with `background: var(--modern-color-primary)` and `color: #ffffff`
- `bundle exec rails assets:precompile` completes with no SCSS errors
- Classic theme gadget title bars remain unchanged (no modification to `welcome.css.scss`)
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>CSS override so modern theme gadget title bars use primary blue (#3b82f6) background with white text instead of the classic semi-transparent dark grey.</what-built>
  <how-to-verify>
1. Start the server: `bin/rails server`
2. Log in and navigate to the home page (/)
3. In Preferences, set Theme to **Modern** and save
4. Return to home page — confirm each gadget title bar shows **blue background (#3b82f6) with white text**
5. In Preferences, set Theme to **Classic** and save
6. Return to home page — confirm gadget title bars show **semi-transparent dark grey** (unchanged)
  </how-to-verify>
  <resume-signal>Type "approved" if both themes look correct, or describe any visual issues</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| CSS cascade | Theme-scoped selectors must not leak across themes |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-NYC-01 | Tampering | CSS selector specificity | accept | Specificity of `.modern .gadget div.title` is equivalent to the welcome.css.scss rule; cascade order (modern.css loaded after welcome.css) ensures override wins. If needed, increase to `.modern div.gadgets .gadget div.title`. |
</threat_model>

<verification>
1. `bundle exec rails assets:precompile` exits 0 — no SCSS compile errors
2. Human visual check: modern theme shows blue gadget title bars, classic theme unchanged
</verification>

<success_criteria>
- Modern theme: gadget title bars have `background: #3b82f6` (var(--modern-color-primary)) with white text
- Classic theme: gadget title bars remain `rgba(0,0,0,.20)` dark grey — no regression
- SCSS compiles without errors
</success_criteria>

<output>
After completion, create `.planning/quick/260501-nyc-modern-theme-gadget-title-bar-color-fix/260501-nyc-SUMMARY.md`
</output>
