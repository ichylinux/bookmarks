require 'resque/server'
require 'resque/scheduler/server'

Rails.application.routes.draw do
  devise_for :users
  resque_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.admin?
  end
  constraints resque_constraint do
    mount Resque::Server.new, :at => "/resque", :as => 'resque'
  end

  resources :bookmarks do
    collection do
      get  'new_import'
      post 'confirm_import'
      post 'import'
    end
  end

  resources :calendars do
    member do
      get  'get_gadget'
    end
  end

  resources :feeds do
    collection do
      post 'get_feed_title'
    end
  end

  resources :preferences, :only => ['index', 'create', 'update']

  resources :todos do
    collection do
      get  'new_import'
      post 'confirm_import'
      post 'delete'
      post 'import'
    end
  end

  resources :welcome, :only => [] do
    collection do
      post 'save_state'
    end
  end

  root :to => 'welcome#index'
end
