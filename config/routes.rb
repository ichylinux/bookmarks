require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  # don't load User model when building docker image
  unless ARGV.first =~ /^dad:setup(:.+)?/
    devise_for :users, :controllers => { :omniauth_callbacks => 'users/omniauth_callbacks' }
  end

  authenticate :user, lambda {|u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :bookmarks

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

  resources :gmails, except: 'show'

  resources :preferences, only: ['index', 'create', 'update']

  resources :todos do
    collection do
      post 'delete'
    end
  end
  
  resources :tweets

  resources :welcome, only: [] do
    collection do
      post 'save_state'
    end
  end

  root :to => 'welcome#index'
end
