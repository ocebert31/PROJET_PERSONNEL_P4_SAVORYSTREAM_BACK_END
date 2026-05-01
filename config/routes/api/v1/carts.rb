# frozen_string_literal: true

resource :cart, only: [], path: "carts" do
  get "/", to: "carts/show#show", as: ""
  post "items", to: "carts/add_item#create"
  patch "items/:id", to: "carts/update_item#update", as: :item
  delete "items/:id", to: "carts/remove_item#destroy"
  delete "/", to: "carts/clear#destroy"
end
