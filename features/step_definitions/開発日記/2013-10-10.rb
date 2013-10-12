# coding: UTF-8

もし /^RSSフィード用のモデルを作成$/ do |string|
  show 'app/models/feed.rb', :as => ['auto', 'edit']
  git_diff 'config/locales/ja.yml'
end

もし /^マイグレーションファイルを編集$/ do
  show 'db/migrate/20131010032138_create_feeds.rb', :as => ['auto', 'edit']
end

もし /^マイグレーション実行$/ do |string|
  git_diff 'db/schema.rb', :as => 'auto', :from => 14
end

もし /^RSSのURLを登録するマスタ画面を作成$/ do |string|
  show 'app/controllers/feeds_controller.rb', :as => ['auto', 'edit']
  show 'app/views/feeds/index.html.erb', :as => 'new'
  show 'app/views/feeds/new.html.erb', :as => 'new'
  show 'app/views/feeds/_form.html.erb', :as => 'new'
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :from => 51, :to => 63
end

もし /^トップページにRSSを表示$/ do
  git_diff 'app/controllers/welcome_controller.rb'
  git_diff 'app/views/welcome/index.html.erb'
  git_diff 'app/assets/stylesheets/welcome.css.scss'
end
