# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Ingredient
        class ShowController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def show
            ingredient = ::Ingredient.find(params[:id])
            render json: { ingredient: IngredientSerializer.call(ingredient) }, status: :ok
          end
        end
      end
    end
  end
end
