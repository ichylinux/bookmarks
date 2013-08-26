# coding: UTF-8

もし /^Unicornの設定ファイルを用意$/ do |string|
  show 'config/unicorn.rb', :as => 'auto'
end

もし /^Capistranoの設定ファイルを用意$/ do |string|
  show 'Capfile', :as => ['auto', 'edit']
  show 'config/deploy.rb', :as => ['auto', 'edit']
end

もし /^サーバにログインし、以下のコマンドを実行$/ do |string|
end
