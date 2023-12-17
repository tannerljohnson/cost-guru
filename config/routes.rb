Rails.application.routes.draw do
  # devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # root to: "home#index"
  root "accounts#index"

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions'
  }
  # get '/analyses', to: 'analyses#index'
  # get '/analyses/new', to: 'analyses#new'

  resources :accounts do
    resources :analyses
    resources :revenue_months, except: [:show]
  end

  # resources :analyses
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
