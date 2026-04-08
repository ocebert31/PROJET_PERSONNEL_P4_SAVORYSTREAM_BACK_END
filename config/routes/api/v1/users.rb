# frozen_string_literal: true

namespace :users do
  resources :registrations, only: [ :create ]
  resources :sessions, only: [ :create ] do
    collection do
      post :refresh
      post :revoke
    end
  end
end
