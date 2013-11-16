# coding: UTF-8

もし /^小さな画面サイズではパディングをなくす$/ do
  git_diff 'app/assets/stylesheets/welcome.css.scss',
      :and => '541cc3e3c9f6ba384e67f148bb7d866645d165df',
      :to => 37
end
  