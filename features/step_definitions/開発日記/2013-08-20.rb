# coding: UTF-8

もし /^rails g controller welcome$/ do
  show 'app/controllers/welcome_controller.rb', :as => 'auto'
end

もし /^indexページを作成$/ do
  show 'app/views/welcome/index.html.erb', :as => 'new'
end

もし /^rails g devise user$/ do
  show 'app/models/user.rb', :as => 'auto'
  show 'db/migrate/20130819035607_devise_create_users.rb', :as => 'auto'
end

もし /^devise用の日本語ファイルを取得$/ do
  puts 'wget https://gist.github.com/kawamoto/4729292/raw/ec2b3e23be61b4b8f6903efedff359fd0a4b3223/devise.ja.yml -O config/locales/devise.ja.yml'
end

もし /^rake db:migrate$/ do
  show 'db/schema.rb'
end
