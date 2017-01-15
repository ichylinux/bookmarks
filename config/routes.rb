Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  devise_for :users, :controllers => { :omniauth_callbacks => 'users/omniauth_callbacks' }

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
