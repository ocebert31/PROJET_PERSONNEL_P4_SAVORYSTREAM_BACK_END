# frozen_string_literal: true

module Api
  module V1
    module Sauces
      module Conditioning
        class IndexController < ApplicationController
          include Api::V1::Users::Authentication
          before_action :authenticate_admin!

          def index
            conditionings = ::Conditioning.includes(:sauce).order(:created_at)
            render json: { conditionings: conditionings.map { |c| ConditioningSerializer.call(c) } }, status: :ok
          end
        end
      end
    end
  end
end
