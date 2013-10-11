source 'https://rubygems.org'

gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'compass-rails'
gem 'daddy'
gem 'devise'
gem 'feedzirra', '= 0.2.0.rc2', :path => File.join(File.dirname(__FILE__), 'vendor', 'feedzirra-0.2.0.rc2')
gem 'jquery-rails'
gem 'nokogiri'

group :development, :test do
  gem 'capybara-webkit'
  gem 'thin'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

group :development, :test do
  gem 'thin'
end

# Deploy with Capistrano
gem 'capistrano', '< 3.0.0'

# To use debugger
# gem 'debugger'
