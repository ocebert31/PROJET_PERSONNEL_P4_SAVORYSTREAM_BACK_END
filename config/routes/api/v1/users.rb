# frozen_string_literal: true

namespace :users do
  resources :registrations, only: [ :create ]
  resources :sessions, only: [ :create ] do
    collection do
      get :me
      post :refresh
      post :revoke
    end
  end
end
