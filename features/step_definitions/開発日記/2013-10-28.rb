# coding: UTF-8

もし /^メールアドレスをクリックしてメニューが開くように修正$/ do
  git_diff 'app/views/common/_menu.html.erb'
end
