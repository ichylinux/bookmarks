# coding: UTF-8

もし /^ユーザの設定を維持するモデルを作成$/ do |string|
  show 'db/migrate/20140120031539_create_preferences.rb',
      :as => 'auto',
      :commit => 'fb2153e5779784035a53c8461983372d550a662e'
end

もし /^マイグレーションファイルを編集$/ do
  git_diff 'db/migrate/20140120031539_create_preferences.rb',
      :between => '1a0e3d64d1a9d2f11b3c50311ab9f406474d7a0f',
      :and => 'fb2153e5779784035a53c8461983372d550a662e'
end

もし /^マイグレーション実行$/ do |string|
  git_diff 'db/schema.rb',
    :as => 'auto',
    :between => 'e3056a8f08d0720e8a99f757b4c5044488a7b3ed',
    :and => '728c1a6b3229ab74841f3163bd3dd44b45ad15b2',
    :from => 56, 
    :to => 62
end

もし /^コントローラを作成$/ do
  show 'app/controllers/preferences_controller.rb', :as => 'new'
end

もし /^ビューを作成$/ do
  show 'app/views/preferences/index.html.erb', :as => 'new'
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :from => 24, :to => 24
end
