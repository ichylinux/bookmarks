# coding: UTF-8

もし /^モデルを作成$/ do |string|
  diff 'db/migrate/20131112032742_create_calendars.rb',
      File.join(File.dirname(__FILE__), '20131112032742_create_calendars.rb.txt'), :as => ['auto', 'edit']
  git_diff 'config/locales/ja.yml', :to => 10
  git_diff 'app/models/calendar.rb',
      :between => '37e3b964227d18ed0ade147b96e7efe0a952f12b',
      :and => '15d2edc3afd7a9508a6a4b6248507234e6e893ea'
end

もし /^マイグレーション$/ do |string|
  git_diff 'db/schema.rb', :as => 'auto', :from => 25, :to => 31
end

もし /^コントローラを作成$/ do |string|
  diff 'app/controllers/calendars_controller.rb',
      File.join(File.dirname(__FILE__), 'calendars_controller.rb.txt'), :as => ['auto', 'edit']
end

もし /^ビューを作成$/ do |string|
  Dir["#{Rails.root}/app/views/calendars/*.html.erb"].sort.each do |view|
    diff view, File.join(File.dirname(__FILE__), File.basename(view)), :as => ['auto', 'edit']
  end
end

もし /^ルーティングを追加$/ do
  git_diff 'config/routes.rb', :from => 4, :to => 20
end

もし /^メニューを追加$/ do
  git_diff 'app/views/common/_menu.html.erb'
end

もし /^モデルを修正$/ do
  git_diff 'app/models/calendar.rb',
      :between => '24e278b94687bc60832c043bf83903b6b5c27a85',
      :and => '37e3b964227d18ed0ade147b96e7efe0a952f12b'
end
