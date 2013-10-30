# coding: UTF-8

もし /^マイグレーション$/ do
  git_diff 'db/schema.rb', :as => 'auto', :from => 25, :to => 38
end

もし /^フォームの修正$/ do
  git_diff 'app/views/feeds/_form.html.erb', :from => 19, :to => 33
end

もし /^表示件数で絞り込み$/ do
  git_diff 'app/views/welcome/index.html.erb', :from => 31, :to => 43
end
