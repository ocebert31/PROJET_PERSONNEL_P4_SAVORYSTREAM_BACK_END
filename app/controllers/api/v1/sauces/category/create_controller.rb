# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Category
        class CreateController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def create
            category = ::Category.new(CategoryParameters.new(params).permitted)
            if category.save
              render json: { message: "Catégorie créée.", category: CategorySerializer.call(category) }, status: :created
            else
              render json: { errors: category.errors.messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
