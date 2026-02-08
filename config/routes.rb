Rails.application.routes.draw do
  # don't load User model when building docker image
  unless ARGV.first =~ /^dad:setup(:.+)?/
    devise_for :users, controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks',
      sessions: 'users/sessions'
    }

    get  'users/two_factor_authentication', to: 'users/two_factor_authentication#show', as: :users_two_factor_authentication
    post 'users/two_factor_authentication', to: 'users/two_factor_authentication#verify'

    get    'users/two_factor_setup', to: 'users/two_factor_setup#show', as: :users_two_factor_setup
    post   'users/two_factor_setup', to: 'users/two_factor_setup#enable'
    delete 'users/two_factor_setup', to: 'users/two_factor_setup#disable'
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

  resources :preferences, only: ['index', 'create', 'update']

  resources :todos do
    collection do
      post 'delete'
    end
  end
  
  resources :welcome, only: [] do
    collection do
      post 'save_state'
    end
  end

  root to: 'welcome#index'
end
