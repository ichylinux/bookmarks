# frozen_string_literal: true

require 'test_helper'

class FontSizeThemeReadabilityContractTest < ActiveSupport::TestCase
  def setup
    @common = Rails.root.join('app/assets/stylesheets/common.css.scss').read
    @modern = Rails.root.join('app/assets/stylesheets/themes/modern.css.scss').read
    @classic = Rails.root.join('app/assets/stylesheets/themes/classic.css.scss').read
    @simple = Rails.root.join('app/assets/stylesheets/themes/simple.css.scss').read
  end

  test 'common scss defines device-aware medium baseline and relative scale classes' do
    assert_includes @common, '--font-size-medium-baseline: 14px'
    assert_includes @common, '--font-size-medium-baseline: 16px'
    assert_includes @common, '--font-size-scale: 0.875'
    assert_includes @common, '--font-size-scale: 1.125'
    assert_includes @common, 'calc(var(--font-size-medium-baseline) * var(--font-size-scale))'
  end

  test 'modern and classic header text follows body scale with rem values' do
    assert_match(/\.drawer nav a[\s\S]*font-size:\s*1rem/, @modern)
    assert_match(/\.head-user-email[\s\S]*font-size:\s*1rem/, @modern)
    assert_match(/\.drawer nav a[\s\S]*font-size:\s*1rem/, @classic)
    assert_match(/\.head-user-email[\s\S]*font-size:\s*1rem/, @classic)
  end

  test 'simple note surfaces use rem values for readability scaling' do
    assert_match(/#notes-tab-panel[\s\S]*font-size:\s*0\.875rem/, @simple)
    assert_match(/\.note-body[\s\S]*font-size:\s*0\.875rem/, @simple)
    assert_match(/\.note-timestamp[\s\S]*font-size:\s*0\.8125rem/, @simple)
  end
end
