Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resource :settings, only: [ :show, :update ]

      resources :boards, only: [ :index, :show, :create, :update, :destroy ]

      resources :tasks, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :next
          get :pending_attention
        end
        member do
          patch :complete
          patch :claim
          patch :unclaim
          patch :assign
          patch :unassign
        end
      end
    end
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :destroy ] do
      member do
        patch :promote
        patch :demote
      end
    end
    resources :invites, only: [ :index, :create, :destroy ]
    resources :audit_events, only: :index
  end

  resource :session, only: [:new, :create, :destroy]
  get "/auth/:provider/callback", to: "omniauth_callbacks#github", as: :omniauth_callback
  get "/auth/failure", to: "omniauth_callbacks#failure"
  resources :passwords, param: :token
  resources :invites, only: [ :show, :update ], param: :token
  resource :settings, only: [ :show, :update ], controller: "profiles" do
    post :regenerate_api_token
  end
  resource :password_change, only: [ :edit, :update ]

  resources :campaigns, only: [:create, :update] do
    get :archived, on: :collection
    member do
      post :duplicate
      patch :archive
      patch :restore
      delete :destroy_permanently
    end
  end

  # Boards (multi-board kanban views)
  resources :boards, only: [ :index, :show, :create, :update, :destroy ] do
    member do
      get :export, to: "boards/exports#show"
      patch :update_task_status
      post :duplicate
      patch :archive
      patch :restore
    end
    resources :board_columns, only: [:create, :update, :destroy] do
      member do
        patch :move_left
        patch :move_right
      end
    end
    resources :tasks, only: [ :show, :new, :create, :edit, :update, :destroy ], controller: "boards/tasks" do
      get :archived, on: :collection
      member do
        patch :assign
        patch :unassign
        post :duplicate
        patch :archive
        patch :restore
      end
      resources :subtasks, only: [ :create, :update, :destroy ], controller: "boards/subtasks"
      resources :comments, only: [ :create, :update, :destroy ], controller: "boards/comments"
    end
  end

  # Redirect root board path to first board
  get "board", to: redirect { |params, request|
    # This will be handled by the controller for proper user scoping
    "/boards"
  }
  # Agent chat endpoint
  post "agent/chat", to: "agent#chat"

  # Home dashboard (authenticated users)
  get "home", to: "home#show", as: :home

  get "pages/home"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root: direct to sign-in
  root "sessions#new"
end
