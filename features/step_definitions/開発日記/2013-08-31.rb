# coding: UTF-8

もし /^トップページにでかでかとタイトル表示しているけどもう不要かな$/ do
  git_diff 'app/views/welcome/index.html.erb'
end
