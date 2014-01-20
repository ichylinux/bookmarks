Bookmarks::Application.routes.draw do
  devise_for :users

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
      post 'import'
    end
  end

  resources :welcome, :only => [] do
    collection do
      post 'save_state'
    end
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
