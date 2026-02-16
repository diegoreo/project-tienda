Rails.application.routes.draw do
  get "errors/not_found"
  get "errors/unprocessable_entity"
  get "errors/internal_server_error"
  # Devise solo para login/logout (SIN registro, SIN recuperar password, SIN editar perfil)
  # Los usuarios SOLO pueden hacer login y logout
  devise_for :users, skip: [ :registrations, :passwords ]
  # Rate limiting check
  get 'rate_limit/check_login', to: 'rate_limit#check_login'

  # gestion de info company
  resource :company, only: [:show, :edit, :update]

  # Gestión de usuarios (CRUD) - SOLO para admin
  resources :users do
    member do
      patch :toggle_active
    end
  end

  resources :products do
    collection do
      get :search_master  
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
    resources :payments, only: [ :index, :new, :create, :destroy ]
    
    member do
      get :sales  # Nueva ruta para historial completo
    end
  end

  resources :inventories, only: [ :index, :show ] do
    resources :inventory_adjustments, only: [ :index, :new, :create, :show ]
  end

  resources :purchases do
    resources :purchase_items, only: [ :create, :update, :destroy ]
  end

  resources :sales do
    member do
      post :cancel
      get :payments
      get :print_ticket  
      get :print_ticket_escpos
    end
  end

  # Cajas (Registers)
  resources :registers do
    member do
      patch :toggle_active
    end
  end

  # Sesiones de caja (Register Sessions)
  resources :register_sessions, except: [ :edit, :update ] do
    # Flujos de efectivo (ingresos/egresos)
    resources :cash_register_flows, path: 'flows', only: [ :index, :new, :create, :show, :edit, :update ] do
      collection do
        post :quick_create  #  Crear flujo con autorización rápida
      end
      
      member do
        post :cancel  # Cancelar un movimiento
      end
    end
    
    member do
      get :close                          # Formulario para cerrar turno
      patch :process_close                # Procesar cierre
      get :closure_report                 # Reporte básico (cajeros)
      get :closure_report_detailed        # Reporte completo (supervisores+)
      patch :toggle_active                # Activar/desactivar (si existe)
    end
  end
  
  # Configuración de tickets
  resource :ticket_settings, only: [:edit, :update], path: 'tickets/settings'

  get "up" => "rails/health#show", as: :rails_health_check

  root "products#index"

  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
