# frozen_string_literal: true

module Api
  module V1
    module Carts
      class RemoveItemController < ApplicationController
        include Api::V1::Carts::CurrentCartSupport

        def destroy
          line = current_cart.cart_sauces.find(params[:id])
          line.destroy!

          render json: {
            message: "Article retiré du panier.",
            cart: CartSerializer.call(current_cart)
          }, status: :ok
        end
      end
    end
  end
end
