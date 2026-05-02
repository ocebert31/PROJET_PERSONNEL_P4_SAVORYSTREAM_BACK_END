# frozen_string_literal: true

module Api
  module V1
    module Carts
      class AddItemController < ApplicationController
        include Api::V1::Carts::CurrentCartSupport

        def create
          sauce = Sauce.find(params[:sauce_id])
          raise ActionController::BadRequest, "conditioning_id is required" if params[:conditioning_id].blank?

          conditioning = sauce.conditionings.find(params[:conditioning_id])
          quantity = item_quantity_param(default: 1)
          line = current_cart.cart_sauces.find_or_initialize_by(conditioning: conditioning)

          line.sauce = sauce
          line.quantity = (line.quantity || 0) + quantity
          line.price = conditioning.price
          line.save!

          render json: {
            message: "Article ajouté au panier.",
            cart: CartSerializer.call(current_cart, base_url: request.base_url)
          }, status: :ok
        end
      end
    end
  end
end
