Rails.application.routes.draw do
  # Devise solo para login/logout (SIN registro, SIN recuperar password, SIN editar perfil)
  # Los usuarios SOLO pueden hacer login y logout
  devise_for :users, skip: [:registrations, :passwords]
  
  # Gestión de usuarios (CRUD) - SOLO para admin
  resources :users do
    member do
      patch :toggle_active
    end
  end
  
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

  get "up" => "rails/health#show", as: :rails_health_check
  
  root "products#index"
end