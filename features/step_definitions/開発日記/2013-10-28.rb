# coding: UTF-8

もし /^メールアドレスをクリックしてメニューが開くように修正$/ do
  git_diff 'app/views/common/_menu.html.erb'
end

もし /^認証情報を保存するカラムを追加$/ do
  git_diff 'db/schema.rb', :as => 'auto'
  git_diff 'config/locales/ja.yml'
end

もし /^フォームに入力項目を追加$/ do
  git_diff 'app/views/feeds/_form.html.erb'
end

もし /^フィードを取得時にBasic認証を設定$/ do
  git_diff 'app/models/feed.rb'
end
