# coding: UTF-8

もし /^ブックマークとタスクをガジェットとして扱えるようにラッパークラスを用意$/ do
  show 'app/models/bookmark_gadget.rb', :as => 'new'
  show 'app/models/todo_gadget.rb', :as => 'new'
end

もし /^ガジェットの種類別にビューファイルを分離$/ do
  show 'app/views/welcome/_bookmark_gadget.html.erb', :as => 'new'
  show 'app/views/welcome/_feed.html.erb', :as => 'new'
  show 'app/views/welcome/_todo_gadget.html.erb', :as => 'new'
end

もし /^ガジェットを３列に配置しソート用のJavaScriptを定義$/ do
  git_diff 'app/assets/stylesheets/welcome.css.scss', :from => 3, :to => 22
  git_diff 'app/controllers/welcome_controller.rb'
  git_diff 'app/views/welcome/index.html.erb'
end
