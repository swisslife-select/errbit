Errbit::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  # Hoptoad Notifier Routes
  match '/notifier_api/v2/notices' => 'notices#create', via: [:get, :post]
  get '/locate/:id' => 'notices#locate', :as => :locate
  post '/deploys.txt' => 'deploys#create'

  resources :notices,   :only => [:show]
  resources :users do
    member do
      delete :unlink_github
    end
  end
  resources :problems,      :only => [:index] do
    collection do
      post :destroy_several
      post :resolve_several
      post :unresolve_several
    end
  end

  resources :apps do
    scope module: :apps do
      resources :problems do
        scope module: :problems do
          resources :comments, only: [:create, :destroy]
        end

        collection do
          post :destroy_all
        end

        member do
          patch :resolve
          patch :unresolve
          post :create_issue
          delete :unlink_issue
        end
      end
      resources :deploys, only: [:index, :show]
      resources :watchers, only: [:destroy]
    end
    member do
      post :regenerate_api_key
    end
  end

  namespace :api do
    namespace :v1 do
      resources :app_statistics, only: :show
    end
  end

  root :to => 'apps#index'

end

