Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root "accounts#index"

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
  }, skip: [:registrations]

  devise_scope(:user) do
    get '/users/sign_up', to: 'users/registrations#new', as: :new_user_registration
    post '/users', to: 'users/registrations#create', as: :user_registration

    get '/users/invitation', to: 'membership_invitations#show', as: :user_invitation
  end

  resources :accounts do
    resources :analyses
    resources :contracts do
      resources :contract_years
      resources :service_discounts
    end
    resources :revenue_months, except: [:show]
    resources :membership_invitations do
      member do
        put 'accept'
        put 'decline'
        put 'cancel'
      end
    end

    get 'inventories', to: 'inventories#index'
    get 'anomalies', to: 'anomalies#index'
    get 'members', to: 'members#index'
    get 'members/new', to: 'members#new'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "health" => "rails/health#show", as: :rails_health_check
end
