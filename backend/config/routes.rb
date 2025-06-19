Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  devise_scope :user do
    put '/users/password', to: 'users/passwords#update', as: :update_user_password
    post '/users/manual_password_reset', to: 'users/passwords#create', as: :manual_password_reset
  end

  resources :protected_resources, only: [:index]
  get 'current_user', to: 'users#show_me'
  get "users/search", to: "users#search"
  resources :users
  resources :visits, defaults: { format: :json } do
    member do
      post :resend_email
    end
  end
  resources :dresses

  get "up" => "rails/health#show", as: :rails_health_check

  post '/upload', to: 'uploads#create'
  resources :watermark_queue, only: [:create], path: 'queue_watermark'

  root 'home#index'
end
