if ENV["COVERAGE"]
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start 'rails' 
end

if ENV['JENKINS']
  require 'minitest/reporters'
  MiniTest::Reporters.use! [
    MiniTest::Reporters::DefaultReporter.new,
    MiniTest::Reporters::JUnitReporter.new
  ]
end

ENV['RAILS_ENV'] ||= 'test'
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
  include Devise::TestHelpers
end
