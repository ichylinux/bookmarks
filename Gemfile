source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.4.0'
gem 'rails', '~> 7.2.0'

gem 'bootsnap', require: false
gem 'daddy'
gem 'devise'
gem 'devise-i18n'
gem 'faraday'
gem 'faraday_middleware'
gem 'feedjira'
gem 'httparty'
gem 'holiday_jp'
gem 'i18n-js'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'nokogiri', force_ruby_platform: true
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-twitter'
gem 'puma'
gem 'rails-i18n', '~> 7.0'
gem 'sass-rails', '>= 6'
gem 'twitter'
gem 'uglifier', '>= 1.3.0'

group :itamae do
  gem 'mysql2', '>= 0.4.4', '< 0.6.0'
end

group :development, :test do
  gem 'byebug'
  gem 'cucumber'
end

group :development do
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara'
  gem 'ci_reporter', require: false
  gem 'closer', require: false
  gem 'cucumber-rails', require: false
  gem 'database_cleaner', require: false
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end
