# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Category
        class UpdateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def update
            category = ::Category.find(params[:id])
            if category.update(CategoryParameters.new(params).permitted)
              render json: { message: "Catégorie mise à jour.", category: CategorySerializer.call(category) }, status: :ok
            else
              render json: { errors: category.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
