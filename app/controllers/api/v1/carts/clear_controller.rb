# frozen_string_literal: true

module Api
  module V1
    module Carts
      class ClearController < ApplicationController
        include Api::V1::Carts::CurrentCartSupport

        def destroy
          current_cart.cart_sauces.destroy_all
          render json: { message: "Panier vidé.", cart: CartSerializer.call(current_cart) }, status: :ok
        end
      end
    end
  end
end
