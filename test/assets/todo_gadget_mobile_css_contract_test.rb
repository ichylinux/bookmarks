require 'test_helper'

# Mobile todo gadget: "追加" link is hidden by default and revealed when the user
# taps the header title/icon (todos.js toggles .title--gadget-actions-visible).
class TodoGadgetMobileCssContractTest < ActiveSupport::TestCase
  # Read once for the whole class — `setup` runs per test method, and these
  # sources are immutable for the duration of the run.
  WELCOME_CSS = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read.freeze
  TODOS_JS = Rails.root.join('app/assets/javascripts/todos.js').read.freeze

  def setup
    @welcome = WELCOME_CSS
    @todos_js = TODOS_JS
  end

  test 'welcome.css.scss hides todo-gadget-new-link on mobile by default' do
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.gadget\.todo\s+\.todo-gadget-new-link[\s\S]*?pointer-events\s*:\s*none/,
      @welcome,
      'welcome.css.scss must set pointer-events: none on .gadget.todo .todo-gadget-new-link inside @media (max-width: 767px).'
    )
  end

  test 'welcome.css.scss reveals todo-gadget-new-link when header has actions-visible class' do
    assert_match(
      /\.title--gadget-actions-visible[\s\S]*?\.todo-gadget-new-link[\s\S]*?opacity\s*:\s*1/,
      @welcome,
      'welcome.css.scss must set opacity: 1 on .todo-gadget-new-link when .title--gadget-actions-visible is present.'
    )

    assert_match(
      /\.title--gadget-actions-visible[\s\S]*?\.todo-gadget-new-link[\s\S]*?pointer-events\s*:\s*auto/,
      @welcome,
      'welcome.css.scss must set pointer-events: auto on .todo-gadget-new-link when .title--gadget-actions-visible is present.'
    )
  end

  # WINCHR-01 (supersedes the former "fine pointer hover only" contract) — rationale:
  # test/assets/css_architecture_contract_test.rb, which also enforces the project-wide
  # ban on hover/pointer gates. This test pins the positive half for this selector.
  test 'welcome.css.scss gates title:hover new-link reveal on viewport width' do
    assert_match(
      /@media\s*\(\s*min-width\s*:\s*\$portal-mobile-breakpoint\s*\)\s*\{[\s\S]*?div\.title:hover\s+\.todo-gadget-new-link/,
      @welcome,
      'welcome.css.scss must wrap div.title:hover .todo-gadget-new-link in ' \
      '@media (min-width: $portal-mobile-breakpoint).'
    )
  end

  test 'todos.js binds header tap-to-reveal on title--gadget-with-icon within gadget root' do
    assert_match(
      /\.on\(\s*['\"]click['\"],\s*['\"]\.title--gadget-with-icon['\"]/,
      @todos_js,
      'todos.js must delegate click on .title--gadget-with-icon within the gadget root (#todo). ' \
      'Do not use .gadget.todo .title--gadget-with-icon — jQuery treats the left side as a descendant of the root, so it never matches.'
    )
  end

  test 'todos.js complete_todos success callback removes title--gadget-actions-visible from the gadget header' do
    assert_match(
      /complete_todos[\s\S]*?removeClass\(\s*['\"]title--gadget-actions-visible['\"]\s*\)/,
      @todos_js,
      'todos.js complete_todos success callback must removeClass("title--gadget-actions-visible") from the gadget header, ' \
      'so the "追加" link stays hidden on mobile immediately after bulk-completing tasks.'
    )
  end

  test 'welcome.css.scss hides new-link on mobile independent of :hover (QUICK-MOB-ADDBTN-02)' do
    assert_match(
      /@media\s*\(\s*max-width\s*:\s*767px\s*\)[\s\S]*?\.gadget\.todo\s+\.title--gadget-with-icon\s+\.todo-gadget-new-link[\s\S]*?opacity\s*:\s*0/,
      @welcome,
      'On mobile, "追加" visibility must be controlled solely by the tap-reveal class, not by :hover. ' \
      'welcome.css.scss must set opacity: 0 on .gadget.todo .title--gadget-with-icon .todo-gadget-new-link ' \
      'inside @media (max-width: 767px) with specificity (0,4,0) to override the :hover rule.'
    )
  end
end
