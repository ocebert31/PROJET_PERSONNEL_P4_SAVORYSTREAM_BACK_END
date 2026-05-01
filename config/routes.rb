# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your routes in config/routes/*.rb and load them with `draw` (see guides.rubyonrails.org/routing.html).

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      draw "api/v1/users"
      draw "api/v1/sauces"
      draw "api/v1/carts"
    end
  end

  # root "posts#index"
end
