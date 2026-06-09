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

    get  'users/email_registration', to: 'users/email_registrations#new', as: :users_email_registration
    post 'users/email_registration', to: 'users/email_registrations#create'

    resource :account_deletion, only: %i[new destroy], controller: 'users/account_deletions'

    get 'privacy', to: 'pages#privacy'
    get 'terms',   to: 'pages#terms'
  end

  resources :bookmarks do
    collection do
      get 'fetch_title'
      get 'gadget'
    end
  end

  resources :calendars, only: [] do
    collection do
      get :get_gadget
    end
  end

  resources :feeds do
    collection do
      get 'fetch_title'
    end
  end

  resources :mastodon_accounts, only: %i[index show new create edit update destroy]

  resources :x_accounts, only: %i[index show update] do
    collection do
      post :refresh
      post :lookup_and_add
    end
  end

  resources :visited_links, only: [:create]

  resources :notes, only: [:create, :update, :destroy] do
    collection do
      get :gadget
    end
  end

  resources :preferences, only: %i[index update]
  delete 'oauth_identities/:provider', to: 'oauth_identities#destroy', as: :oauth_identity

  resources :todos do
    collection do
      post 'delete'
    end
    member do
      patch 'toggle_highlight'
    end
  end

  resources :welcome, only: [] do
    collection do
      post 'save_state'
    end
  end

  namespace :admin do
    resources :users, only: %i[index destroy] do
      member do
        get :confirm_purge
      end
    end
    resources :x_api_usages, only: [:index]
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
  root to: 'welcome#index'
end
