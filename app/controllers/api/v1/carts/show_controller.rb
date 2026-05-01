# frozen_string_literal: true

module Api
  module V1
    module Carts
      class ShowController < ApplicationController
        include Api::V1::Carts::CurrentCartSupport

        def show
          render json: { cart: CartSerializer.call(current_cart) }, status: :ok
        end
      end
    end
  end
end
