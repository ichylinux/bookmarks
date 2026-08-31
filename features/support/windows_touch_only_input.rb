# Dedicated Capybara session reproducing WINCHR-01: a Windows touchscreen laptop
# where Chrome reports NO hovering pointer at all, even though the user is driving
# a real mouse. Values confirmed on the affected machine (Chrome 151, Windows 10,
# maxTouchPoints 10, innerWidth 1289):
#
#   (hover:hover)      false   (hover:none)       true
#   (pointer:fine)     false   (pointer:coarse)   true
#   (any-hover:hover)  false   (any-hover:none)   true
#   (any-pointer:fine) false   (any-pointer:coarse) true
#
# Both the primary-only features AND the any-input features come back
# none/coarse, which is why gating the "追加" reveal on either family made the
# button unreachable. The reveal must therefore be gated on viewport width alone.
#
# PointerType bitmask: none=1, coarse=2, fine=4. HoverType bitmask: none=1, hover=2.
# primary + available are all coarse/no-hover => the mouse is invisible to Chrome.
Capybara.register_driver :headless_chrome_windows_touch_only_input do |app|
  options = Closer::Drivers::Chrome.options(headless: true)
  options.add_argument(
    'blink-settings=primaryPointerType=2,primaryHoverType=1,' \
    'availablePointerTypes=2,availableHoverTypes=1'
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Opens a throwaway browser session emulating the affected Windows machine, signs
# in the current user fresh (sessions do not share cookies), yields with that
# session active as Capybara.current_session, then always closes it.
#
# Selenium still drives a synthetic mouse, so `.hover` fires :hover normally —
# what the emulation changes is only what the *media features* report, which is
# exactly the axis WINCHR-01 turns on.
def with_windows_touch_only_session
  session = Capybara::Session.new(:headless_chrome_windows_touch_only_input, Capybara.app)

  Capybara.using_session(session) do
    resize_browser_window(1280, 800)

    visit '/users/sign_in'
    fill_in 'user[email]', with: current_user.email
    fill_in 'user[password]', with: 'testtest'
    find('form.auth-form').find('input[type="submit"], button[type="submit"]').click

    if current_user.two_factor_enabled?
      totp = ROTP::TOTP.new(current_user.otp_secret)
      fill_in 'user[otp_attempt]', with: totp.now
      find('input[type="submit"], button[type="submit"]', match: :first).click
    end

    assert has_no_selector?('form[action*="sign_in"]'), 'サインイン後もサインインフォームが表示されています(touch-only session)'

    yield
  end
ensure
  session&.driver&.quit
end
