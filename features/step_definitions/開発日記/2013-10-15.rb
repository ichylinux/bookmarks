# coding: UTF-8

もし /^モデルを作成$/ do |string|
  show 'app/models/todo.rb', :as => ['auto', 'edit']
end

もし /^マイグレーションファイルを編集$/ do
  show 'db/migrate/20131015031309_create_todos.rb', :as => ['auto', 'edit']
end

もし /^マイグレーション実行$/ do |string|
  git_diff 'db/schema.rb', :as => 'auto'
end

もし /^マスタ管理画面を作成$/ do
  show 'app/controllers/todos_controller.rb', :as => 'new'
  show 'app/models/todo_import_form.rb', :as => 'new'
  git_diff 'app/views/common/_menu.html.erb'
  show 'app/views/todos/index.html.erb', :as => 'new'
  show 'app/views/todos/new_import.html.erb', :as => 'new'
  show 'app/views/todos/confirm_import.html.erb', :as => 'new'
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :from => 61, :to => 67
end

もし /^トップページにタスクを表示$/ do
  git_diff 'app/controllers/welcome_controller.rb'
  git_diff 'app/views/welcome/index.html.erb'
end
