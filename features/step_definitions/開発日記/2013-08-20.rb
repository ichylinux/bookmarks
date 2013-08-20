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
  git_diff 'db/schema.rb', :as => 'auto'
end

もし /^application_controllerを修正$/ do
  git_diff 'app/controllers/application_controller.rb'
end

もし /^レイアウトにログアウトのリンクを用意$/ do
  show 'app/views/common/_menu.html.erb', :as => 'new'
  git_diff 'app/views/layouts/application.html.erb'
end

もし /^rails s$/ do
end

もし /^http:\/\/localhost:3000 にアクセスするとログイン画面が表示される$/ do
  assert_visit '/users/sign_in'
end
