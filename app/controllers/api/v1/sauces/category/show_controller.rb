# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Category
        class ShowController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def show
            category = ::Category.find(params[:id])
            render json: { category: CategorySerializer.call(category) }, status: :ok
          end
        end
      end
    end
  end
end
