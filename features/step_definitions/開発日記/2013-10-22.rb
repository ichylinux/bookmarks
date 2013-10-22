# coding: UTF-8

もし /^タイトルを取得するアクションを追加$/ do
  git_diff 'config/routes.rb', :from => 59, :to => 63
  git_diff 'app/controllers/feeds_controller.rb'
end

もし /^Ajaxで呼び出す$/ do
  show 'app/assets/javascripts/feeds.js', :as => 'new'
  git_diff 'app/views/feeds/_form.html.erb'
end
