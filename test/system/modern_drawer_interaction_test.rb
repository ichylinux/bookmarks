# frozen_string_literal: true

require 'application_system_test_case'

class ModernDrawerInteractionTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]

  setup do
    user.preference.update!(theme: 'modern')
    sign_in user
  end

  test 'drawer starts closed; hamburger toggles drawer-open twice' do
    visit root_path
    refute page.has_css?('body.drawer-open'), 'drawer should start closed'

    find('button.hamburger-btn', match: :first).click
    assert_selector 'body.drawer-open'

    find('button.hamburger-btn', match: :first).click
    refute page.has_css?('body.drawer-open')
  end

  test 'drawer closes when overlay is clicked' do
    visit root_path
    find('button.hamburger-btn', match: :first).click
    assert_selector 'body.drawer-open'

    # Drawer panel sits above the overlay at many hit points; use a direct overlay click.
    page.execute_script('document.querySelector(".drawer-overlay").click()')
    refute page.has_css?('body.drawer-open')
  end

  test 'drawer closes on Escape' do
    visit root_path
    find('button.hamburger-btn', match: :first).click
    assert_selector 'body.drawer-open'

    send_keys :escape
    refute page.has_css?('body.drawer-open')
  end

  # Close drawer before navigation so the next page load reflects a clean body class.
  test 'drawer closes when following a drawer nav link (before navigation)' do
    visit root_path
    find('button.hamburger-btn', match: :first).click
    assert_selector 'body.drawer-open'

    within '.drawer' do
      click_link '設定'
    end
    assert_current_path preferences_path
    refute page.has_css?('body.drawer-open')
  end

  test 'modern theme shows non-link email beside hamburger' do
    visit root_path
    assert_selector '#header .head-box .modern-user-email', text: user.display_name
    assert_no_selector '#header .head-box .modern-user-email a'
  end
end
