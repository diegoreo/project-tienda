Rails.application.routes.draw do
  devise_for :users
  resources :products do
    collection do
      get :search
    end
    member do
      patch :activate
    end
  end

  resources :categories, except: :show
  resources :units, except: :show
  resources :warehouses, except: :show
  resources :suppliers
  resources :customers do
    resources :payments, only: [:index, :new, :create, :destroy]
  end

  resources :inventories, only: [:index, :show] do
    resources :inventory_adjustments, only: [:index, :new, :create, :show]
  end

  resources :purchases do
    resources :purchase_items, only: [:create, :update, :destroy]
  end

  resources :sales do
    member do
      post :cancel
      get :payments
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "products#index"
end
