def resize_browser_window(width, height)
  return unless Capybara.current_session.driver.respond_to?(:browser)

  browser = Capybara.current_session.driver.browser
  return unless browser.respond_to?(:manage)

  browser.manage.window.resize_to(width, height)
rescue StandardError
  nil
end

Before('@mobile_portal') do
  @mobile_portal_scenario = true
end

def ensure_mobile_viewport!
  return unless @mobile_portal_scenario

  resize_browser_window(390, 844)
end

# Reset viewport after mobile portal scenarios (avoids leaking window size across Cucumber scenarios).
After('@mobile_portal') do
  @mobile_portal_scenario = false
  resize_browser_window(1280, 800)
end
