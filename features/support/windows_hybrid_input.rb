# Dedicated Capybara session that emulates a Windows touchscreen laptop with a
# mouse attached: the touchscreen is the *primary* pointer (coarse, no hover)
# while a fine hovering pointer (the mouse) is also available. Standard headless
# Chrome reports NO pointer devices at all (hover:none/pointer:none/any-hover:none/
# any-pointer:none across the board) since there is no simulated input hardware,
# so it cannot distinguish the primary-only media conditions (the bug) from the
# any-input media conditions (the fix) — this is why WINCHR-01 needs its own
# browser process launched with Blink's primary/available pointer overrides.
#
# PointerType bitmask: none=1, coarse=2, fine=4. HoverType bitmask: none=1, hover=2.
# primaryPointerType=2 (coarse) + primaryHoverType=1 (none) => primary is the
# touchscreen. availablePointerTypes=6 (coarse|fine) + availableHoverTypes=3
# (none|hover) => a fine, hovering mouse is also attached.
Capybara.register_driver :headless_chrome_windows_hybrid_input do |app|
  options = Closer::Drivers::Chrome.options(headless: true)
  options.add_argument(
    'blink-settings=primaryPointerType=2,primaryHoverType=1,' \
    'availablePointerTypes=6,availableHoverTypes=3'
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Opens a throwaway browser session emulating a Windows touchscreen-laptop-with-
# mouse, signs in the current user fresh (sessions do not share cookies), yields
# with that session active as Capybara.current_session, then always closes it.
def with_windows_hybrid_input_session
  session = Capybara::Session.new(:headless_chrome_windows_hybrid_input, Capybara.app)

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

    assert has_no_selector?('form[action*="sign_in"]'), 'サインイン後もサインインフォームが表示されています(hybrid session)'

    yield
  end
ensure
  session&.driver&.quit
end
