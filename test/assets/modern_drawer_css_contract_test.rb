# frozen_string_literal: true

require 'test_helper'

class ModernDrawerCssContractTest < ActiveSupport::TestCase
  def setup
    @scss = Rails.root.join('app/assets/stylesheets/themes/modern.css.scss').read
  end

  test 'modern scss includes drawer motion contracts' do
    # libsass cannot compile min(88vw, 320px); width + max-width expresses the same cap
    assert_includes @scss, 'width: 88vw'
    assert_includes @scss, 'max-width: 320px'
    assert_includes @scss, 'var(--modern-bg)'
    assert_includes @scss, 'rgba(0, 0, 0, 0.5)'
    assert_includes @scss, 'translateX(100%)'
    assert_includes @scss, 'translateX(0)'
    assert_includes @scss, '250ms'
    assert_includes @scss, 'ease-out'
    assert_includes @scss, 'prefers-reduced-motion'
    assert_includes @scss, 'hamburger-btn'
    assert_includes @scss, 'drawer-overlay'
  end
end
