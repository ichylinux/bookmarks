require 'test_helper'

# Gadget header service icon horizontal inset matches the gadget list's first column
# (entry-like button), derived from common.css ol/li spacing.
class GadgetTitleIconCssContractTest < ActiveSupport::TestCase
  def setup
    @welcome = Rails.root.join('app/assets/stylesheets/welcome.css.scss').read
    @common = Rails.root.join('app/assets/stylesheets/common.css.scss').read
  end

  test 'welcome.css.scss pads gadget headers to match common.css ol li list inset' do
    assert_match(
      /\$gadget-list-inset-inline-start:\s*calc\(2px \+ 0\.5em\)/,
      @welcome,
      'welcome.css.scss must define $gadget-list-inset-inline-start as calc(2px + 0.5em) ' \
      'to mirror common.css ol padding and li margin.'
    )

    assert_match(
      /div\.title\.title--gadget-with-icon[\s\S]*?padding:\s*4px 4px 4px \$gadget-list-inset-inline-start/,
      @welcome,
      'welcome.css.scss must apply $gadget-list-inset-inline-start as the left padding ' \
      'on .title--gadget-with-icon.'
    )

    assert_match(/ol\s*\{[\s\S]*?padding:\s*2px/, @common)
    assert_match(/ol\s*\{[\s\S]*?li\s*\{[\s\S]*?margin:\s*0\.5em/, @common)
  end
end