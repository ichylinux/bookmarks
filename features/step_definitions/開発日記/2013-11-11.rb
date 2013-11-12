# coding: UTF-8

もし /^横幅によって列数を調整$/ do
  git_diff 'app/views/layouts/application.html.erb'
  git_diff 'app/assets/stylesheets/common.css.scss', :from => 20, :to => 35
  git_diff 'app/assets/stylesheets/welcome.css.scss', :from => 24, :to => 35
end
