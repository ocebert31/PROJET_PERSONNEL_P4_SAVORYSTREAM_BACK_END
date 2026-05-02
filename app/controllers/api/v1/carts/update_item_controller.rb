# frozen_string_literal: true

module Api
  module V1
    module Carts
      class UpdateItemController < ApplicationController
        include Api::V1::Carts::CurrentCartSupport

        def update
          line = current_cart.cart_sauces.find(params[:id])
          quantity = item_quantity_param(default: line.quantity)

          if quantity <= 0
            line.destroy!
            message = "Article retiré du panier."
          else
            line.update!(quantity: quantity)
            message = "Quantité mise à jour."
          end

          render json: { message: message, cart: CartSerializer.call(current_cart, base_url: request.base_url) }, status: :ok
        end
      end
    end
  end
end
