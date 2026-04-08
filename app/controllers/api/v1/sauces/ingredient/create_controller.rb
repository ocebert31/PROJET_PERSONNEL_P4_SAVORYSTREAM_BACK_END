# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Ingredient
        class CreateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def create
            ingredient = ::Ingredient.new(IngredientParameters.new(params).permitted)
            if ingredient.save
              render json: { message: "Ingrédient créé.", ingredient: IngredientSerializer.call(ingredient) }, status: :created
            else
              render json: { errors: ingredient.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
