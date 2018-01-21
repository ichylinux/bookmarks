source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'

gem 'coffee-rails', '~> 4.2'
gem 'daddy'
gem 'devise'
gem 'devise-i18n'
gem 'faraday'
gem 'feedjira'
gem 'i18n-js'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'nokogiri'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'puma', '~> 3.7'
gem 'rails-i18n'
gem 'redis', '~> 3.0'
gem 'redis-namespace'
gem 'sass-rails', '~> 5.0'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'turbolinks', '~> 5'
gem 'twitter'
gem 'two_factor_authentication'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara'
  gem 'selenium-webdriver'
end

group :development do
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-sidekiq'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rails-erd'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'closer'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner', :require => false
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end
