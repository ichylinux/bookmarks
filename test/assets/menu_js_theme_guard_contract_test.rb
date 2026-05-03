# frozen_string_literal: true

require 'test_helper'

class MenuJsThemeGuardContractTest < ActiveSupport::TestCase
  def setup
    @menu_js = Rails.root.join('app/assets/javascripts/menu.js').read
  end

  test 'menu.js drawer guard applies to modern and classic only' do
    assert_match(
      /if\s*\(!\$\('body'\)\.hasClass\('modern'\)\s*&&\s*!\$\('body'\)\.hasClass\('classic'\)\)\s*return;/,
      @menu_js
    )
  end
end
