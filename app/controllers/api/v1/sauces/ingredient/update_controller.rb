# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Ingredient
        class UpdateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def update
            ingredient = ::Ingredient.find(params[:id])
            if ingredient.update(IngredientParameters.new(params).permitted)
              render json: { message: "Ingrédient mis à jour.", ingredient: IngredientSerializer.call(ingredient) }, status: :ok
            else
              render json: { errors: ingredient.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
