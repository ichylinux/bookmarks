require 'test_helper'

# MOB-01: On touch-only devices, the .todo-gadget-new-link "追加" link must be visible
# and tappable. This @media (hover: none) block in welcome.css.scss overrides the default
# opacity:0 / pointer-events:none that hides the link on desktop.
#
# These are regression-guard contract tests. A violation means the mobile override block
# was removed from welcome.css.scss.
class TodoGadgetMobileCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
  end

  test 'welcome.css.scss contains hover-none media block for todo-gadget-new-link' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link/,
      @welcome,
      'welcome.css.scss must contain @media (hover: none) { .todo-gadget-new-link { ... } }. MOB-01 override is missing.'
    )
  end

  test 'welcome.css.scss todo-gadget-new-link has opacity 1 inside hover-none block' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link[\s\S]*?opacity\s*:\s*1/,
      @welcome,
      'welcome.css.scss must set opacity: 1 on .todo-gadget-new-link inside @media (hover: none). MOB-01 tap-visibility rule is missing.'
    )
  end

  test 'welcome.css.scss todo-gadget-new-link has pointer-events auto inside hover-none block' do
    assert_match(
      /@media\s*\(\s*hover\s*:\s*none\s*\)[\s\S]*?\.todo-gadget-new-link[\s\S]*?pointer-events\s*:\s*auto/,
      @welcome,
      'welcome.css.scss must set pointer-events: auto on .todo-gadget-new-link inside @media (hover: none). MOB-01 tap-interactivity rule is missing.'
    )
  end
end
