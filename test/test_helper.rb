require 'daddy/test_help'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

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
