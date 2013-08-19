# coding: UTF-8

前提 /^rails new bookmarks -d mysql --skip-bundle$/ do
  `rm -Rf /tmp/bookmarks`
  `cd /tmp && rails new bookmarks -d mysql --skip-bundle`
  puts "<pre>#{`cd /tmp/bookmarks && tree .`}</pre>"
end

前提 /^Gemfileを編集$/ do
  diff 'Gemfile', '/tmp/bookmarks/Gemfile', :as => 'edit'
end

前提 /^sudo bundle install$/ do
  `cd /tmp/bookmarks && sudo bundle install`
  diff 'Gemfile.lock', '/tmp/bookmarks/Gemfile.lock', :as => 'auto'
end

前提 /^rake dad:db:config$/ do
  diff 'config/database.yml', '/tmp/bookmarks/config/database.yml', :as => 'auto'
end

前提 /^rake dad:db:create$/ do
end

前提 /^rake db:migrate$/ do
  show 'db/schema.rb', :as => 'auto'
end

前提 /^rails s$/ do
end

前提 /^http:\/\/localhost:3000 にアクセス$/ do
  assert_visit '/'
end
