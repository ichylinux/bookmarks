# coding: UTF-8

もし /^Gemfileを編集$/ do
  git_diff 'Gemfile', :from => 23, :to => 26
end

もし /^sudo bundle update$/ do
  git_diff 'Gemfile.lock', :as => 'auto', :from => 206
end

もし /^インポート用のアクションをルーティングに追加$/ do
  git_diff 'config/routes.rb', :from => 51, :to => 57
end

もし /^ビューで使うフォームモデル$/ do
  show 'app/models/bookmark_import_form.rb', :as => 'new'
end

もし /^インポート画面$/ do
  show 'app/views/bookmarks/new_import.html.erb', :as => 'new'
end

もし /^確認画面$/ do
  show 'app/views/bookmarks/confirm_import.html.erb', :as => 'new'
end

もし /^コントローラにアクションを追加$/ do
  git_diff 'app/controllers/bookmarks_controller.rb', :from => 53, :to => 75
end

もし /^ログインユーザのブックマークだけに絞り込み$/ do
  git_diff 'app/controllers/welcome_controller.rb'
end
