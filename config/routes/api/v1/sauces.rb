# frozen_string_literal: true

# Ressources exposées sous /api/v1/sauces/… (catalogue : catégories, conditionnements, ingrédients, sauces).

resources :categories, only: [], path: "sauces/categories" do
  collection do
    get "/", to: "sauces/category/index#index", as: ""
    post "/", to: "sauces/category/create#create"
  end

  member do
    get "/", to: "sauces/category/show#show", as: ""
    patch "/", to: "sauces/category/update#update"
    put "/", to: "sauces/category/update#update"
    delete "/", to: "sauces/category/destroy#destroy"
  end
end

resources :conditionings, only: [], path: "sauces/conditionings" do
  collection do
    get "/", to: "sauces/conditioning/index#index", as: ""
    post "/", to: "sauces/conditioning/create#create"
  end

  member do
    get "/", to: "sauces/conditioning/show#show", as: ""
    patch "/", to: "sauces/conditioning/update#update"
    put "/", to: "sauces/conditioning/update#update"
    delete "/", to: "sauces/conditioning/destroy#destroy"
  end
end

resources :ingredients, only: [], path: "sauces/ingredients" do
  collection do
    get "/", to: "sauces/ingredient/index#index", as: ""
    post "/", to: "sauces/ingredient/create#create"
  end

  member do
    get "/", to: "sauces/ingredient/show#show", as: ""
    patch "/", to: "sauces/ingredient/update#update"
    put "/", to: "sauces/ingredient/update#update"
    delete "/", to: "sauces/ingredient/destroy#destroy"
  end
end

resources :sauces, only: [] do
  collection do
    get "/", to: "sauces/index#index", as: ""
    post "/", to: "sauces/create#create"
  end

  member do
    get "/", to: "sauces/show#show", as: ""
    patch "/", to: "sauces/update#update"
    put "/", to: "sauces/update#update"
    delete "/", to: "sauces/destroy#destroy"
  end
end
