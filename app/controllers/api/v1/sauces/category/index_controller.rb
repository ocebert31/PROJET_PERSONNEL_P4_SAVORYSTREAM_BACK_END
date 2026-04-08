# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Category
        class IndexController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def index
            categories = ::Category.order(:name)
            render json: { categories: categories.map { |category| CategorySerializer.call(category) } }, status: :ok
          end
        end
      end
    end
  end
end
