require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  use_doorkeeper

  devise_for :users, :controllers => { :omniauth_callbacks => 'users/omniauth_callbacks' }

  authenticate :user, lambda {|u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
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
  
  resources :tweets, only: ['index', 'new', 'create', 'destroy']

  resources :welcome, :only => [] do
    collection do
      post 'save_state'
    end
  end

  root :to => 'welcome#index'
end
