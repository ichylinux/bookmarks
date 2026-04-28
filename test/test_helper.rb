require 'daddy/test_help'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'action_dispatch/system_testing/browser'

# Stale chromedriver on PATH (e.g. /usr/local/bin for Chrome 145) breaks system tests when
# Chrome is newer; Selenium Manager then fetches a matching driver if that binary is hidden.
if ENV['PATH']
  paths = ENV['PATH'].split(File::PATH_SEPARATOR).reject do |dir|
    next false unless dir == '/usr/local/bin'

    File.executable?(File.join(dir, 'chromedriver'))
  end
  ENV['PATH'] = paths.join(File::PATH_SEPARATOR)
end

module ActionDispatch
  module SystemTesting
    module SeleniumChromeDriverPathReset
      private

      def resolve_driver_path(namespace)
        namespace::Service.driver_path = nil
        super
      end
    end

    Browser.prepend(SeleniumChromeDriverPathReset)
  end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |f|
    self.class_eval File.read(f)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
