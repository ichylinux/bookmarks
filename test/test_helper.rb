require 'daddy/test_help'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each do |f|
    self.class_eval File.read(f)
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
