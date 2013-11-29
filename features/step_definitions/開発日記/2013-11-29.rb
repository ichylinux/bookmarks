# coding: UTF-8

もし /^今日かどうかの判定してCSSクラスを設定$/ do
  git_diff 'app/helpers/calendars_helper.rb'
end

もし /^CSSの定義$/ do
  git_diff 'app/assets/stylesheets/calendars.css.scss'
end
