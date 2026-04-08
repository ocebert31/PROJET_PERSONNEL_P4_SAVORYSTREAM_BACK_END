# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Ingredient
        class IndexController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def index
            ingredients = ::Ingredient.includes(:sauce).order(:created_at)
            render json: { ingredients: ingredients.map { |i| IngredientSerializer.call(i) } }, status: :ok
          end
        end
      end
    end
  end
end
