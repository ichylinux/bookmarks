# coding: UTF-8

もし /^トップページを表示後、当月のカレンダーをAjaxで取得$/ do
  git_diff 'app/views/welcome/_calendar.html.erb'
end

もし /^Ajax呼び出し用のアクションを追加$/ do
  git_diff 'config/routes.rb', :from => 12, :to => 16
  git_diff 'app/controllers/calendars_controller.rb', :from => 13, :to => 17
end

もし /^カレンダーの日付を指定できるように修正$/ do
  git_diff 'app/models/calendar.rb', :from => 23, :to => 25
end

もし /^ビューを用意$/ do
  show 'app/views/calendars/get_gadget.html.erb', :as => 'new'
end

もし /^前月・翌月のリンクをクリックした時のJavaScript$/ do
  show 'app/assets/javascripts/calendars.js', :as => 'new'
end
