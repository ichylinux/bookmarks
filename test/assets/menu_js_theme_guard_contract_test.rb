# frozen_string_literal: true

require 'test_helper'

class MenuJsThemeGuardContractTest < ActiveSupport::TestCase
  def setup
    @menu_js = Rails.root.join('app/assets/javascripts/menu.js').read
  end

  test 'menu.js uses strict modern-only body guard' do
    assert_match(/if\s*\(!\$\('body'\)\.hasClass\('modern'\)\)\s*return;/, @menu_js)
    refute_match(/hasClass\('classic'\)/, @menu_js)
  end
end
