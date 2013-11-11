# coding: UTF-8

もし /^横幅によって列数を調整$/ do
  git_diff 'app/views/layouts/application.html.erb'
  git_diff 'app/assets/stylesheets/welcome.css.scss'
end
