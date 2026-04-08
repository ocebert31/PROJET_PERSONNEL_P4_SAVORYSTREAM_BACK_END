# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Ingredient
        class DestroyController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def destroy
            ingredient = ::Ingredient.find(params[:id])
            ingredient.destroy!
            head :no_content
          end
        end
      end
    end
  end
end
