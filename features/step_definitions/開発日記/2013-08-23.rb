# coding: UTF-8

もし /^モデルを作成$/ do
  puts '$ rails g model bookmark'
  show 'app/models/bookmark.rb', :as => ['auto', 'edit']
  show 'db/migrate/20130821035447_create_bookmarks.rb', :as => ['auto', 'edit']
end

もし /^マイグレーション$/ do
  puts '$ rake db:migrate'
  git_diff 'db/schema.rb', :as => 'auto', :from => 14, :to => 27
end

もし /^コントローラを作成$/ do
  puts '$ rails g controller bookmarks'
  show 'app/controllers/bookmarks_controller.rb', :as => ['auto', 'edit']
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :as => 'edit', :from => 44, :to => 56
end

もし /^モデルの属性を一括代入できるように設定を変更$/ do
  git_diff 'config/application.rb', :as => 'edit', :from => 50, :to => 55
end

もし /^ビューを作成$/ do
  show 'app/views/bookmarks/index.html.erb', :as => 'new'
  show 'app/views/bookmarks/_form.html.erb', :as => 'new'
  show 'app/views/bookmarks/new.html.erb', :as => 'new'
  show 'app/views/bookmarks/show.html.erb', :as => 'new'
  show 'app/views/bookmarks/edit.html.erb', :as => 'new'
end

もし /^ラベルを日本語化$/ do
  show 'config/locales/ja.yml', :as => 'new'
  git_diff 'config/application.rb', :as => 'edit', :from => 32, :to => 34
end

もし /^管理機能へのリンクを作成$/ do
  git_diff 'app/views/common/_menu.html.erb', :as => 'edit'
end
