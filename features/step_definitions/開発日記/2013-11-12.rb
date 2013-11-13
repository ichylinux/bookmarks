# coding: UTF-8

もし /^モデルを作成$/ do |string|
  diff 'db/migrate/20131112032742_create_calendars.rb',
      File.join(File.dirname(__FILE__), '20131112032742_create_calendars.rb.txt'), :as => ['auto', 'edit']
end

もし /^マイグレーション$/ do |string|
  git_diff 'db/schema.rb', :as => 'auto', :from => 25, :to => 31
end

もし /^コントローラを作成$/ do |string|
  diff 'app/controllers/calendars_controller.rb',
      File.join(File.dirname(__FILE__), 'calendars_controller.rb.txt'), :as => ['auto', 'edit']
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :from => 4, :to => 20
end
