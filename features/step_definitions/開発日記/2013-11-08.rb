# coding: UTF-8

もし /^レイアウトが変更されたタイミングでサーバーにPOST$/ do
  git_diff 'app/views/welcome/index.html.erb'
  git_diff 'app/controllers/welcome_controller.rb'
  show 'app/models/portal.rb', :as => 'new'
end
