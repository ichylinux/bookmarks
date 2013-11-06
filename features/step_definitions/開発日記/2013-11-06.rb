# coding: UTF-8

もし /^参照用のアクションを実装$/ do
  git_diff 'app/controllers/feeds_controller.rb', :from => 9, :to => 14
end

もし /^参照ビューを作成$/ do
  show 'app/views/feeds/show.html.erb', :as => 'new'
end

もし /^トップページを修正$/ do
  git_diff 'app/views/welcome/index.html.erb', :from => 31
end
