# frozen_string_literal: true

require 'test_helper'

class ModernFullPageThemeContractTest < ActiveSupport::TestCase
  def setup
    @scss = Rails.root.join('app/assets/stylesheets/themes/modern.css.scss').read
  end

  # STYLE-01: Header bars
  test 'modern scss includes primary header bar override' do
    assert_includes @scss, '.modern #header .head-box'
    assert_includes @scss, 'var(--modern-header-bg)'
    assert_includes @scss, '--modern-header-fg'
  end

  test 'modern scss includes secondary nav strip override' do
    assert_includes @scss, '.modern .header'
    assert_includes @scss, 'var(--modern-border)'
  end

  test 'modern scss offsets main wrapper below primary header when menu strip omitted' do
    assert_includes @scss, '.modern .wrapper'
    assert_match(/padding-top:\s*24px/, @scss)
  end

  # STYLE-02: Body typography
  test 'modern scss includes 16px system font stack' do
    assert_includes @scss, 'font-size: 16px'
    assert_includes @scss, '-apple-system'
    assert_includes @scss, 'BlinkMacSystemFont'
    assert_match(/line-height:\s*1\.[5-9]/, @scss)
  end

  # STYLE-03: Tables
  test 'modern scss includes table styling' do
    assert_includes @scss, '.modern table'
    assert_match(/padding:\s*10px\s+12px/, @scss)
    assert_includes @scss, 'thead'
    assert_includes @scss, 'nth-child'
  end

  # STYLE-04: Action links
  test 'modern scss includes action link styles' do
    assert_includes @scss, '.modern .actions'
    assert_includes @scss, 'var(--modern-color-primary)'
    assert_includes @scss, 'focus-visible'
    assert_includes @scss, 'transition:'
  end

  # STYLE-04: Form controls
  test 'modern scss includes form control styles' do
    assert_includes @scss, 'input[type="'
    assert_includes @scss, 'var(--modern-bg)'
    assert_includes @scss, 'border-radius:'
  end

  # STYLE-05: Gadget title bars
  test 'modern scss keeps gadget title links white after visit' do
    assert_includes @scss, '.modern div.gadgets div.gadget div div.title a:visited'
    assert_match(/\.modern div\.gadgets div\.gadget div div\.title a:focus-visible[\s\S]*color:\s*#ffffff/, @scss)
  end

  # Token presence
  test 'modern scss declares Phase 9 tokens' do
    assert_includes @scss, '--modern-border'
    assert_includes @scss, '--modern-surface-alt'
    assert_includes @scss, '--modern-danger'
  end
end
