require 'test_helper'

# Mobile todo gadget: "追加" link is hidden by default and revealed when the user
# taps the header title/icon (todos.js toggles .title--gadget-actions-visible).
class TodoGadgetMobileCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @todos_js = Rails.root.join('app/assets/javascripts/todos.js').read
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

  test 'todos.js toggles title--gadget-actions-visible on mobile header tap' do
    assert_match(
      /title--gadget-actions-visible/,
      @todos_js,
      'todos.js must toggle .title--gadget-actions-visible on the todo gadget header for mobile tap-to-reveal.'
    )
  end
end
