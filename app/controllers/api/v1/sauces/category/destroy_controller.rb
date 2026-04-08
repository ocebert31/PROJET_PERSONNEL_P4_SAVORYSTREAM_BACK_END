# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Category
        class DestroyController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def destroy
            category = ::Category.find(params[:id])
            category.destroy!
            head :no_content
          rescue ActiveRecord::DeleteRestrictionError
            render json: { message: "Impossible de supprimer une catégorie utilisée par des sauces." }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
